// lib/services/scan_point_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 📍 ScanPoint Model Class
/// Represents a scan point (merchant terminal, library desk, access gate, etc.)
class ScanPoint {
  /// Document ID from Firestore
  final String id;

  /// Unique scan point identifier
  final String scanPointId;

  /// Display name of the scan point
  final String name;

  /// Type: commerce, library, access, or booking
  final String type;

  /// Physical location description
  final String? location;

  /// Additional description or notes
  final String? description;

  /// Tags for categorization and filtering
  final List<String> tags;

  /// Owner user ID (merchant/staff)
  final String? ownerUid;

  /// Whether this scan point is currently active
  final bool active;

  /// Total revenue (for commerce type only)
  final double? revenue;

  /// Today's revenue (for commerce type only)
  final double? todayRevenue;

  /// QR code data for this scan point
  final String? qrCode;

  /// Total scan count
  final int scanCount;

  /// Total interaction count
  final int interactionCount;

  /// Last active timestamp
  final DateTime? lastActive;

  const ScanPoint({
    required this.id,
    required this.scanPointId,
    required this.name,
    required this.type,
    this.location,
    this.description,
    this.tags = const [],
    this.ownerUid,
    required this.active,
    this.revenue,
    this.todayRevenue,
    this.qrCode,
    this.scanCount = 0,
    this.interactionCount = 0,
    this.lastActive,
  });

  /// Create ScanPoint from Firestore document
  factory ScanPoint.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw ArgumentError('Document data is null for scan point: ${doc.id}');
    }

    return ScanPoint(
      id: doc.id,
      scanPointId: data['scan_point_id'] as String? ?? doc.id,
      name: data['name'] as String? ?? 'Unnamed Scan Point',
      type: data['type'] as String? ?? 'unknown',
      location: data['location'] as String?,
      description: data['description'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      ownerUid: data['owner_uid'] as String?,
      active: data['active'] as bool? ?? true,
      revenue: (data['revenue'] as num?)?.toDouble(),
      todayRevenue: (data['today_revenue'] as num?)?.toDouble(),
      qrCode: data['qr_code'] as String?,
      scanCount: (data['scan_count'] as num?)?.toInt() ?? 0,
      interactionCount: (data['interaction_count'] as num?)?.toInt() ?? 0,
      lastActive: data['last_active'] != null
          ? (data['last_active'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert ScanPoint to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'scan_point_id': scanPointId,
      'name': name,
      'type': type,
      'location': location,
      'description': description,
      'tags': tags,
      'owner_uid': ownerUid,
      'active': active,
      'revenue': revenue,
      'today_revenue': todayRevenue,
      'qr_code': qrCode,
      'scan_count': scanCount,
      'interaction_count': interactionCount,
      'last_active': lastActive != null
          ? Timestamp.fromDate(lastActive!)
          : null,
    };
  }

  /// Check if this is a commerce scan point
  bool get isCommerce => type == 'commerce';

  /// Check if this is a library scan point
  bool get isLibrary => type == 'library';

  /// Check if this is an access scan point
  bool get isAccess => type == 'access';

  /// Check if this is a booking scan point
  bool get isBooking => type == 'booking';

  @override
  String toString() {
    return 'ScanPoint(id: $id, scanPointId: $scanPointId, name: $name, type: $type, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanPoint &&
        other.id == id &&
        other.scanPointId == scanPointId;
  }

  @override
  int get hashCode => Object.hash(id, scanPointId);
}

/// 🏪 ScanPoint Service
/// Manages scan point data and provides current scan point context for logged-in users
class ScanPointService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current scan point for the logged-in user
  ///
  /// Logic:
  /// 1. Check if user is logged in
  /// 2. Look up user document for scan_point_id field
  /// 3. If found, get scan point by ID
  /// 4. If not found, try to find scan point where owner_uid matches current user
  /// 5. Return null if no scan point is associated with this user
  static Future<ScanPoint?> getCurrentScanPointForLoggedInUser() async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        print('🚫 [ScanPointService] No user logged in');
        return null;
      }

      final uid = user.uid;
      print('👤 [ScanPointService] Getting scan point for user: $uid');

      // Step 1: Check user document for scan_point_id field
      final userDoc = await _db.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final scanPointId = userData['scan_point_id'] as String?;

        if (scanPointId != null && scanPointId.isNotEmpty) {
          print(
            '📍 [ScanPointService] Found scan_point_id in user doc: $scanPointId',
          );

          // Get scan point by ID
          final scanPointDoc = await _db
              .collection('scan_points')
              .doc(scanPointId)
              .get();

          if (scanPointDoc.exists && scanPointDoc.data() != null) {
            final scanPoint = ScanPoint.fromDocument(scanPointDoc);
            print('✅ [ScanPointService] Found scan point: ${scanPoint.name}');
            return scanPoint;
          } else {
            print(
              '⚠️ [ScanPointService] Scan point document not found: $scanPointId',
            );
          }
        } else {
          print('🔍 [ScanPointService] No scan_point_id in user document');
        }
      } else {
        print('⚠️ [ScanPointService] User document not found: $uid');
      }

      // Step 2: Try to find scan point by owner_uid
      print('🔍 [ScanPointService] Searching by owner_uid: $uid');
      final ownerQuery = await _db
          .collection('scan_points')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (ownerQuery.docs.isNotEmpty) {
        final scanPoint = ScanPoint.fromDocument(ownerQuery.docs.first);
        print(
          '✅ [ScanPointService] Found scan point by owner_uid: ${scanPoint.name}',
        );
        return scanPoint;
      }

      // No scan point found
      print('❌ [ScanPointService] No scan point found for user: $uid');
      return null;
    } catch (e) {
      print('❌ [ScanPointService] Error getting current scan point: $e');
      return null;
    }
  }

  /// Watch the current scan point for real-time updates
  ///
  /// Returns a stream that emits the current scan point whenever it changes
  /// Returns Stream.value(null) if no scan point is found or user is not logged in
  static Stream<ScanPoint?> watchCurrentScanPoint() {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        print('🚫 [ScanPointService] No user logged in for watch stream');
        return Stream.value(null);
      }

      final uid = user.uid;
      print('👁️ [ScanPointService] Setting up watch stream for user: $uid');

      // Return a stream that first finds the scan point, then watches it
      return _findAndWatchScanPoint(uid);
    } catch (e) {
      print('❌ [ScanPointService] Error setting up watch stream: $e');
      return Stream.value(null);
    }
  }

  /// Internal method to find and watch scan point
  static Stream<ScanPoint?> _findAndWatchScanPoint(String uid) async* {
    try {
      // First, find the scan point ID
      String? scanPointDocId;

      // Check user document for scan_point_id
      final userDoc = await _db.collection('users').doc(uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final scanPointId = userDoc.data()!['scan_point_id'] as String?;
        if (scanPointId != null && scanPointId.isNotEmpty) {
          scanPointDocId = scanPointId;
          print(
            '📍 [ScanPointService] Watching scan point from user doc: $scanPointId',
          );
        }
      }

      // If not found in user doc, try owner_uid query
      if (scanPointDocId == null) {
        final ownerQuery = await _db
            .collection('scan_points')
            .where('owner_uid', isEqualTo: uid)
            .limit(1)
            .get();

        if (ownerQuery.docs.isNotEmpty) {
          scanPointDocId = ownerQuery.docs.first.id;
          print(
            '📍 [ScanPointService] Watching scan point by owner_uid: $scanPointDocId',
          );
        }
      }

      if (scanPointDocId == null) {
        print(
          '❌ [ScanPointService] No scan point found to watch for user: $uid',
        );
        yield null;
        return;
      }

      // Watch the scan point document
      yield* _db.collection('scan_points').doc(scanPointDocId).snapshots().map((
        snapshot,
      ) {
        try {
          if (snapshot.exists && snapshot.data() != null) {
            final scanPoint = ScanPoint.fromDocument(snapshot);
            print(
              '🔄 [ScanPointService] Scan point updated: ${scanPoint.name}',
            );
            return scanPoint;
          } else {
            print(
              '⚠️ [ScanPointService] Scan point document no longer exists: $scanPointDocId',
            );
            return null;
          }
        } catch (e) {
          print('❌ [ScanPointService] Error parsing scan point update: $e');
          return null;
        }
      });
    } catch (e) {
      print('❌ [ScanPointService] Error in watch stream: $e');
      yield null;
    }
  }

  /// Get scan point by ID
  static Future<ScanPoint?> getScanPointById(String scanPointId) async {
    try {
      print('🔍 [ScanPointService] Getting scan point by ID: $scanPointId');

      final doc = await _db.collection('scan_points').doc(scanPointId).get();

      if (doc.exists && doc.data() != null) {
        final scanPoint = ScanPoint.fromDocument(doc);
        print('✅ [ScanPointService] Found scan point: ${scanPoint.name}');
        return scanPoint;
      }

      print('❌ [ScanPointService] Scan point not found: $scanPointId');
      return null;
    } catch (e) {
      print('❌ [ScanPointService] Error getting scan point by ID: $e');
      return null;
    }
  }

  /// Get all scan points for a specific owner
  static Future<List<ScanPoint>> getScanPointsForOwner(String ownerUid) async {
    try {
      print('🔍 [ScanPointService] Getting scan points for owner: $ownerUid');

      final query = await _db
          .collection('scan_points')
          .where('owner_uid', isEqualTo: ownerUid)
          .get();

      final scanPoints = query.docs
          .map((doc) => ScanPoint.fromDocument(doc))
          .toList();

      print(
        '✅ [ScanPointService] Found ${scanPoints.length} scan points for owner',
      );
      return scanPoints;
    } catch (e) {
      print('❌ [ScanPointService] Error getting scan points for owner: $e');
      return [];
    }
  }

  /// Update scan point data
  static Future<bool> updateScanPoint(
    String scanPointId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print('🔄 [ScanPointService] Updating scan point: $scanPointId');

      await _db.collection('scan_points').doc(scanPointId).update(updates);

      print('✅ [ScanPointService] Scan point updated successfully');
      return true;
    } catch (e) {
      print('❌ [ScanPointService] Error updating scan point: $e');
      return false;
    }
  }

  /// Check if current user has access to a specific scan point
  static Future<bool> hasAccessToScanPoint(String scanPointId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final scanPoint = await getScanPointById(scanPointId);
      if (scanPoint == null) return false;

      // Check if user is the owner
      if (scanPoint.ownerUid == user.uid) return true;

      // Check if user document has this scan_point_id
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userScanPointId = userDoc.data()!['scan_point_id'] as String?;
        return userScanPointId == scanPointId;
      }

      return false;
    } catch (e) {
      print('❌ [ScanPointService] Error checking scan point access: $e');
      return false;
    }
  }
  /// Update scan point heartbeat (Online Status)
  /// 
  /// Should be called periodically (e.g., every 5 minutes) by the active scan point device.
  static Future<void> updateHeartbeat(String scanPointId) async {
    try {
      await _db.collection('scan_points').doc(scanPointId).update({
        'last_active': FieldValue.serverTimestamp(),
      });
      print('💓 [ScanPointService] Heartbeat sent for $scanPointId');
    } catch (e) {
      print('❌ [ScanPointService] Error sending heartbeat: $e');
    }
  }
}
