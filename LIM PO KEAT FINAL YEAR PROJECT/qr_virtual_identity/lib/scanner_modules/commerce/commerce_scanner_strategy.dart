import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../services/commerce_service.dart'; // Import local service
import 'package:flutter_animate/flutter_animate.dart';
import '../scanner_mode_strategy.dart';
import '../../services/scan_point_service.dart';
import '../../utils/qr_parser.dart';
import '../../utils/scanner_lifecycle_controller.dart';
import 'commerce_scanner_controller.dart';
import '../../utils/error_mapper.dart';
import '../../widgets/scan_success_overlay.dart';
import '../../widgets/scan_error_overlay.dart';
import '../../utils/audio_helper.dart'; // Import AudioHelper
import '../../widgets/jelly_card.dart'; // Import JellyCard
import '../../widgets/jelly_status_views.dart'; // 🍬 Jelly Status Views

/// Strategy implementation for commerce/payment scanner mode
///
/// Single-step workflow:
/// 1. Desktop triggers with payment_amount and cart_items
/// 2. Scan customer QR code
/// 3. Process payment via QrProcessorService
/// 4. Complete and notify desktop
class CommerceScannerStrategy implements ScannerModeStrategy {
  // Controller for payment state
  final CommerceScannerController _controller = CommerceScannerController();

  // Callback to notify when strategy is finished (for cleanup)
  @override
  VoidCallback? onStrategyFinished;

  // Callback to trigger UI rebuild in parent widget
  @override
  VoidCallback? onStateChanged;

  @override
  Function(Map<String, dynamic> info)? onDebugInfo;

  // State for success animation
  bool _isSuccess = false;
  String? _successMessage;
  Map<String, dynamic>? _successData;

  // State for error overlay
  bool _showError = false;
  String? _errorMessage;

  // Context for showing snackbars (updated in buildUI)
  BuildContext? _context;

  @override
  String get scanMode => 'commerce';

  @override
  String getScanFrameType() => 'qr'; // Always QR for customer payment codes

  @override
  Future<void> onTriggerReceived(
    ScanPoint scanPoint, {
    Map<String, dynamic>? data,
  }) async {
    print(
      '💳 [Commerce Strategy] Trigger received for scan point: ${scanPoint.name}',
    );

    // Extract payment details from trigger data
    double paymentAmount = 0.0;
    List<Map<String, dynamic>>? cartItems;

    if (data != null) {
      print('💳 [Commerce Strategy] Trigger data: $data');
      if (data.containsKey('amount')) {
        paymentAmount = (data['amount'] as num).toDouble();
      }
      if (data.containsKey('cart')) {
        cartItems = List<Map<String, dynamic>>.from(
          (data['cart'] as List).map((item) => Map<String, dynamic>.from(item)),
        );
      }
    }

    print(
      '💳 [Commerce Strategy] Payment Amount: RM ${paymentAmount.toStringAsFixed(2)}',
    );

    // Activate controller with payment details
    _controller.activate(amount: paymentAmount, cartItems: cartItems);

    // Reset any previous scanner state
    ScannerLifecycleController.resetState();

    // Start scanning for customer QR (needs context - will be available from buildUI)
    // Note: We'll start scanner in buildUI when context is available
    print(
      '📸 [Commerce Strategy] Commerce mode activated, waiting for UI to start scanner...',
    );
  }

  @override
  Future<void> onQrScanned(String rawValue, ScanPoint scanPoint) async {
    print('💳 [Commerce Strategy] QR scanned: $rawValue');
    final startTime = DateTime.now();
    
    // 🔊 Audio Feedback: Beep on scan
    AudioHelper.playBeep();

    // Prevent processing if not active
    if (!_controller.isActive) {
      print('⚠️ [Commerce Strategy] Controller not active, ignoring scan');
      return;
    }

    try {
      // 1. Parse QR code
      final result = QRParser.parse(rawValue);

      print(
        '💳 [Commerce Strategy] Parse result: ${result.type}, isValid: ${result.isValid}',
      );

      if (!result.isValid) {
        _emitDebugInfo(rawValue, 'error', 'Invalid QR: ${result.errorMessage}', startTime);
        ScannerLifecycleController.setProcessing(false); // FIX: Clear processing
        await AudioHelper.playError(); // 🔊 Error Sound
        await onScanError('Invalid QR code: ${result.errorMessage}');
        return;
      }

      // 2. Validate that this is a user QR (customer)
      if (result.type != QrType.user) {
        _emitDebugInfo(rawValue, 'error', 'Invalid QR Type: ${result.type}', startTime);
        ScannerLifecycleController.setProcessing(false); // FIX: Clear processing
        await AudioHelper.playError(); // 🔊 Error Sound
        await onScanError(
          'Invalid QR type. Please scan a customer QR code.',
        );
        return;
      }

      // 3. Check for expiration
      if (result.isExpired) {
        _emitDebugInfo(rawValue, 'error', 'QR Expired', startTime);
        ScannerLifecycleController.setProcessing(false); // FIX: Clear processing
        await AudioHelper.playError(); // 🔊 Error Sound
        await onScanError('QR Code Expired. Please refresh.');
        return;
      }

      // 4. Use Local CommerceService for instant payment processing
      // This bypasses the 3-5s Cloud Function latency 🚀
      
      // FIX: Set processing state to show loading animation
      ScannerLifecycleController.setProcessing(true, onUpdate: () {
         if (onStateChanged != null) onStateChanged!();
      });

      // Call local service DIRECTLY
      final response = await CommerceService.processPayment(
        userId: result.userId!,
        scanPoint: scanPoint,
        amount: _controller.paymentAmount,
        items: _controller.cartItems,
        // Security parameters from QR
        timestamp: result.timestamp,
        nonce: result.nonce,
        signature: result.sig,
      );

      ScannerLifecycleController.setProcessing(false); // Clear processing immediately

      if (response.success) {
        // Payment Successful
        final data = response.data ?? {};
        
        if (result.userId != null) {
          _controller.setCustomer(
            uid: result.userId!,
            // If email is not in response, try to use masked UID or fallback
            email: data['user_email'] ?? 'User ${result.userId!.substring(0, 5)}...',
          );
        }
        
        _emitDebugInfo(rawValue, 'success', 'Payment Successful (Local)', startTime, backendResponse: data);
        
        // 🔊 Audio Feedback: Success
        await AudioHelper.playSuccess();
        
        // ✅ Update State for JellySuccessView
        _isSuccess = true;
        _successMessage = 'Payment Successful';
        _successData = {
          'Amount': 'RM ${_controller.paymentAmount?.toStringAsFixed(2) ?? "0.00"}',
          'Customer': data['user_email'] ?? 'Verified User',
          'Balance': 'RM ${(data['new_balance'] as num?)?.toStringAsFixed(2) ?? "N/A"}',
        };
        
        if (onStateChanged != null) onStateChanged!();

        // Note: onScanComplete will be called by the overlay's onDismiss callback
      } else {
        // Payment Failed
        throw FirebaseFunctionsException(
          code: response.errorCode ?? 'UNKNOWN',
          message: response.message,
        );
      }

    } catch (e) {
      print('❌ [Commerce Strategy] Error processing payment: $e');
      
      // FIX: Check if the error message actually contains "Payment successful"
      // This happens if the backend throws a success message as an exception or if the client SDK misinterprets it
      final errorString = e.toString();
      if (errorString.contains('Payment successful') || (errorString.contains('RM') && errorString.contains('paid'))) {
         print('✅ [Commerce Strategy] Caught "Payment successful" in exception block - treating as SUCCESS');
         
         // Manually construct a success response
         // We might not have the full data, but we know it succeeded
         _emitDebugInfo(rawValue, 'success', 'Payment Successful (Recovered from Exception)', startTime);
         
         // 🔊 Audio Feedback: Success
         await AudioHelper.playSuccess();

         ScannerLifecycleController.setProcessing(false); // FIX: Clear processing before showing success
         
         // ✅ Update State for JellySuccessView
         _isSuccess = true;
         _successMessage = 'Payment Successful';
         _successData = {
           'Amount': 'RM ${_controller.paymentAmount?.toStringAsFixed(2) ?? "0.00"}',
           'Status': 'Recovered',
         };

         if (onStateChanged != null) onStateChanged!();
         return;
      }
      
      // Use unified error mapper
      final friendlyError = mapBackendError(e);
      _emitDebugInfo(rawValue, 'error', 'Exception: $e', startTime);
      ScannerLifecycleController.setProcessing(false); // FIX: Clear processing before showing error
      await AudioHelper.playError(); // 🔊 Error Sound
      await onScanError(friendlyError);
    }
  }

  void _emitDebugInfo(String rawQr, String result, String message, DateTime startTime, {Map<String, dynamic>? backendResponse}) {
    if (onDebugInfo != null) {
      onDebugInfo!({
        'mode': 'commerce',
        'scanPoint': 'Commerce Terminal',
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
    print('✅ [Commerce Strategy] Payment complete, cleaning up...');

    // Capture data before reset
    final isCustomerScanned = _controller.isCustomerScanned;
    final customerUid = _controller.customerUid;
    final paymentAmount = _controller.paymentAmount;

    // Notify desktop that scanner is finished (and successful)
    // We do this BEFORE stopping the scanner to ensure desktop gets the success state
    await _notifyDesktopScannerStopped(
      forcedStatus: 'success',
      forcedUid: customerUid,
      forcedAmount: paymentAmount,
    );

    // Stop scanner
    await ScannerLifecycleController.stopScanning();

    // Reset controller
    _controller.reset();
    _isSuccess = false; // Reset success state
    _successMessage = null;
    _successData = null;
    _showError = false;
    _errorMessage = null;

    // Notify MobileScannerTerminal to clear strategy
    if (onStrategyFinished != null) {
      print('💳 [Commerce Strategy] Calling onStrategyFinished callback');
      onStrategyFinished!();
    }
  }

  @override
  Future<void> onScanError(String error) async {
    print('❌ [Commerce Strategy] Error: $error');

    _showError = true;
    _errorMessage = error;
    if (onStateChanged != null) onStateChanged!();

    // Note: We don't reset controller on error to allow retry
    // User can scan again or desktop can cancel
  }

  @override
  Widget? buildUI(BuildContext context) {
    // Update context for snackbars
    _context = context;

    if (!_controller.isActive) {
      return null; // No UI overlay when inactive
    }

    // FIX: Show Processing View
    if (ScannerLifecycleController.isProcessing) {
      return const JellyProcessingView();
    }

    // ✅ Full Screen Success View (Jelly Animation)
    if (_isSuccess) {
      return JellySuccessView(
        message: _successMessage ?? 'Success',
        data: _successData,
        onDone: () async {
          await onScanComplete();
        },
      );
    }

    // Material 3 "Jelly" Design UI
    return Stack(
      children: [
        // 1. Top Header Card (Payment Amount)
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: JellyCard(
            delay: 200.ms,
            color: Colors.white.withOpacity(0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.payment, color: Colors.green.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Payment Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'RM ${_controller.paymentAmount?.toStringAsFixed(2) ?? "0.00"}',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade800,
                    letterSpacing: -1,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .shimmer(duration: 2000.ms, color: Colors.green.shade400.withOpacity(0.3)),
                
                const SizedBox(height: 8),
                if (_controller.itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_controller.itemCount} item${_controller.itemCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 2. Bottom Status / Instruction Card
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: JellyCard(
            delay: 400.ms,
            color: Colors.black.withOpacity(0.8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20)
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 3000.ms),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ready to Scan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Align customer QR code within frame',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Error Overlay
        if (_showError && _errorMessage != null)
          ScanErrorOverlay(
            title: 'Payment Failed',
            subtitle: _errorMessage,
            onDismiss: () {
              _showError = false;
              _errorMessage = null;
              if (onStateChanged != null) onStateChanged!();
              // Resume scanning
              ScannerLifecycleController.setProcessing(false);
            },
          ),
      ],
    );
  }

  /// Notify desktop that scanner has stopped
  Future<void> _notifyDesktopScannerStopped({
    String? forcedStatus,
    String? forcedUid,
    double? forcedAmount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Use forced values if provided, otherwise check controller
      final isSuccess = forcedStatus == 'success' || 
                       (_controller.isCustomerScanned && _controller.customerUid != null);
      
      final uid = forcedUid ?? _controller.customerUid;
      final amount = forcedAmount ?? _controller.paymentAmount;

      // If payment was successful, send success status with details
      if (isSuccess && uid != null) {
        await FirebaseFirestore.instance
            .collection('scanner_status')
            .doc(user.uid)
            .set({
              'status': 'success',
              'student_uid': uid,
              'amount': amount,
              'timestamp': FieldValue.serverTimestamp(),
            });
        print('📡 [Commerce Strategy] Desktop notified: Payment SUCCESS');
      } else {
        // Otherwise just set to IDLE
        await FirebaseFirestore.instance
            .collection('scanner_status')
            .doc(user.uid)
            .set({'status': 'IDLE', 'timestamp': FieldValue.serverTimestamp()});
        print('📡 [Commerce Strategy] Desktop notified: Scanner IDLE');
      }
    } catch (e) {
      print('❌ [Commerce Strategy] Failed to notify desktop: $e');
    }
  }

  @override
  bool get shouldHandleStopTrigger {
    // If showing success animation, don't stop immediately.
    // Wait for the user to dismiss the success view.
    if (_isSuccess) {
      print('🛡️ [Commerce Strategy] Blocking stop trigger to show success animation');
      return false;
    }

    // FIX: Also block stop if we are currently processing a payment
    // This prevents race conditions where desktop sees DB update before mobile finishes
    if (ScannerLifecycleController.isProcessing) {
      print('🛡️ [Commerce Strategy] Blocking stop trigger during processing');
      return false;
    }

    return true;
  }
}
