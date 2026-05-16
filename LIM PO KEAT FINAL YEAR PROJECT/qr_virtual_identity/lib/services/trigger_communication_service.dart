// lib/services/trigger_communication_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔔 Trigger Communication Service
/// Handles desktop → mobile trigger communication via Firestore
///
/// This service manages the real-time communication between desktop and mobile
/// scanner terminals using the unified trigger schema.
///
/// **Trigger Document Path**: `scanner_triggers/{scan_point_id}`
///
/// **Unified Schema**:
/// ```json
/// {
///   "active": true/false,
///   "scan_mode": "library" | "commerce" | "access" | "event",
///   "scan_point_id": "SP002",
///   "triggered_at": <Timestamp>
/// }
/// ```
class TriggerCommunicationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Listen for desktop triggers for a specific scan point
  ///
  /// Sets up a real-time listener on `scanner_triggers/{scanPointId}` that
  /// monitors the `active` flag and `scan_mode` field.
  ///
  /// **Parameters**:
  /// - `scanPointId`: The scan point ID to listen for triggers (e.g., "SP002")
  /// - `onTrigger`: Callback invoked when a trigger is received with `active: true`
  ///                Parameters: (scanMode, scanPointId)
  /// - `onError`: Optional callback for handling listener errors
  ///
  /// **Returns**: StreamSubscription that can be cancelled when no longer needed
  ///
  /// **Example**:
  /// ```dart
  /// final subscription = TriggerCommunicationService.listen(
  ///   scanPointId: 'SP002',
  ///   onTrigger: (scanMode, scanPointId) async {
  ///     print('Received trigger: $scanMode for $scanPointId');
  ///     // Handle the trigger...
  ///   },
  /// );
  ///
  /// // Later, cancel the subscription
  /// await subscription.cancel();
  /// ```
  static StreamSubscription<DocumentSnapshot> listen({
    required String scanPointId,
    required Future<void> Function(
      String scanMode,
      String scanPointId,
      Map<String, dynamic> data,
    )
    onTrigger,
    VoidCallback? onStop,
    void Function(Object error)? onError,
  }) {
    print(
      '📱 [TriggerService] Setting up listener for scan point: $scanPointId',
    );

    return _db
        .collection('scanner_triggers')
        .doc(scanPointId)
        .snapshots()
        .listen(
          (doc) async {
            print('\n🔔 [TriggerService] Snapshot received for: $scanPointId');
            print('🔔 [TriggerService] Timestamp: ${DateTime.now()}');
            print('🔔 [TriggerService] Document exists: ${doc.exists}');

            // Skip if document doesn't exist
            if (!doc.exists) {
              print(
                '⚠️ [TriggerService] Trigger document does not exist for: $scanPointId',
              );
              return;
            }

            final data = doc.data();
            if (data == null) {
              print(
                '⚠️ [TriggerService] Trigger document data is null for: $scanPointId',
              );
              return;
            }

            // Check for active trigger
            final active = data['active'] as bool? ?? false;
            final scanMode = data['scan_mode'] as String?;

            print('🔔 [TriggerService] Data received:');
            print('   - active: $active');
            print('   - scan_mode: $scanMode');
            print('   - scan_point_id: ${data['scan_point_id']}');
            print('   - triggered_at: ${data['triggered_at']}');

            if (active && scanMode != null) {
              print('🔥🔥🔥 [TriggerService] TRIGGER IS ACTIVE! 🔥🔥🔥');
              print('🔥 Mode: $scanMode, Scan Point: $scanPointId');

              try {
                // Invoke the callback
                await onTrigger(scanMode, scanPointId, data);
              } catch (e) {
                print('❌ [TriggerService] Error in onTrigger callback: $e');
                rethrow;
              }
            } else {
              // Trigger is not active or missing scan_mode
              if (!active) {
                print(
                  '📭 [TriggerService] Trigger inactive (active=false) for: $scanPointId',
                );
                // Invoke onStop if provided
                if (onStop != null) {
                  print('🛑 [TriggerService] Invoking onStop callback');
                  onStop();
                }
              } else if (scanMode == null) {
                print(
                  '⚠️ [TriggerService] Trigger missing scan_mode for: $scanPointId',
                );
              }
            }
          },
          onError: (error) {
            print('❌ [TriggerService] Listener error for $scanPointId: $error');
            if (onError != null) {
              onError(error);
            }
          },
        );
  }

  /// Reset a trigger to inactive state
  ///
  /// Updates the trigger document to set `active: false`, indicating that
  /// the trigger has been consumed by the mobile scanner.
  ///
  /// **Parameters**:
  /// - `scanPointId`: The scan point ID whose trigger should be reset
  ///
  /// **Example**:
  /// ```dart
  /// await TriggerCommunicationService.resetTrigger('SP002');
  /// ```
  ///
  /// **Note**: This should be called immediately after receiving a trigger
  /// to prevent the same trigger from being processed multiple times.
  static Future<void> resetTrigger(String scanPointId) async {
    try {
      print('🔄 [TriggerService] Resetting trigger for: $scanPointId');

      await _db.collection('scanner_triggers').doc(scanPointId).update({
        'active': false,
      });

      print('✅ [TriggerService] Trigger reset successfully for: $scanPointId');
    } catch (e) {
      print('❌ [TriggerService] Failed to reset trigger for $scanPointId: $e');
      rethrow;
    }
  }

  /// Check if a trigger is currently active for a scan point
  ///
  /// Performs a one-time read of the trigger document to check if there's
  /// an active trigger waiting.
  ///
  /// **Parameters**:
  /// - `scanPointId`: The scan point ID to check
  ///
  /// **Returns**: True if trigger exists and is active, false otherwise
  ///
  /// **Example**:
  /// ```dart
  /// final hasActiveTrigger = await TriggerCommunicationService.isActive('SP002');
  /// if (hasActiveTrigger) {
  ///   print('Trigger is waiting!');
  /// }
  /// ```
  static Future<bool> isActive(String scanPointId) async {
    try {
      final doc = await _db
          .collection('scanner_triggers')
          .doc(scanPointId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      if (data == null) {
        return false;
      }

      final active = data['active'] as bool? ?? false;
      return active;
    } catch (e) {
      print(
        '❌ [TriggerService] Failed to check trigger status for $scanPointId: $e',
      );
      return false;
    }
  }

  /// Get the current trigger data for a scan point
  ///
  /// Retrieves the full trigger document including scan_mode, triggered_at, etc.
  ///
  /// **Parameters**:
  /// - `scanPointId`: The scan point ID to query
  ///
  /// **Returns**: Map containing trigger data, or null if not found/inactive
  ///
  /// **Example**:
  /// ```dart
  /// final trigger = await TriggerCommunicationService.getTriggerData('SP002');
  /// if (trigger != null) {
  ///   print('Scan mode: ${trigger['scan_mode']}');
  ///   print('Triggered at: ${trigger['triggered_at']}');
  /// }
  /// ```
  static Future<Map<String, dynamic>?> getTriggerData(
    String scanPointId,
  ) async {
    try {
      final doc = await _db
          .collection('scanner_triggers')
          .doc(scanPointId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      final active = data['active'] as bool? ?? false;
      if (!active) {
        return null; // Only return data if trigger is active
      }

      return data;
    } catch (e) {
      print(
        '❌ [TriggerService] Failed to get trigger data for $scanPointId: $e',
      );
      return null;
    }
  }
}
