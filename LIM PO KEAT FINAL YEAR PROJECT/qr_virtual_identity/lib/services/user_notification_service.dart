// lib/services/user_notification_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/jelly_notification.dart';
import '../pages_user/payment_success_page.dart';

/// 📢 User Notification Service
/// Monitors user's interactions in real-time and shows notifications
/// when the user is scanned at access points, libraries, etc.
class UserNotificationService {
  static final Set<String> _processedIds = {};
  static StreamSubscription<QuerySnapshot>? _interactionListener;
  static DateTime? _lastNotificationTime;
  static String? _currentUserId;
  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  /// Start listening for user's interaction events
  static void startListening(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_currentUserId != user.uid) {
      _processedIds.clear(); // 🧹 Clear cache only if user changes
    }

    if (_interactionListener != null && _currentUserId == user.uid) {
      return;
    }

    _currentUserId = user.uid;
    _lastNotificationTime = DateTime.now();
    // _processedIds.clear(); // ❌ Don't clear on every restart, keep history for session

    print('👂 [UserNotification] Starting global listener for: ${user.uid}');

    _interactionListener = FirebaseFirestore.instance
        .collection('interactions')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .listen(
          (snapshot) => _handleInteractionUpdate(context, snapshot),
          onError: (e) => print('❌ [UserNotification] Error: $e'),
        );
  }

  static void stopListening() {
    _interactionListener?.cancel();
    _interactionListener = null;
    // _currentUserId = null; // Keep user ID to check against next time
    // _processedIds.clear(); // ❌ Don't clear history when leaving page
    _removeNotification();
  }

  /// Get stream of recent messages for Inbox
  /// Get stream of recent messages for Inbox with optional filtering
  /// [filterTypes] - List of types to filter by (e.g. ['payment', 'purchase'])
  static Stream<QuerySnapshot> getInboxStream({List<String>? filterTypes, int limit = 50}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    Query query = FirebaseFirestore.instance
        .collection('interactions')
        .where('user_id', isEqualTo: user.uid);

    // Apply Type Filter if provided
    if (filterTypes != null && filterTypes.isNotEmpty) {
      query = query.where('type', whereIn: filterTypes);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// 🏷️ Helper to get types for a specific category
  static List<String> getCategoryTypes(String category) {
    switch (category.toLowerCase()) {
      case 'commerce':
        return ['purchase', 'payment'];
      case 'access':
        return ['access_granted', 'access_denied'];
      case 'library':
        return ['book_borrowed', 'book_returned'];
      case 'event':
        return ['event_checkin', 'event_joined'];
      default:
        return []; // Empty means 'All'
    }
  }

  static void _handleInteractionUpdate(
    BuildContext context,
    QuerySnapshot snapshot,
  ) {
    for (var change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) continue;

      final data = change.doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      // 🛡️ Anti-Spam: Check if already processed
      final interactionId = data['interaction_id'] ?? change.doc.id;
      if (_processedIds.contains(interactionId)) {
        continue;
      }
      _processedIds.add(interactionId);

      // Filter old events (older than 30s to be safe, but rely on _lastNotificationTime)
      if (_lastNotificationTime != null &&
          timestamp.toDate().isBefore(_lastNotificationTime!)) {
        continue;
      }

      // Filter events older than 10 seconds (to avoid spam on login)
      if (DateTime.now().difference(timestamp.toDate()).inSeconds > 10) {
        continue;
      }

      final type = data['type'] as String?;

      // 🎉 Handle Payment Success (Full Screen)
      if (type == 'purchase' || type == 'payment') {
        print('💰 [UserNotification] Payment detected, navigating to Success Page');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(data: data),
          ),
        );
        return; // Don't show banner
      }

      _showGlobalNotification(context, data);
    }
  }

  static void _showGlobalNotification(
      BuildContext context, Map<String, dynamic> data) {
    // 🛑 Overlay Disabled by User Request
    // _removeNotification(); // Remove existing if any

    // final overlayState = Overlay.of(context);
    
    // _currentOverlay = OverlayEntry(
    //   builder: (context) => Positioned(
    //     top: MediaQuery.of(context).padding.top + 10,
    //     left: 16,
    //     right: 16,
    //     child: Material(
    //       color: Colors.transparent,
    //       child: JellyNotification(
    //         title: _getTitle(data['type']),
    //         subtitle: data['scan_point_name'] ?? 'Campus Point',
    //         amount: data['amount'] != null ? 'RM ${data['amount']}' : null,
    //         onDismiss: _removeNotification,
    //         onTap: () {
    //           _removeNotification();
    //           // TODO: Navigate to details
    //         },
    //       ),
    //     ),
    //   ),
    // );

    // overlayState.insert(_currentOverlay!);

    // // Auto dismiss
    // _dismissTimer = Timer(const Duration(seconds: 5), _removeNotification);
  }

  static void _removeNotification() {
    _dismissTimer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  static String _getTitle(String? type) {
    switch (type) {
      case 'payment':
        return 'Payment Successful';
      case 'access_granted':
        return 'Access Granted';
      case 'access_denied':
        return 'Access Denied';
      case 'book_borrowed':
        return 'Book Borrowed';
      default:
        return 'New Notification';
    }
  }
}
