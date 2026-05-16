// lib/services/scanner_notification_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 📢 Scanner Notification Service
/// Centralized user feedback and desktop notification management
class ScannerNotificationService {
  /// Show success message (green snackbar) - DISABLED for Jelly UI
  static void showSuccess({
    required BuildContext context,
    required String message,
    String? details,
  }) {
    // Legacy snackbar removed.
    // Feedback is now handled by JellyNotification in the UI layer.
  }

  /// Show error message (red snackbar) - DISABLED for Jelly UI
  static void showError({
    required BuildContext context,
    required String message,
  }) {
    // Legacy snackbar removed.
    // Feedback is now handled by JellyNotification in the UI layer.
  }

  /// Show info message (blue snackbar) - DISABLED for Jelly UI
  static void showInfo({
    required BuildContext context,
    required String message,
  }) {
    // Legacy snackbar removed.
    // Feedback is now handled by JellyNotification in the UI layer.
  }

  /// Notify desktop that scanner has stopped
  /// Updates scanner_status to IDLE and marks latest trigger as stopped
  static Future<void> notifyDesktopScannerStopped() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
          '⚠️ [Notification Service] Cannot notify desktop - no user logged in',
        );
        return;
      }

      final userId = user.uid;
      print(
        '🔔 [Notification Service] Notifying desktop: Scanner stopped for user $userId',
      );

      // 1. Update scanner_status to IDLE
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(userId)
          .set({
            'state': 'IDLE',
            'status': 'idle',
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // 2. Mark the latest consumed trigger as stopped
      final triggerQuery = await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'consumed')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (triggerQuery.docs.isNotEmpty) {
        final triggerId = triggerQuery.docs.first.id;
        await FirebaseFirestore.instance
            .collection('scanner_triggers')
            .doc(triggerId)
            .update({
              'status': 'stopped',
              'updated_at': FieldValue.serverTimestamp(),
            });
        print(
          '✅ [Notification Service] Desktop notified - trigger $triggerId marked as stopped',
        );
      } else {
        print(
          '⚠️ [Notification Service] No consumed trigger found to mark as stopped',
        );
      }
    } catch (e) {
      print('❌ [Notification Service] Error notifying desktop: $e');
    }
  }
}
