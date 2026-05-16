import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch user role and data from 'users' or 'admins' collection.
  /// Returns a [UserModel] or null if not found.
  Future<UserModel?> getUserData(String email, {String? uid}) async {
    try {
      // 1. Try Direct UID Lookup (Fastest & Most Reliable)
      if (uid != null) {
        // Check 'users' collection by UID
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data()!, uid, 'users');
        }

        // Check 'admins' collection by UID
        final adminDoc = await _firestore.collection('admins').doc(uid).get();
        if (adminDoc.exists) {
          // Admin roles might be implicit in the collection, but we ensure it's set
          final data = adminDoc.data()!;
          if (!data.containsKey('role')) {
             data['role'] = 'admin';
          }
          return UserModel.fromMap(data, uid, 'admins');
        }
      }

      // 2. Fallback: Check 'users' collection by Email (Slower)
      final userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final doc = userSnapshot.docs.first;
        return UserModel.fromMap(doc.data(), doc.id, 'users');
      }

      // 3. Fallback: Check 'admins' collection by Email
      final adminSnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        final doc = adminSnapshot.docs.first;
        final data = doc.data();
        if (!data.containsKey('role')) {
             data['role'] = 'admin';
        }
        return UserModel.fromMap(data, doc.id, 'admins');
      }

      return null;
    } catch (e) {
      debugPrint("❌ Error fetching user data: $e");
      rethrow;
    }
  }

  /// Fetch scan point details for a merchant.
  Future<Map<String, dynamic>?> getScanPoint(String scanPointId) async {
    try {
      final doc = await _firestore.collection('scan_points').doc(scanPointId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error fetching scan point: $e");
      rethrow;
    }
  }

  /// Check if a scan point ID is blacklisted.
  bool isScanPointBlacklisted(String scanPointId) {
    const blacklistedScanPoints = [
      'sp03',
      'sp04',
      'sp05',
      'sp003',
      'sp004',
      'sp005',
    ];
    return blacklistedScanPoints.contains(scanPointId.toLowerCase());
  }
}
