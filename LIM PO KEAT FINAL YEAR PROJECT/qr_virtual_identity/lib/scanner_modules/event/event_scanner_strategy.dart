import 'dart:async';
import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Core Animation Lib
import '../scanner_mode_strategy.dart';
import '../../services/scan_point_service.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../../utils/qr_parser.dart';
import '../../utils/scanner_lifecycle_controller.dart';
import '../../services/scanner_notification_service.dart';
import '../../utils/audio_helper.dart';
import '../../widgets/jelly_status_views.dart';
import '../../widgets/jelly_idle_view.dart';
import '../../widgets/jelly_notification.dart';

enum CheckInStatus { none, success, duplicate, error, networkError }

/// 🎫 Event Scanner Strategy (Jelly Kiosk Edition)
/// Implements continuous event check-in with "Tri-State Feedback" (Success, Duplicate, Error).
class EventScannerStrategy implements ScannerModeStrategy {
  @override
  bool get shouldHandleStopTrigger => true;
  @override
  String get scanMode => 'event';

  @override
  VoidCallback? onStrategyFinished;

  @override
  VoidCallback? onStateChanged;

  @override
  Function(Map<String, dynamic> info)? onDebugInfo;

  BuildContext? _context;
  ScanPoint? _scanPoint;

  // State
  CheckInStatus _status = CheckInStatus.none;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _feedbackTitle;
  String? _feedbackSubtitle;
  
  // Event Config
  String? _currentEventId;
  String? _targetEventName;

  // Timers
  Timer? _autoDismissTimer;
  
  // Kiosk Sleep Mode
  Timer? _sleepTimer;
  bool _isSleeping = false;
  static const Duration _sleepDuration = Duration(seconds: 60);

  // Debounce
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _debounceDuration = Duration(seconds: 3);

  @override
  Future<void> onTriggerReceived(
    ScanPoint scanPoint, {
    Map<String, dynamic>? data,
  }) async {
    _scanPoint = scanPoint;

    if (data != null && data.containsKey('event_id')) {
      _currentEventId = data['event_id'];
      _targetEventName = data['event_name'];
      print('🎫 [EventScanner] Configured for Event ID: $_currentEventId');
    } else {
      await _autoAssignEvent();
    }
    
    await _notifyDesktopScannerStopped();
    
    // Initial Start
    await _wakeUp();
  }

  Future<void> _autoAssignEvent() async {
      print('⚠️ [EventScanner] No Event ID provided! Auto-assigning...');
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('events')
            .where('is_active', isEqualTo: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();
          _currentEventId = data['event_id'] ?? doc.id;
          _targetEventName = data['name'] ?? 'Unknown Event';
          print('🎫 [EventScanner] Auto-assigned: $_targetEventName');
          _notifyUIUpdate();
        }
      } catch (e) {
        print('❌ [EventScanner] Auto-assign failed: $e');
      }
  }

  @override
  Future<void> onQrScanned(String rawValue, ScanPoint scanPoint) async {
    // 1. Wake up logic
    if (_isSleeping) {
      await _wakeUp();
      return;
    }
    _resetSleepTimer();

    if (_isProcessing) return;

    // Debounce
    if (rawValue == _lastScannedCode && 
        _lastScanTime != null && 
        DateTime.now().difference(_lastScanTime!) < _debounceDuration) {
      return;
    }

    _isProcessing = true;
    _lastScannedCode = rawValue;
    _lastScanTime = DateTime.now();
    _notifyUIUpdate();

    final startTime = DateTime.now();

    try {
      final result = QRParser.parse(rawValue);

      if (!result.isValid || result.type != QrType.user) {
         // Silently ignore non-user QRs or show quick error? 
         // Strategy: Show error for better UX
         throw Exception('Please scan your Identity QR.');
      }
      
      if (result.isExpired) throw Exception('QR Code Expired.');
      
      final userId = result.userId;
      if (userId == null) throw Exception('Invalid Identity Data.');

      HapticFeedback.lightImpact();

      if (_currentEventId == null) {
         throw Exception('No Active Event Configured.');
      }

      print('🔄 [EventScanner] Checking in User: $userId...');

      // Call Backend
      final response = await EventService.processIdentityCheckIn(
        userId: userId,
        eventId: _currentEventId!,
        scanPoint: scanPoint,
        timestamp: result.timestamp,
        nonce: result.nonce,
        signature: result.sig,
      );

      _handleBackendResponse(response, rawValue, startTime);

    } catch (e) {
      print('❌ [EventScanner] Local Error: $e');
      _emitDebugInfo(rawValue, 'error', e.toString(), startTime);
      await onScanError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      // Release lock but wait for dismiss timer to clear UI
      _isProcessing = false; 
    }
  }

  void _handleBackendResponse(Map<String, dynamic> response, String rawQr, DateTime startTime) async {
    final status = response['status'] as String?;
    final message = response['message'] as String? ?? 'Unknown State';
    final userName = response['user_name'] as String? ?? 'Guest';

    _feedbackSubtitle = userName;

    if (status == 'success' || response['success'] == true) {
      // ✅ SUCCESS
      _status = CheckInStatus.success;
      _feedbackTitle = 'Check-in Successful';
      _feedbackSubtitle = userName; // User Name
      
      print('✅ [EventScanner] Success: $userName');
      await AudioHelper.playSuccess();
      HapticFeedback.heavyImpact();
      
      _emitDebugInfo(rawQr, 'success', 'Checked In', startTime, backendResponse: response);
      _startAutoDismiss(seconds: 2); // Quick clear for flow

    } else if (status == 'already_checked_in') {
      // ⚠️ DUPLICATE (Warning)
      _status = CheckInStatus.duplicate;
      _feedbackTitle = 'Already Checked In';
      // _feedbackSubtitle remains userName
      
      print('⚠️ [EventScanner] Duplicate: $userName');
      // Play a specific sound if available, else error sound is okay but we show Orange UI
      await AudioHelper.playError(); 
      HapticFeedback.mediumImpact();
      
      _emitDebugInfo(rawQr, 'duplicate', 'Duplicate Check-in', startTime, backendResponse: response);
      _startAutoDismiss(seconds: 2); // Quick clear (it's not a fatal error)

    } else {
      // ❌ ERROR
      _status = CheckInStatus.error;
      _feedbackTitle = 'Check-in Failed';
      _feedbackSubtitle = message;
      
      print('❌ [EventScanner] Backend Error: $message');
      await AudioHelper.playError();
      HapticFeedback.vibrate();
      
      _emitDebugInfo(rawQr, 'error', message, startTime, backendResponse: response);
      _startAutoDismiss(seconds: 4); // Longer read time for errors
    }

    _notifyUIUpdate();
  }

  void _startAutoDismiss({required int seconds}) {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(Duration(seconds: seconds), () {
      _resetState();
    });
  }

  // --- Sleep Mode ---

  void _resetSleepTimer() {
    _sleepTimer?.cancel();
    if (!_isSleeping) {
      _sleepTimer = Timer(_sleepDuration, _goToSleep);
    }
  }

  Future<void> _goToSleep() async {
    _isSleeping = true;
    _sleepTimer?.cancel();
    _notifyUIUpdate();
    if (_context != null && _context!.mounted) {
       await ScannerLifecycleController.stopScanning(); 
    }
  }

  Future<void> _wakeUp() async {
    HapticFeedback.mediumImpact();
    _isSleeping = false;
    _notifyUIUpdate();
    
    if (_context != null && _context!.mounted) {
       await ScannerLifecycleController.startScanning(
        context: _context!,
        onScannerReady: () => _resetSleepTimer(),
        onScannerFailed: (e) => onScanError(e),
      );
    }
    _resetSleepTimer();
  }

  // --- State Mgmt ---

  void _resetState() {
    _autoDismissTimer?.cancel();
    _status = CheckInStatus.none;
    _errorMessage = null;
    _feedbackTitle = null;
    _feedbackSubtitle = null;
    _resetSleepTimer();
    _notifyUIUpdate();
  }

  void _notifyUIUpdate() {
    if (onStateChanged != null) onStateChanged!();
  }
  
  void _emitDebugInfo(String rawQr, String result, String message, DateTime startTime, {Map<String, dynamic>? backendResponse}) {
    if (onDebugInfo != null) {
      onDebugInfo!({
        'mode': 'event',
        'scanPoint': _scanPoint?.name ?? 'Unknown',
        'timestamp': DateTime.now().toIso8601String(),
        'result': result,
        'latencyMs': DateTime.now().difference(startTime).inMilliseconds,
        'message': message,
        'backendResponse': backendResponse,
      });
    }
  }

  @override
  Future<void> onScanComplete() async {}

  @override
  Future<void> onScanError(String error) async {
      _errorMessage = error;
      final errorStr = error.toLowerCase();

      // 📡 Smart Sniffing for Network Errors
      if (errorStr.contains('network') || 
          errorStr.contains('socket') || 
          errorStr.contains('timeout') ||
          errorStr.contains('offline')) {
          _status = CheckInStatus.networkError;
          _feedbackTitle = 'Connection Lost';
          _feedbackSubtitle = 'Please check internet.';
      } else {
          _status = CheckInStatus.error;
          _feedbackTitle = 'Scanner Error';
          _feedbackSubtitle = error;
      }
      
      await AudioHelper.playError();
      HapticFeedback.vibrate();
      
      _notifyUIUpdate();
      ScannerLifecycleController.setProcessing(false);
      _startAutoDismiss(seconds: 4);
  }

  // --- UI Construction ---

  @override
  Widget buildUI(BuildContext context) {
    _context = context;

    return GestureDetector(
      onTap: () {
        if (_isSleeping) _wakeUp();
        else {
          // If tapping notification, dismiss it
          if (_status != CheckInStatus.none) _resetState();
          _resetSleepTimer();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // 1. Idle View (Animated Entry)
          if (!_isSleeping)
            Animate(
              effects: [
                ScaleEffect(duration: 600.ms, curve: Curves.elasticOut, begin: const Offset(0.9, 0.9)),
                FadeEffect(duration: 400.ms),
              ],
              child: JellyIdleView(
                title: 'Event Check-In',
                subtitle: _scanPoint?.name ?? 'Ticket Scanner',
                eventName: _targetEventName ?? 'Loading Event...',
                instruction: 'Scan Identity QR',
              ),
            ),

          // 2. Edge Glow (Tri-State)
          if (!_isSleeping)
            _buildEdgeGlow(),

          // 3. Notification Layer
          if (!_isSleeping && _status != CheckInStatus.none)
             Positioned(
              top: 20, left: 20, right: 20,
              child: _buildNotification(),
             ),

          // 4. Processing
          if (_isProcessing && _status == CheckInStatus.none)
             const Center(child: JellyProcessingView()),

          // 5. Sleep Overlay
          if (_isSleeping)
            _buildSleepOverlay(context),
        ],
      ),
    );
  }

  Widget _buildNotification() {
    IconData icon;
    Color color;
    String amountText;

    switch (_status) {
      case CheckInStatus.success:
        icon = Icons.check_circle;
        color = Colors.green;
        amountText = 'Welcome';
        break;
      case CheckInStatus.duplicate:
        icon = Icons.warning_rounded; // ⚠️ Warning icon
        color = Colors.orange;
        amountText = 'Used Ticket'; // Friendly warning
        break;
      case CheckInStatus.error:
        icon = Icons.cancel;
        color = Colors.red;
        amountText = 'Error';
        break;
      case CheckInStatus.networkError:
        icon = Icons.wifi_off_rounded;
        color = Colors.amber;
        amountText = 'Offline';
        break;
      default:
        return const SizedBox.shrink();
    }

    return JellyNotification(
      title: _feedbackTitle ?? '',
      subtitle: _feedbackSubtitle ?? '',
      amount: amountText,
      icon: icon,
      color: color,
      onTap: _resetState,
      onDismiss: _resetState,
    );
  }

  Widget _buildEdgeGlow() {
    Color? glowColor;
    switch (_status) {
      case CheckInStatus.success: glowColor = Colors.green.withOpacity(0.6); break;
      case CheckInStatus.duplicate: glowColor = Colors.orange.withOpacity(0.6); break;
      case CheckInStatus.error: glowColor = Colors.red.withOpacity(0.6); break;
      case CheckInStatus.networkError: glowColor = Colors.amber.withOpacity(0.6); break;
      default: return const SizedBox.shrink(); // No glow
    }

    return IgnorePointer(
      child: AnimatedContainer(
        duration: 300.ms,
        decoration: BoxDecoration(
          border: Border.all(color: glowColor, width: 12),
          boxShadow: [
             BoxShadow(color: glowColor, blurRadius: 40, spreadRadius: 5),
          ],
        ),
      )
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .fade(begin: 0.6, end: 1.0, duration: 500.ms),
    );
  }

  Widget _buildSleepOverlay(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ Color(0xFF2C3E50), Color(0xFF000000) ], // Dark Slate
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 64)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 2.seconds),
            const SizedBox(height: 20),
            Text(
              'Scanner Asleep', 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white70)
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap to Wake',
              style: TextStyle(color: Colors.white30, letterSpacing: 1.5),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.3, end: 1.0, duration: 1.seconds),
          ],
        ),
      ),
    );
  }

  @override
  String getScanFrameType() => 'qr';

  Future<void> _notifyDesktopScannerStopped() async {
    await ScannerNotificationService.notifyDesktopScannerStopped();
  }
}
