// lib/services/generic_qr_processing_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/qr_parser.dart';
import '../services/scan_point_service.dart';
import '../services/qr_processor_service.dart';
import '../utils/scanner_lifecycle_controller.dart';
import '../scanner_modules/scanner_mode_strategy.dart';

/// Generic QR Processing Service
///
/// Handles all non-strategy QR code processing logic.
/// This is the FALLBACK processor when no scanner strategy is active.
///
/// Responsibilities:
/// - Parse QR codes using QRParser
/// - Validate QR types (user, item, location, event)
/// - Route valid QR codes to QrProcessorService
/// - Display success/error feedback via snackbars
/// - Stop scanner after processing
/// - Notify desktop of completion
///
/// Strategy Pattern Integration:
/// - If a strategy is active, this service is BYPASSED
/// - Strategies (library, commerce) handle their own QR processing
/// - This service only processes generic, non-modal QR scans
class GenericQrProcessingService {
  /// Main entry point for generic QR processing
  ///
  /// Returns early if a strategy is active (strategy handles its own QR codes)
  static Future<void> handle({
    required String rawValue,
    required ScanPoint scanPoint,
    required BuildContext context,
    required ScannerModeStrategy? activeStrategy,
  }) async {
    // Strategy check - if strategy is active, let it handle the QR
    if (activeStrategy != null) {
      print(
        '🔄 [GenericQR] Strategy active (${activeStrategy.scanMode}) - skipping generic processing',
      );
      return;
    }

    print('📋 [GenericQR] Processing generic QR: $rawValue');

    try {
      // Parse QR code
      final result = QRParser.parse(rawValue);

      print(
        '📋 [GenericQR] Parse result: ${result.type}, isValid: ${result.isValid}',
      );
      if (result.type == QrType.user) {
        print('📋 [GenericQR] User ID: ${result.userId}');
        if (result.email != null) {
          print('📋 [GenericQR] Email: ${result.email}');
        }
        if (result.name != null) print('📋 [GenericQR] Name: ${result.name}');
      }

      if (!result.isValid) {
        _showError(context, 'Invalid QR Code: ${result.errorMessage}');
        await _cleanupAfterProcessing(context);
        return;
      }

      print('✅ [GenericQR] QR parsed successfully: ${result.type}');

      // Route based on QR type
      await _processQrByType(
        result: result,
        scanPoint: scanPoint,
        context: context,
      );
    } catch (e) {
      print('❌ [GenericQR] Error processing QR code: $e');
      if (context.mounted) {
        _showError(context, 'Failed to process QR code: ${e.toString()}');
      }
      if (context.mounted) {
        await _cleanupAfterProcessing(context);
      }
    }
  }

  /// Route QR processing based on type
  static Future<void> _processQrByType({
    required QrParseResult result,
    required ScanPoint scanPoint,
    required BuildContext context,
  }) async {
    print(
      '📍 [GenericQR] Processing for scan point: ${scanPoint.name} (${scanPoint.type})',
    );

    // Use QrProcessorService for universal routing
    final response = await QrProcessorService.process(result, scanPoint);

    if (!context.mounted) return;

    if (response.success) {
      // Show success feedback
      final details = _getResponseDetails(response);
      _showSuccess(context, response.message, details);
    } else {
      // Show error feedback
      _showError(context, response.message);
    }

    // Always cleanup after processing
    await _cleanupAfterProcessing(context);
  }

  /// Extract details from QrProcessorService response for display
  static String _getResponseDetails(QrProcessResponse response) {
    final details = <String>[];

    // Extract common response data
    if (response.data != null) {
      // User information
      if (response.data!.containsKey('user_name')) {
        details.add('User: ${response.data!['user_name']}');
      }
      if (response.data!.containsKey('user_email')) {
        details.add('Email: ${response.data!['user_email']}');
      }

      // Item information
      if (response.data!.containsKey('item_title')) {
        details.add('Item: ${response.data!['item_title']}');
      }
      if (response.data!.containsKey('book_title')) {
        details.add('Book: ${response.data!['book_title']}');
      }

      // Transaction information
      if (response.data!.containsKey('transaction_amount')) {
        final amount = response.data!['transaction_amount'];
        details.add('Amount: RM ${amount.toStringAsFixed(2)}');
      }

      // Location information
      if (response.data!.containsKey('location_name')) {
        details.add('Location: ${response.data!['location_name']}');
      }

      // Event information
      if (response.data!.containsKey('event_title')) {
        details.add('Event: ${response.data!['event_title']}');
      }
      if (response.data!.containsKey('event_date')) {
        details.add('Date: ${response.data!['event_date']}');
      }

      // Operation type
      if (response.data!.containsKey('operation')) {
        details.add('Operation: ${response.data!['operation']}');
      }
    }

    return details.isEmpty ? 'Processing completed' : details.join('\n');
  }

  /// Cleanup after QR processing
  static Future<void> _cleanupAfterProcessing(BuildContext context) async {
    // Stop scanner
    await ScannerLifecycleController.stopScanning(
      onScannerStopped: () {
        // Scanner stopped callback
      },
    );

    // Notify desktop that scanner has stopped
    await _notifyDesktopScannerStopped();

    // Reset processing state
    ScannerLifecycleController.setProcessing(
      false,
      onUpdate: () {
        // State update callback
      },
    );

    print('📱 [GenericQR] QR processing completed, scanner stopped');
  }

  /// Notify desktop that mobile scanner has stopped after successful QR scan
  static Future<void> _notifyDesktopScannerStopped() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('📡 [GenericQR] Notifying desktop that scanner has stopped');

      // Update scanner_status to IDLE to notify desktop immediately
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(user.uid)
          .set({
            'state': 'IDLE',
            'status': 'idle',
            'updated_at': FieldValue.serverTimestamp(),
            'last_scan_completed': FieldValue.serverTimestamp(),
          });

      // Also find and update the latest consumed scanner_trigger
      final triggerQuery = await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .where('target_uid', isEqualTo: user.uid)
          .where('status', isEqualTo: 'consumed')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (triggerQuery.docs.isNotEmpty) {
        final latestTrigger = triggerQuery.docs.first;

        // Update status to "stopped"
        await latestTrigger.reference.update({
          'status': 'stopped',
          'stopped_at': FieldValue.serverTimestamp(),
          'stopped_reason': 'qr_scan_completed',
        });

        print(
          '✅ [GenericQR] Desktop notified - trigger status updated to stopped',
        );
      } else {
        print('⚠️ [GenericQR] No consumed trigger found to update');
      }
    } catch (e) {
      print('❌ [GenericQR] Failed to notify desktop: $e');
    }
  }

  /// Show success message with details
  static void _showSuccess(
    BuildContext context,
    String message,
    String details,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (details.isNotEmpty)
                    Text(details, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error message
  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
