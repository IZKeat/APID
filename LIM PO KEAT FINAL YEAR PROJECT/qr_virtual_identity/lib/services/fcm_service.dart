import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/jelly_notification.dart';
import '../pages_user/event_details_page.dart';

/// 📢 FCM Service
/// Handles Firebase Cloud Messaging (Push Notifications)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize FCM (Mobile Only)
  Future<void> init(BuildContext context) async {
    // 🛡️ Windows Safety Check
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('🖥️ FCM skipped on Desktop (Not supported)');
      return;
    }

    try {
      // 1. Request Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 FCM Permission Granted');
        
        // 2. Get & Save Token
        String? token = await _messaging.getToken();
        if (token != null) {
          await _saveTokenToDatabase(token);
        }

        // 3. Listen for Token Refresh
        _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

        // 4. Foreground Message Handler
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('📩 Foreground Message: ${message.notification?.title}');
          
          // // 🛑 Suppress Payment Notifications (Handled by UserNotificationService)
          // final type = message.data['type'];
          // if (type == 'purchase' || type == 'payment') {
          //    debugPrint('🔇 Suppressing FCM banner for payment (Handled by Firestore Listener)');
          //    return;
          // }//

          _showForegroundNotification(context, message);
        });

        // 5. Background Message Handler (Opened App)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('📩 Message Opened App: ${message.data}');
          final data = message.data;
          
          // Check for Event ID in payload
          if (data.containsKey('id')) {
             final eventId = data['id'];
             debugPrint('🚀 FCM Navigation -> Event ID: $eventId');
             
             Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(eventId: eventId),
                ),
             );
          }
        });

      } else {
        debugPrint('🔕 FCM Permission Denied');
      }
    } catch (e) {
      debugPrint('❌ FCM Init Error: $e');
    }
  }

  /// Save FCM Token to Firestore User Document
  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'last_fcm_update': FieldValue.serverTimestamp(),
      });
      debugPrint('💾 FCM Token Saved: ${token.substring(0, 6)}...');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  /// Show JellyNotification when app is in foreground
  void _showForegroundNotification(BuildContext context, RemoteMessage message) {
    // 🛑 Overlay Disabled by User Request
    // if (message.notification == null) return;

    // final overlayState = Overlay.of(context);
    // final overlayEntry = OverlayEntry(
    //   builder: (context) => Positioned(
    //     top: MediaQuery.of(context).padding.top + 10,
    //     left: 16,
    //     right: 16,
    //     child: Material(
    //       color: Colors.transparent,
    //       child: JellyNotification(
    //         title: message.notification!.title ?? 'New Notification',
    //         subtitle: message.notification!.body ?? '',
    //         onDismiss: () {}, // Handled internally by JellyNotification
    //         onTap: () {
    //           // Handle tap
    //         },
    //       ),
    //     ),
    //   ),
    // );

    // overlayState.insert(overlayEntry);
    
    // // Auto remove after 5 seconds (JellyNotification handles animation, but we need to remove entry)
    // Future.delayed(const Duration(seconds: 5), () {
    //   overlayEntry.remove();
    // });
  }
}
