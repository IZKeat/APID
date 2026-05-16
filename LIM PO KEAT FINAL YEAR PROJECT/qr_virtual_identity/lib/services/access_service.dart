// lib/services/access_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/scan_point_service.dart';
import '../services/qr_processor_service.dart';

/// 🔐 Access Service
/// Handles entry/exit access control for secure areas and buildings
class AccessService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // TODO: Move this to a secure storage or remote config
  static const String _hmacSecret = "SUPER_SECRET_256_BIT_KEY";

  /// Verify HMAC Signature
  static bool _verifyHmac(String uid, int timestamp, String nonce, String signature) {
    try {
      final key = utf8.encode(_hmacSecret);
      final bytes = utf8.encode('$uid|$timestamp|$nonce');
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(bytes);
      final expectedSignature = digest.toString();
      return signature == expectedSignature;
    } catch (e) {
      print('❌ [AccessService] Security Check Error: $e');
      return false;
    }
  }

  /// Process access control for access scan points
  ///
  /// Simplified access control:
  /// 1. Check if user is blacklisted → DENY
  /// 2. Check if user is in whitelist (access_permissions) → ALLOW
  /// 3. Otherwise → DENY
  ///
  /// No entry/exit logic, no time-based rules, no auto-toggle
  static Future<QrProcessResponse> processEntry({
    required String userId,
    required ScanPoint scanPoint,
    // Security Parameters
    int? timestamp,
    String? nonce,
    String? signature,
  }) async {
    try {
      print('🔐 [AccessService] Processing access for user: $userId');

      // 🔒 Security Check: HMAC Verification
      if (timestamp != null && nonce != null && signature != null) {
        // Check for replay attacks (Timestamp expiry - 60 seconds)
        final now = DateTime.now().millisecondsSinceEpoch;
        if ((now - timestamp).abs() > 60000) {
             return QrProcessResponse.error(
            'QR Code Expired. Please refresh.',
            'QR_EXPIRED',
          );
        }

        final isValid = _verifyHmac(userId, timestamp, nonce, signature);
        if (!isValid) {
          return QrProcessResponse.error(
            'Security Alert: Invalid QR Signature',
            'INVALID_SIGNATURE',
          );
        }
        print('🔒 [AccessService] HMAC Correct. Secure Access.');
      } else {
        print('⚠️ [AccessService] Warning: Processing unsecured transaction!');
      }

      print(
        '🔐 [AccessService] Scan point: ${scanPoint.name} (${scanPoint.type})',
      );


      // Validate scan point type
      if (scanPoint.type != 'access') {
        return QrProcessResponse.error(
          'Access processing is only available for access scan points',
          'INVALID_SCAN_POINT_TYPE',
        );
      }

      // Get user data
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('⚠️ [AccessService] User not found: $userId');
        return QrProcessResponse.error(
          'User not found',
          'USER_NOT_FOUND',
        );
      }

      final userData = userDoc.data()!;

      // STEP 1: Check blacklist (priority check)
      final isBlacklisted = userData['is_blacklisted'] as bool? ?? false;
      if (isBlacklisted) {
        print('❌ [AccessService] User is blacklisted: $userId');
        
        // Log denied access attempt
        await _logAccessAttempt(
          userId: userId,
          scanPoint: scanPoint,
          allowed: false,
          reason: 'User is blacklisted',
        );

        return QrProcessResponse.error(
          'Access blocked. Please contact security.',
          'BLACKLISTED',
        );
      }

      // STEP 2: Check whitelist (access_permissions array)
      final accessPermissions =
          userData['access_permissions'] as List<dynamic>? ?? [];

      if (!accessPermissions.contains(scanPoint.scanPointId)) {
        print('❌ [AccessService] User not in whitelist for: ${scanPoint.scanPointId}');
        
        // Log denied access attempt
        await _logAccessAttempt(
          userId: userId,
          scanPoint: scanPoint,
          allowed: false,
          reason: 'Not authorized for this access point',
        );

        return QrProcessResponse.error(
          'Not authorized for this access point',
          'NOT_WHITELISTED',
        );
      }

      // STEP 3: Access GRANTED - user is whitelisted
      print('✅ [AccessService] Access GRANTED for user: $userId');

      return await _processAccessGrant(userId, scanPoint, userData);
    } catch (e) {
      print('❌ [AccessService] Error processing access: $e');
      return QrProcessResponse.error(
        'Access processing failed: ${e.toString()}',
        'ACCESS_PROCESSING_ERROR',
      );
    }
  }

  /// Process access grant and log interaction
  static Future<QrProcessResponse> _processAccessGrant(
    String userId,
    ScanPoint scanPoint,
    Map<String, dynamic> userData,
  ) async {
    try {
      final interactionId = _db.collection('interactions').doc().id;
      final userEmail = userData['email'] as String?;
      final userName = userData['name'] as String? ?? 
                       '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();

      // Create access granted interaction
      await _db.collection('interactions').doc(interactionId).set({
        'user_id': userId,
        'user_email': userEmail,
        'user_name': userName.isNotEmpty ? userName : null,
        'scan_point_id': scanPoint.scanPointId,
        'scan_point_name': scanPoint.name,
        'type': 'access_granted',
        'location': scanPoint.location ?? 'Unknown location',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'success',
        'interaction_id': interactionId,
      });

      // Update scan point statistics
      await _db.collection('scan_points').doc(scanPoint.id).update({
        'interaction_count': FieldValue.increment(1),
        'scan_count': FieldValue.increment(1),
        'last_active': FieldValue.serverTimestamp(),
      });

      // Update user's access activity
      await _db.collection('users').doc(userId).update({
        'access_count': FieldValue.increment(1),
        'last_access_activity': FieldValue.serverTimestamp(),
      });

      return QrProcessResponse.success(
        'Access granted! Welcome to ${scanPoint.name}',
        {
          'access_granted': true,
          'access_point': scanPoint.name,
          'location': scanPoint.location ?? 'Unknown location',
          'timestamp': DateTime.now().toIso8601String(),
          'interaction_id': interactionId,
          'user_email': userEmail,
          'user_name': userName.isNotEmpty ? userName : null,
        },
      );
    } catch (e) {
      print('❌ [AccessService] Error processing access grant: $e');
      return QrProcessResponse.error(
        'Failed to grant access: ${e.toString()}',
        'ACCESS_GRANT_ERROR',
      );
    }
  }

  /// Log access attempt (for denied access)
  static Future<void> _logAccessAttempt({
    required String userId,
    required ScanPoint scanPoint,
    required bool allowed,
    required String reason,
  }) async {
    try {
      final interactionId = _db.collection('interactions').doc().id;

      await _db.collection('interactions').doc(interactionId).set({
        'user_id': userId,
        'scan_point_id': scanPoint.scanPointId,
        'scan_point_name': scanPoint.name,
        'type': 'access_denied',
        'location': scanPoint.location ?? 'Unknown location',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'denied',
        'denial_reason': reason,
        'interaction_id': interactionId,
      });

      print('📝 [AccessService] Logged denied access attempt: $reason');
    } catch (e) {
      print('❌ [AccessService] Error logging access attempt: $e');
    }
  }

  /// Grant access permission to a user for specific scan points
  static Future<bool> grantAccessPermission(
    String userId,
    List<String> scanPointIds,
  ) async {
    try {
      print('🔑 [AccessService] Granting access permission to user: $userId');

      await _db.collection('users').doc(userId).update({
        'access_permissions': FieldValue.arrayUnion(scanPointIds),
        'permissions_updated': FieldValue.serverTimestamp(),
      });

      print('✅ [AccessService] Access permissions granted successfully');
      return true;
    } catch (e) {
      print('❌ [AccessService] Error granting access permission: $e');
      return false;
    }
  }

  /// Revoke access permission from a user
  static Future<bool> revokeAccessPermission(
    String userId,
    List<String> scanPointIds,
  ) async {
    try {
      print('🔒 [AccessService] Revoking access permission from user: $userId');

      await _db.collection('users').doc(userId).update({
        'access_permissions': FieldValue.arrayRemove(scanPointIds),
        'permissions_updated': FieldValue.serverTimestamp(),
      });

      print('✅ [AccessService] Access permissions revoked successfully');
      return true;
    } catch (e) {
      print('❌ [AccessService] Error revoking access permission: $e');
      return false;
    }
  }

  /// Get access statistics for a scan point
  static Future<Map<String, dynamic>> getAccessStats(String scanPointId) async {
    try {
      print('📊 [AccessService] Getting access stats for: $scanPointId');

      // Get today's access activities
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayActivities = await _db
          .collection('interactions')
          .where('scan_point_id', isEqualTo: scanPointId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('type', whereIn: ['entry', 'exit'])
          .get();

      // Count entries and exits
      int todayEntries = 0;
      int todayExits = 0;

      for (final doc in todayActivities.docs) {
        final type = doc.data()['type'] as String;
        if (type == 'entry') {
          todayEntries++;
        } else if (type == 'exit') {
          todayExits++;
        }
      }

      // Current occupancy (entries - exits today)
      final currentOccupancy = todayEntries - todayExits;

      return {
        'today_entries': todayEntries,
        'today_exits': todayExits,
        'total_today_activities': todayActivities.docs.length,
        'estimated_current_occupancy': currentOccupancy > 0
            ? currentOccupancy
            : 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ [AccessService] Error getting access stats: $e');
      return {};
    }
  }

  /// Get user's access history
  static Future<List<Map<String, dynamic>>> getUserAccessHistory(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final accessHistory = await _db
          .collection('interactions')
          .where('user_id', isEqualTo: userId)
          .where('type', whereIn: ['entry', 'exit'])
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return accessHistory.docs.map((doc) {
        final data = doc.data();
        return {
          'type': data['type'],
          'scan_point_name': data['scan_point_name'],
          'location': data['location'],
          'timestamp': (data['timestamp'] as Timestamp)
              .toDate()
              .toIso8601String(),
          'interaction_id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('❌ [AccessService] Error getting user access history: $e');
      return [];
    }
  }
}
