import 'package:flutter/material.dart';
import '../services/scan_point_service.dart';

/// 🎯 Scanner Mode Strategy Interface
///
/// Defines the contract that all scanner mode implementations must follow.
/// This enables the Strategy Pattern for modular scanner modes.
///
/// **Implementations**:
/// - LibraryScannerStrategy (library mode)
/// - CommerceScannerStrategy (commerce/payment mode)
/// - AccessScannerStrategy (access control mode)
/// - EventScannerStrategy (booking/event mode)
abstract class ScannerModeStrategy {
  /// The unique mode identifier (e.g., 'library', 'commerce', 'access', 'event')
  String get scanMode;

  /// Called when desktop triggers this scanner mode
  ///
  /// **Parameters**:
  /// - `scanPoint`: The scan point configuration for this terminal
  /// - `data`: Optional trigger data (e.g., payment amount, cart items)
  ///
  /// **Responsibilities**:
  /// - Initialize mode-specific state
  /// - Start camera using ScannerLifecycleController
  /// - Show mode-specific UI prompts
  Future<void> onTriggerReceived(ScanPoint scanPoint, {Map<String, dynamic>? data});

  /// Called when a QR code is scanned while in this mode
  ///
  /// **Parameters**:
  /// - `rawValue`: The raw QR code string
  /// - `scanPoint`: The scan point configuration
  ///
  /// **Responsibilities**:
  /// - Parse QR code using QRParser
  /// - Process via QrProcessorService (NOT direct service calls)
  /// - Handle multi-step workflows (e.g., library: student → book)
  /// - Show success/error feedback
  Future<void> onQrScanned(String rawValue, ScanPoint scanPoint);

  /// Called when the scan completes successfully
  ///
  /// **Responsibilities**:
  /// - Reset mode state
  /// - Stop scanner using ScannerLifecycleController
  /// - Notify desktop of completion
  Future<void> onScanComplete();

  /// Called when a scan error occurs
  ///
  /// **Parameters**:
  /// - `error`: The error message
  ///
  /// **Responsibilities**:
  /// - Show error message to user
  /// - Optionally reset state or retry
  Future<void> onScanError(String error);

  /// Build mode-specific UI overlay
  ///
  /// **Parameters**:
  /// - `context`: BuildContext for rendering
  ///
  /// **Returns**: Widget tree for mode-specific UI
  ///
  /// **Responsibilities**:
  /// - Show current step indicators
  /// - Display mode-specific instructions
  /// - Render any status information
  Widget? buildUI(BuildContext context);

  /// Get scan frame type for camera view
  ///
  /// **Returns**: 'qr' for square frame, 'barcode' for wide rectangular frame
  ///
  /// **Purpose**:
  /// - Allows strategies to customize scan frame based on current step
  /// - Library mode: 'qr' for student scan, 'barcode' for book scan
  /// - Commerce mode: 'qr' for all scans
  String getScanFrameType() => 'qr'; // Default to QR square frame

  /// 🛠️ **Demo Mode Debug Callback**
  ///
  /// Called when the strategy has debug information to share with the desktop overlay.
  /// This is used for the "Demo Mode" to show live logs and backend responses.
  ///
  /// **Parameters**:
  /// - `info`: A map containing debug details:
  ///   - `mode`: The current scan mode
  ///   - `scanPoint`: The scan point name
  ///   - `timestamp`: ISO8601 timestamp
  ///   - `rawQr`: Masked QR code
  ///   - `result`: "success", "error", or "processing"
  ///   - `latencyMs`: Duration in milliseconds
  ///   - `backendResponse`: JSON response (optional)
  Function(Map<String, dynamic> info)? onDebugInfo;

  /// 🔄 **Lifecycle Callbacks**
  /// Called when the strategy completes its workflow and should be cleared.
  VoidCallback? onStrategyFinished;

  /// Called when the strategy's internal state changes (to trigger UI rebuilds).
  VoidCallback? onStateChanged;

  /// 🛑 **Stop Trigger Handler**
  ///
  /// Determines if the strategy should handle the stop trigger from the desktop.
  /// Returns `true` by default. Override to return `false` if the strategy
  /// needs to delay stopping (e.g., to show a success animation).
  bool get shouldHandleStopTrigger => true;
}
