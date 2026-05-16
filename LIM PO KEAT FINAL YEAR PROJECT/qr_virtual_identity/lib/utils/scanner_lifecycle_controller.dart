// lib/utils/scanner_lifecycle_controller.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// dY"? Scanner Lifecycle Controller
/// Manages the camera lifecycle and scanning state for mobile scanner terminals
///
/// This utility service handles all camera-related operations including:
/// - Camera initialization and pre-configuration
/// - Starting and stopping the scanner
/// - State management (_isScanning, _lastScanResult)
/// - Firestore scanner status updates
/// - Cleanup and disposal
///
/// **Design Pattern**: Static utility service (stateless)
/// **Used By**: MobileScannerTerminal and other scanner implementations
class ScannerLifecycleController {
  /// Shared camera controller instance (recreated if disposed)
  /// This controller is used across all scanner operations
  /// Supports both QR codes and barcodes (EAN, UPC, Code128, etc.)
  static MobileScannerController? _controller;

  static MobileScannerController get controller =>
      _controller ??= _createController();

  static MobileScannerController _createController() {
    return MobileScannerController(
      autoStart: false, // Prevent auto start to avoid double-start races
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.qrCode, // QR codes
        // BarcodeFormat.ean8, // Reduced formats for speed and stability
        // BarcodeFormat.ean13, 
      ],
    );
  }

  /// Current scanning state
  static bool _isScanning = false;
  static bool _isProcessing = false;
  static bool _isStarting = false; // Prevent re-entry
  static String? _lastScanResult;

  /// Get current scanning state
  static bool get isScanning => _isScanning;

  /// Get current processing state
  static bool get isProcessing => _isProcessing;

  /// Get last scan result
  static String? get lastScanResult => _lastScanResult;

  /// dY"? Initialize the camera controller
  static Future<void> initialize({void Function()? onStateReset}) async {
    try {
      print('dY"? [Lifecycle] Pre-initializing camera controller...');

      // Reset all states
      _isScanning = false;
      _isProcessing = false;
      _isStarting = false;
      _lastScanResult = null;
      // Ensure controller exists (it may have been disposed on previous logout)
      _controller ??= _createController();

      onStateReset?.call();

      print('?o. [Lifecycle] Initialization complete');
    } catch (e) {
      print('?s??,? [Lifecycle] Pre-initialization warning: $e');
    }
  }

  /// 🚑 Start the scanner with Auto-Retry (Robust Mode)
  static Future<void> startScanning({
    required BuildContext context,
    void Function()? onScannerReady,
    void Function(dynamic error)? onScannerFailed,
    void Function(int attempt)? onRetry,
  }) async {
    const int maxRetries = 3;
    int attempt = 1;

    print('dY"? [Lifecycle] Request to start scanner (Robust Mode)...');

    if (_isScanning) {
      print('?s??,? [Lifecycle] Scanner already started, skipping start()');
      onScannerReady?.call();
      return;
    }

    if (_isStarting) {
      print('?s??,? [Lifecycle] Scanner is currently starting, ignoring duplicate request');
      return;
    }

    _isStarting = true;

    while (attempt <= maxRetries) {
      try {
        print('🔄 [Lifecycle] Start Attempt $attempt/$maxRetries...');

        if (attempt > 1) {
           // 🛠️ Soft Reset before retry
           print('🛠️ [Lifecycle] Performing soft reset before retry...');
           await _softReset();
           onRetry?.call(attempt);
        }

        // Ensure we have a valid controller
        _controller ??= _createController();
        final cameraController = _controller!;

        // Start Camera
        try {
           await cameraController.start();
        } catch (startErr) {
           final msg = startErr.toString();
           // Swallow "already started" errors as success
           if (msg.contains('already started') || msg.contains('controllerAlreadyInitialized')) {
             print('?s??,? [Lifecycle] Driver reported already started. Treating as success.');
           } else {
             rethrow; // Real error, trigger catch block
           }
        }

        print('?o. [Lifecycle] Camera started successfully');
        
        // Setup State
        _isScanning = true;
        _lastScanResult = null;
        
        // Update Firestore
        _updateFirestoreStatus('ACTIVE');

        // Success! Break loop
        onScannerReady?.call();
        return; 

      } catch (e) {
        print('⚠️ [Lifecycle] Attempt $attempt failed: $e');
        
        if (attempt == maxRetries) {
           // ❌ Final Failure
           print('??O [Lifecycle] All retry attempts failed.');
           _isScanning = false;
           _updateFirestoreStatus('IDLE_ERROR');
           onScannerFailed?.call(e);
        } else {
           // ⏳ Wait before retry
           await Future.delayed(Duration(milliseconds: 500 * attempt)); 
        }
      }
      attempt++;
    }

    _isStarting = false;
  }

  /// 🛠️ Soft Reset: Dispose and Recreate Controller
  static Future<void> _softReset() async {
    try {
      if (_controller != null) {
        await _controller!.stop();
        _controller!.dispose();
      }
    } catch (_) {} // Ignore dispose errors
    _controller = null;
    _controller = _createController();
  }

  /// Firestore helper
  static Future<void> _updateFirestoreStatus(String status) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      try {
        await FirebaseFirestore.instance
            .collection('scanner_status')
            .doc(user.uid)
            .set({
              'state': status,
              'status': status.toLowerCase(),
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}
  }

  /// ??1 Stop the scanner
  static Future<void> stopScanning({void Function()? onScannerStopped}) async {
    print('??1 [Lifecycle] Stopping scanner...');

    try {
      // Update state immediately
      _isScanning = false;
      _isStarting = false;

      // Stop the camera
      final cameraController = _controller;
      if (cameraController != null) {
        await cameraController.stop();
      }

      // Update Firestore status - scanner is now IDLE
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('scanner_status')
              .doc(user.uid)
              .set({
                'state': 'IDLE',
                'status': 'idle',
                'updated_at': FieldValue.serverTimestamp(),
              });
          print('dY"? [Lifecycle] Status updated to IDLE in Firestore');
        } catch (e) {
          print('?s??,? [Lifecycle] Failed to update status: $e');
        }
      }

      print('??1 [Lifecycle] Scanner stopped');

      // Invoke callback
      onScannerStopped?.call();
    } catch (e) {
      print('?s??,? [Lifecycle] Stop error: $e (ignored)');
    }
  }

  /// dY", Reset scanner state
  static void resetState({void Function()? onStateReset}) {
    print('dY", [Lifecycle] Resetting scanner state...');

    _isScanning = false;
    _isProcessing = false;
    _isStarting = false;
    _lastScanResult = null;

    onStateReset?.call();

    print('?o. [Lifecycle] State reset complete');
  }

  /// dY-`?,? Dispose the camera controller
  static void dispose() {
    print('dY-`?,? [Lifecycle] Disposing camera controller...');

    try {
      final cameraController = _controller;
      _controller = null;
      if (cameraController != null) {
        cameraController.dispose();
      }
      _isScanning = false;
      _isProcessing = false;
      _isStarting = false;
      _lastScanResult = null;

      print('?o. [Lifecycle] Camera controller disposed');
    } catch (e) {
      print('?s??,? [Lifecycle] Dispose error: $e (ignored)');
    }
  }

  /// dY"? Set processing state
  static void setProcessing(bool isProcessing, {void Function()? onUpdate}) {
    _isProcessing = isProcessing;
    onUpdate?.call();
  }

  /// dY"? Set last scan result
  static void setLastScanResult(String? rawValue, {void Function()? onUpdate}) {
    _lastScanResult = rawValue;
    onUpdate?.call();
  }

  /// ?o. Check if QR code should be processed
  static bool shouldProcessQr(String rawValue) {
    if (_isProcessing) {
      print('??-?,? [Lifecycle] Already processing, skipping...');
      return false;
    }

    if (rawValue == _lastScanResult) {
      print('??-?,? [Lifecycle] Duplicate scan, skipping...');
      return false;
    }

    return true;
  }
}
