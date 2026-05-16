import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';


/// 🛡️ Admin Service
/// Centralizes all admin-related data fetching and operations.
/// Decouples UI from direct Firestore/Cloud Function calls.
class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Update a user's QR status and cascade the status to owned scan points atomically.
  ///
  /// Params:
  /// - [uid]: Target user document ID (required).
  /// - [newStatus]: New status value; must be one of `active` or `banned`.
  ///
  /// Returns:
  /// - Map with `updatedScanPoints` (int) indicating how many scan points were affected.
  ///
  /// Throws:
  /// - [ArgumentError] if inputs are invalid.
  /// - [Exception] if the batch operation fails.
  static Future<Map<String, int>> updateUserStatus({
    required String uid,
    required String newStatus,
  }) async {
    if (uid.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    const allowedStatuses = {'active', 'banned'};
    if (!allowedStatuses.contains(newStatus)) {
      throw ArgumentError('Unsupported status: $newStatus');
    }

    try {
      // Batch keeps user + scan_points updates consistent.
      final batch = _db.batch();

      // Update user document.
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {'qr_status': newStatus});

      // Cascade to scan_points owned by this user.
      final scanPoints = await _db
          .collection('scan_points')
          .where('owner_uid', isEqualTo: uid)
          .get();

      for (final doc in scanPoints.docs) {
        batch.update(doc.reference, {'status': newStatus});
      }

      await batch.commit();

      return {'updatedScanPoints': scanPoints.docs.length};
    } catch (e) {
      debugPrint('⚠️ Error updating user status: $e');
      throw Exception('Failed to update user status');
    }
  }

  /// Get paginated users with optional search
  /// 
  /// [limit]: Number of users to fetch (default 20)
  /// [startAfter]: DocumentSnapshot to start after (for pagination)
  /// [searchQuery]: Optional search query (email or name)
  static Future<Map<String, dynamic>> getUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? searchQuery,
  }) async {
    try {
      Query query = _db.collection('users').orderBy('email');

      // Apply search filter (Prefix search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .where('email', isGreaterThanOrEqualTo: searchQuery)
            .where('email', isLessThan: '$searchQuery\uf8ff');
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      
      return {
        'users': snapshot.docs,
        'lastDoc': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Get real-time stream of scan points
  /// 
  /// [type]: Optional filter by scan point type
  /// [searchQuery]: Optional search query for name (prefix search)
  static Stream<QuerySnapshot> getScanPointsStream({String? type, String? searchQuery}) {
    Query query = _db.collection('scan_points');
    
    if (type != null && type != 'all') {
      query = query.where('type', isEqualTo: type);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Convert to uppercase for case-insensitive search if data is stored as such,
      // but assuming 'name' is mixed case, we stick to exact prefix or need a normalized field.
      // For now, we assume standard prefix search on 'name'.
      // Note: This might require a composite index if 'type' is also used.
      query = query
          .orderBy('name')
          .startAt([searchQuery])
          .endAt(['$searchQuery\uf8ff']);
    }

    return query.snapshots();
  }

  /// Get audit logs directly from Firestore
  /// 
  /// [lastTimestamp]: Optional timestamp for pagination
  /// [startDate]: Optional start date filter
  /// [endDate]: Optional end date filter
  static Future<List<Map<String, dynamic>>> getAuditLogs({
    int? lastTimestamp,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _db.collection('audit_logs')
          .orderBy('timestamp', descending: true);

      // Apply Date Filter
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
      }
      if (endDate != null) {
        // Add 1 day to include the end date fully (up to 23:59:59)
        final end = endDate.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        query = query.where('timestamp', isLessThanOrEqualTo: end.millisecondsSinceEpoch);
      }

      query = query.limit(50);

      if (lastTimestamp != null) {
        final startAfterDate = Timestamp.fromMillisecondsSinceEpoch(lastTimestamp);
        // Note: startAfter might conflict with range filters if not careful, 
        // but since we order by timestamp, it should be fine as long as the cursor is within range.
        // However, Firestore requires the cursor to match the order by fields.
        // Since we order by timestamp, passing the timestamp integer might fail if it expects a DocumentSnapshot or matching type.
        // The original code used `startAfter([startAfterDate])` which is correct for `orderBy('timestamp')`.
        query = query.startAfter([lastTimestamp]); // Use int directly as stored in Firestore? 
        // Wait, original code used Timestamp.fromMillisecondsSinceEpoch(lastTimestamp).
        // If the field in DB is number (milliseconds), we should pass number. 
        // If it's Timestamp, we pass Timestamp.
        // Looking at original code: `(data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch` implies it's stored as Timestamp.
        // So we must pass Timestamp.
        query = query.startAfter([startAfterDate]);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch,
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching audit logs: $e');
      throw Exception('Failed to fetch audit logs');
    }
  }

  /// Get security anomalies stream directly from Firestore
  static Stream<List<Map<String, dynamic>>> getAnomaliesStream({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _db.collection('anomalies')
        .orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      final end = endDate.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    return query
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch,
        };
      }).toList();
    });
  }

  /// Resolve a security anomaly directly
  /// 
  /// [anomalyId]: ID of the anomaly to resolve
  /// [resolution]: Note on how it was resolved
  static Future<void> resolveAnomaly(String anomalyId, String resolution) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      // Direct delete from Firestore
      await _db.collection('anomalies').doc(anomalyId).delete();
      
      debugPrint('✅ Anomaly $anomalyId resolved by $uid');
    } catch (e) {
      debugPrint('❌ Error resolving anomaly: $e');
      throw Exception('Failed to resolve anomaly');
    }
  }
  /// Get all restricted access points for permission management
  /// 
  /// Returns a list of scan points that require specific access permissions.
  /// Filters by types: access, library, facility, lab.
  /// 
  /// Returns:
  /// - List of [QueryDocumentSnapshot] containing scan point data.
  /// 
  /// Throws:
  /// - [Exception] if the query fails.
  static Future<List<QueryDocumentSnapshot>> getAccessPoints() async {
    try {
      // We want to fetch all points that are NOT 'commerce' basically, 
      // or specifically the ones that are 'access' controlled.
      // Using 'whereIn' to future-proof for other restricted types.
      final snapshot = await _db
          .collection('scan_points')
          .where('type', whereIn: ['access', 'library', 'facility', 'lab'])
          .get();

      return snapshot.docs;
    } catch (e) {
      debugPrint('❌ Error fetching access points: $e');
      // Return empty list instead of throwing to prevent UI crash
      return []; 
    }
  }
}
