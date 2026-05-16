import 'dart:async';
import 'package:flutter/material.dart';
import '../scanner_mode_strategy.dart';
import '../../services/scan_point_service.dart';
import '../../services/access_service.dart'; // Import local service
import '../../utils/qr_parser.dart';
import '../../utils/scanner_lifecycle_controller.dart';
import '../../services/scanner_notification_service.dart';
import '../../utils/error_mapper.dart';
import '../../utils/audio_helper.dart';
import '../../widgets/jelly_status_views.dart';
import '../../widgets/jelly_idle_view.dart';
import '../../widgets/jelly_notification.dart';

/// 🔐 Access Scanner Strategy (Jelly Edition - Kiosk Mode)
/// Implements continuous access control workflow with Sleep Mode (Power Saving).
class AccessScannerStrategy implements ScannerModeStrategy {
  @override
  bool get shouldHandleStopTrigger => true;
  @override
  String get scanMode => 'access';

  @override
  VoidCallback? onStrategyFinished;

  @override
  VoidCallback? onStateChanged;

  @override
  Function(Map<String, dynamic> info)? onDebugInfo;

  BuildContext? _context;
  ScanPoint? _scanPoint;
  bool? _accessGranted;
  bool _showError = false;
  String? _errorMessage;

  String? _scannedUserId;
  String? _scannedUserEmail;
  String? _scannedUserName;
  String? _denialReason;
  
  bool _isProcessing = false;
  Timer? _autoDismissTimer;
  
  // Sleep Mode Logic
  Timer? _sleepTimer;
  bool _isSleeping = false;
  static const Duration _sleepDuration = Duration(seconds: 60); // 60s idle to sleep

  // Debounce logic
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _debounceDuration = Duration(seconds: 3);

  @override
  Future<void> onTriggerReceived(
    ScanPoint scanPoint, {
    Map<String, dynamic>? data,
  }) async {
    _scanPoint = scanPoint;
    print('🔍 [AccessStrategy] Trigger received for scan point: ${scanPoint.name}');
    
    if (_context != null && _context!.mounted) {
      ScannerNotificationService.showInfo(
        context: _context!,
        message: 'Access Control Kiosk Active',
      );
    }
    
    // Initial Start
    await _wakeUp();

    await _notifyDesktopScannerStopped();
    _reset();
  }

  @override
  Future<void> onQrScanned(String rawValue, ScanPoint scanPoint) async {
    // 1. Wake up if sleeping (Edge case: shouldn't happen if camera is off, but good safeguard)
    if (_isSleeping) {
      await _wakeUp();
      return;
    }

    _resetSleepTimer(); // Activity detected!

    if (_isProcessing) return;
    
    // Debounce check
    if (rawValue == _lastScannedCode && 
        _lastScanTime != null && 
        DateTime.now().difference(_lastScanTime!) < _debounceDuration) {
      print('⏳ [AccessStrategy] Debounced duplicate scan: $rawValue');
      return;
    }

    print('📸 [AccessStrategy] QR scanned: $rawValue');
    final startTime = DateTime.now();
    
    _lastScannedCode = rawValue;
    _lastScanTime = startTime;
    
    _isProcessing = true;
    _notifyUIUpdate();

    try {
      final result = QRParser.parse(rawValue);

      if (!result.isValid) {
        throw Exception('Invalid QR: ${result.errorMessage}');
      }

      if (result.type != QrType.user) {
        throw Exception('Invalid QR type. Please scan a Student/Staff ID.');
      }

      if (result.isExpired) {
        throw Exception('QR Code Expired. Please refresh.');
      }

      final userId = result.userId;
      if (userId == null) {
        throw Exception('Invalid QR: Missing User ID');
      }

      print('🔄 [AccessStrategy] Verifying access for User: $userId at Point: ${_scanPoint!.scanPointId}...');

      // Process via Local Service (Fast)
      final response = await AccessService.processEntry(
        userId: userId,
        scanPoint: _scanPoint!,
        // Security parameters
        timestamp: result.timestamp,
        nonce: result.nonce,
        signature: result.sig,
      );

      final data = response.data ?? {};
      print('📦 [AccessStrategy] Local Service Response: $response');

      if (response.success || data['allowed'] == true || data['access_granted'] == true) {
        // ACCESS GRANTED
        _accessGranted = true;
        _scannedUserId = userId;
        _scannedUserEmail = data['user_email'];
        _scannedUserName = data['user_name'];
        _denialReason = null;
        
        _emitDebugInfo(rawValue, 'success', 'Access Granted', startTime, backendResponse: data);
        print('✅ [AccessStrategy] Access GRANTED for $userId');
        await AudioHelper.playSuccess();

        // Kiosk Mode: Auto-ready for next person in 2s
        _startAutoDismissTimer();

      } else {
        // ACCESS DENIED
        _accessGranted = false;
        _scannedUserId = userId;
        _denialReason = response.message ?? data['reason'] ?? 'Access Denied';
        
        _emitDebugInfo(rawValue, 'error', 'Access Denied: $_denialReason', startTime, backendResponse: data);
        print('⛔ [AccessStrategy] Access DENIED: $_denialReason');
        await AudioHelper.playError();
        
        // Kiosk Mode: Auto-ready even on failure
        _startAutoDismissTimer(duration: const Duration(seconds: 3));
      }


      _notifyUIUpdate();

    } catch (e) {
      print('❌ [AccessStrategy] Error in access scan: $e');
      
      // ⚡ Smart Debounce: Reset debounce on error so user can retry immediately
      print('⚡ [AccessStrategy] Smart Debounce: Resetting debounce due to error.');
      _lastScannedCode = null;
      _lastScanTime = null;

      final friendlyError = mapBackendError(e);
      _emitDebugInfo(rawValue, 'error', 'Exception: $e', startTime);
      await onScanError(friendlyError);
    } finally {
      _isProcessing = false;
      _notifyUIUpdate();
    }
  }

  void _startAutoDismissTimer({Duration duration = const Duration(seconds: 2)}) {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(duration, () {
      _reset(); // Clears flags, making UI ready for next scan
      _notifyUIUpdate();
    });
  }

  // --- Sleep Mode Logic ---

  void _resetSleepTimer() {
    _sleepTimer?.cancel();
    // Only start sleep timer if NOT currently sleeping (to avoid loops)
    if (!_isSleeping) {
      _sleepTimer = Timer(_sleepDuration, _goToSleep);
    }
  }

  Future<void> _goToSleep() async {
    print('💤 [AccessStrategy] No activity for 60s. Entering Sleep Mode.');
    _isSleeping = true;
    _sleepTimer?.cancel();
    _notifyUIUpdate();
    
    // Stop camera to save power
    if (_context != null && _context!.mounted) {
       await ScannerLifecycleController.stopScanning(); 
    }
  }

  Future<void> _wakeUp() async {
    print('🌅 [AccessStrategy] Waking up...');
    _isSleeping = false;
    _notifyUIUpdate();
    
    // Restart Camera
    if (_context != null && _context!.mounted) {
       await ScannerLifecycleController.startScanning(
        context: _context!,
        onScannerReady: () {
          print('📸 [AccessStrategy] Scanner ready (Woken up)');
          _resetSleepTimer(); // Start counting down again
        },
        onScannerFailed: (e) => onScanError(e.toString()),
      );
    }
    _resetSleepTimer(); // Start timer immediately assuming start request works
  }

  // ------------------------

  void _emitDebugInfo(String rawQr, String result, String message, DateTime startTime, {Map<String, dynamic>? backendResponse}) {
    if (onDebugInfo != null) {
      onDebugInfo!({
        'mode': 'access',
        'scanPoint': _scanPoint?.name ?? 'Unknown',
        'timestamp': DateTime.now().toIso8601String(),
        'rawQr': _maskQr(rawQr),
        'result': result,
        'latencyMs': DateTime.now().difference(startTime).inMilliseconds,
        'message': message,
        'backendResponse': backendResponse,
      });
    }
  }

  String _maskQr(String qr) {
    if (qr.length <= 10) return '***';
    return '${qr.substring(0, 5)}...${qr.substring(qr.length - 5)}';
  }

  @override
  Future<void> onScanComplete() async {
    // In Kiosk Mode, we DO NOT stop scanning here.
    // We just log it. The loop continues.
    print('✅ [AccessStrategy] Scan processed. Ready for next.');
  }

  @override
  Future<void> onScanError(String error) async {
    print('❌ [AccessStrategy] Error: $error');
    await AudioHelper.playError();
    _showError = true;
    _errorMessage = error;
    _notifyUIUpdate();
    
    // Even on critical error, in Kiosk Mode we might want to stay alive?
    // But for safety, we stop processing flag.
    ScannerLifecycleController.setProcessing(false);
    
    // Auto-dismiss critical errors too after a bit, so the kiosk doesn't get stuck
    _startAutoDismissTimer(duration: const Duration(seconds: 5));
  }

  @override
  Widget buildUI(BuildContext context) {
    _context = context;

    // Root is a GestureDetector to handle Wake Up
    return GestureDetector(
      onTap: () {
        if (_isSleeping) {
          _wakeUp();
        } else {
          _resetSleepTimer(); // Any tap resets the timer
        }
      },
      behavior: HitTestBehavior.translucent, // Catch taps even on empty space
      child: Stack(
        children: [
          // 1. Base Layer: Idle View (Only visible when awake)
          if (!_isSleeping)
            JellyIdleView(
              title: 'Access Control',
              subtitle: _scanPoint?.name ?? 'Security Check',
              eventName: 'Authorized Personnel Only',
              instruction: 'Tap NFC or Scan ID',
            ),

          // 2. Notification Layer (Results) - Hide if sleeping
          if (!_isSleeping && _accessGranted != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: JellyNotification(
                title: _accessGranted == true ? 'Access Granted' : 'Access Denied',
                subtitle: _scannedUserName ?? 'Unknown User',
                amount: _accessGranted == true ? 'Welcome' : (_denialReason ?? 'Restricted'),
                icon: _accessGranted == true ? Icons.check_circle : Icons.cancel,
                color: _accessGranted == true ? Colors.green : Colors.red,
                onTap: () {
                  _reset();
                  _notifyUIUpdate();
                },
                onDismiss: () {
                  _reset();
                  _notifyUIUpdate();
                },
              ),
            ),

          if (!_isSleeping && _showError && _errorMessage != null && _accessGranted == null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: JellyNotification(
                title: 'Scan Error',
                subtitle: _errorMessage!,
                icon: Icons.error_outline,
                color: Colors.orange,
                onTap: () {
                  _reset();
                  _notifyUIUpdate();
                },
                onDismiss: () {
                  _reset();
                  _notifyUIUpdate();
                },
              ),
            ),
            
          // 3. Processing Indicator
          if (_isProcessing)
            const Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // 4. Sleep Overlay (The "Kiosk Idle" Screen)
          if (_isSleeping)
            Container(
              color: Colors.black.withOpacity(0.85), // Dark overlay
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app, color: Colors.white54, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Kiosk Sleeping',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap screen to scan',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  String getScanFrameType() => 'qr';

  void _reset() {
    // Note: _autoDismissTimer should generally be managed before calling this or by this.
    // Here we just reset data.
    _accessGranted = null;
    _scannedUserId = null;
    _scannedUserEmail = null;
    _scannedUserName = null;
    _denialReason = null;
    _showError = false;
    _errorMessage = null;
    
    // IMPORTANT for Kiosk Mode:
    // Resetting should also ensure the sleep timer is ticking
    _resetSleepTimer();
  }

  Future<void> _notifyDesktopScannerStopped() async {
    await ScannerNotificationService.notifyDesktopScannerStopped();
  }

  void _notifyUIUpdate() {
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }
}
