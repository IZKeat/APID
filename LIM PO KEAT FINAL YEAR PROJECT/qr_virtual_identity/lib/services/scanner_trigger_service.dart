import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScannerTriggerService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send trigger to mobile scanner
  static Future<void> sendTrigger(
    String merchantUid,
    double total,
    List<Map<String, dynamic>> cartItems,
  ) async {
    await _db.collection('scanner_triggers').doc(merchantUid).set({
      'trigger': true,
      'amount': total,
      'cart': cartItems,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Listen for scanner status updates
  static Stream<DocumentSnapshot> listenForScannerStatus(String merchantUid) {
    return _db.collection('scanner_status').doc(merchantUid).snapshots();
  }

  /// Clear scanner trigger
  static Future<void> clearTrigger(String merchantUid) async {
    await _db.collection('scanner_triggers').doc(merchantUid).update({
      'trigger': false,
    });
  }

  /// Write scanner result (for mobile use)
  static Future<void> writeScanResult(
    String merchantUid,
    String status, {
    String? studentUid,
    String? errorMessage,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (studentUid != null) {
      data['student_uid'] = studentUid;
    }
    if (errorMessage != null) {
      data['message'] = errorMessage;
    }

    await _db.collection('scanner_status').doc(merchantUid).set(data);
  }

  /// Get current user UID
  static String? getCurrentMerchantUid() {
    return _auth.currentUser?.uid;
  }

  /// Process payment transaction
  static Future<Map<String, dynamic>> processPayment(
    String studentUid,
    double amount,
    Map<String, dynamic> cartItems,
    String scanPointId,
  ) async {
    try {
      // Get student data
      final studentDoc = await _db.collection('users').doc(studentUid).get();
      if (!studentDoc.exists) {
        return {'success': false, 'error': 'Student not found'};
      }

      final studentData = studentDoc.data()!;
      final balance = (studentData['balance'] ?? 0).toDouble();

      if (balance < amount) {
        return {'success': false, 'error': 'Insufficient balance'};
      }

      // Deduct balance
      await _db.collection('users').doc(studentUid).update({
        'balance': balance - amount,
      });

      // Create interaction record
      await _db.collection('interactions').add({
        'user_id': studentUid,
        'user_email': studentData['email'],
        'scan_point_id': scanPointId,
        'scan_point_name': 'Smokey Café',
        'type': 'purchase',
        'status': 'success',
        'amount': amount,
        'items': cartItems,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'studentEmail': studentData['email'],
        'newBalance': balance - amount,
      };
    } catch (e) {
      return {'success': false, 'error': 'Payment failed: $e'};
    }
  }

  /// Listen for triggers (for mobile use)
  static Stream<DocumentSnapshot> listenForTriggers(String merchantUid) {
    return _db.collection('scanner_triggers').doc(merchantUid).snapshots();
  }
}
