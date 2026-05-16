// lib/pages_admin/utils/admin_guard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apid/pages_common/login_page.dart';

/// 🛡️ Admin Guard Utility
/// Protects admin routes and verifies admin authorization
class AdminGuard {
  /// Check if current user is an authenticated admin
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      return adminDoc.docs.isNotEmpty;
    } catch (e) {
      print('❌ Admin verification failed: $e');
      return false;
    }
  }

  /// Alias for isAdmin() - checks if user has admin access
  static Future<bool> checkAdminAccess() async {
    return await isAdmin();
  }

  /// Get admin data for current user
  static Future<Map<String, dynamic>?> getAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      return adminDoc.data();
    } catch (e) {
      print('❌ Failed to fetch admin data: $e');
      return null;
    }
  }

  /// Logout admin and navigate to login
  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print('❌ Logout failed: $e');
    }
  }

  /// Verify admin access and redirect to login if unauthorized
  static Future<bool> verifyAccess(BuildContext context) async {
    final isAuthorized = await isAdmin();

    if (!isAuthorized) {
      if (!context.mounted) return false;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Unauthorized access. Please login as admin.'),
          backgroundColor: Colors.red,
        ),
      );

      return false;
    }

    return true;
  }

  /// Stream of admin authentication state
  static Stream<User?> get authStateChanges {
    return FirebaseAuth.instance.authStateChanges();
  }
}
