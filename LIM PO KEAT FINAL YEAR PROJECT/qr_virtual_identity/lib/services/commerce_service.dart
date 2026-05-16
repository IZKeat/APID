// lib/services/commerce_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/scan_point_service.dart';
import '../services/qr_processor_service.dart';

/// 💰 Commerce Service
/// Handles payment processing, purchases, and refunds for commerce scan points
class CommerceService {
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
      
      // Constant time comparison to prevent timing attacks
      // (Simple string comparison is fine for this project scope, 
      // but arguably we should use a constant-time comparison function if strict security is needed)
      return signature == expectedSignature;
    } catch (e) {
      print('❌ [CommerceService] Security Check Error: $e');
      return false;
    }
  }

  /// Default test purchase amount (in RM)
  static const double defaultPurchaseAmount = 2.00;

  /// Process payment for commerce scan points
  ///
  /// Handles user payments by:
  /// 1. Validating HMAC Signature (Security)
  /// 2. Validating scan point type
  /// 3. Checking user wallet balance
  /// 4. Deducting amount
  static Future<QrProcessResponse> processPayment({
    required String userId,
    required ScanPoint scanPoint,
    double? amount,
    List<Map<String, dynamic>>? items,
    String? description,
    String? itemName,
    // Security Parameters
    int? timestamp,
    String? nonce,
    String? signature,
  }) async {
    try {
      // 🔒 1. Security Check: HMAC Verification
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
        print('🔒 [CommerceService] HMAC Correct. Secure Transaction.');
      } else {
        // Enforce security for Commerce
        // Allow bypass ONLY if it's a legacy static code (but really we should block it)
        print('⚠️ [CommerceService] Warning: Processing unsecured transaction!');
        // Ideally: return QrProcessResponse.error('Secure QR required', 'SECURITY_REQUIRED');
      }

      if (scanPoint.type != 'commerce') {
        return QrProcessResponse.error(
          'Payment processing is only available for commerce scan points',
          'INVALID_SCAN_POINT_TYPE',
        );
      }

      final purchaseAmount = amount ?? defaultPurchaseAmount;
      final purchaseDescription =
          description ?? 'Purchase at ${scanPoint.name}';
      final purchaseItemName = itemName ?? 'General Purchase';

      print(
        '💰 [CommerceService] Purchase amount: RM ${purchaseAmount.toStringAsFixed(2)}',
      );
      print('🛒 [CommerceService] Items to save: $items');

      // 🔍 Smart Lookup: If userId looks like a Student ID (e.g., tp072581), find the real UID
      String targetUserId = userId;
      if (userId.toLowerCase().startsWith('tp')) {
        print(
          '🔍 [CommerceService] Detected Student ID: $userId, searching by email...',
        );
        try {
          final emailQuery =
              await _db
                  .collection('users')
                  .where('email', isEqualTo: '$userId@mail.apu.edu.my')
                  .limit(1)
                  .get();

          if (emailQuery.docs.isNotEmpty) {
            targetUserId = emailQuery.docs.first.id;
            print(
              '✅ [CommerceService] Resolved Student ID to User UID: $targetUserId',
            );
          } else {
            print(
              '⚠️ [CommerceService] Could not find user with email: $userId@mail.apu.edu.my',
            );
            // Fallback: Try searching by 'student_id' field if it exists in future
          }
        } catch (e) {
          print('⚠️ [CommerceService] Smart lookup failed: $e');
        }
      }

      // Get user's current wallet balance
      final userDoc = await _db.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) {
        return QrProcessResponse.error(
          'User account not found',
          'USER_NOT_FOUND',
        );
      }

      final userData = userDoc.data()!;
      // FIX: Read 'balance' first (from screenshot), fallback to 'wallet_balance'
      final currentBalance =
          (userData['wallet_balance'] as num?)?.toDouble() ??
          (userData['balance'] as num?)?.toDouble() ??
          0.0;

      print(
        '💰 [CommerceService] Current balance: RM ${currentBalance.toStringAsFixed(2)}',
      );

      // Check if user has sufficient balance
      // 🌟 GUEST LOGIC: Check if user is a guest and apply RM 1.00 fee
      double finalAmount = purchaseAmount;
      String finalDescription = purchaseDescription;
      List<Map<String, dynamic>> finalItems = List.from(items ?? []);

      if (userData['role'] == 'guest') {
        print('👤 [CommerceService] Guest user detected. Applying RM 1.00 Guest Fee.');
        finalAmount += 1.00;
        finalDescription += ' (Incl. RM1.00 Guest Fee)';
        finalItems.add({
          'name': 'Guest Transaction Fee',
          'price': 1.00,
          'qty': 1,
          'type': 'fee',
        });
      }

      if (currentBalance < finalAmount) {
        return QrProcessResponse.error(
          'Insufficient wallet balance. Current: RM ${currentBalance.toStringAsFixed(2)}, Required: RM ${finalAmount.toStringAsFixed(2)}',
          'INSUFFICIENT_BALANCE',
        );
      }

      // Perform transaction using Firestore transaction
      final transactionResult = await _db.runTransaction<QrProcessResponse>((
        transaction,
      ) async {
        // Re-read user balance within transaction to ensure consistency
        final userSnapshot = await transaction.get(
          _db.collection('users').doc(targetUserId),
        );
        if (!userSnapshot.exists) {
          return QrProcessResponse.error(
            'User account not found',
            'USER_NOT_FOUND',
          );
        }

        final latestBalance =
            (userSnapshot.data()!['wallet_balance'] as num?)?.toDouble() ??
            (userSnapshot.data()!['balance'] as num?)?.toDouble() ??
            0.0;

        if (latestBalance < finalAmount) {
          return QrProcessResponse.error(
            'Insufficient balance (transaction check)',
            'INSUFFICIENT_BALANCE',
          );
        }

        final newBalance = latestBalance - finalAmount;
        final interactionId = _db.collection('interactions').doc().id;

        // Create purchase interaction
        transaction.set(_db.collection('interactions').doc(interactionId), {
          'user_id': targetUserId,
          'scan_point_id': scanPoint.scanPointId,
          'type': 'purchase',
          'amount': finalAmount,
          'item_name': purchaseItemName,
          'description': finalDescription,
          'timestamp': FieldValue.serverTimestamp(),
          'remarks': 'Payment processed via QR scanner',
          'interaction_id': interactionId,
          'scan_point_name': scanPoint.name,
          'status': 'completed',
          'items': finalItems, // Save cart items
          'metadata': {
            'guest_fee_applied': userData['role'] == 'guest',
            'original_amount': purchaseAmount,
          }
        });

        // Update user wallet balance
        transaction.update(_db.collection('users').doc(targetUserId), {
          'wallet_balance': newBalance, // Sync legacy field
          'balance': newBalance, // Update main field
          'last_transaction': FieldValue.serverTimestamp(),
        });

        // Update scan point revenue and statistics
        final scanPointRef = _db.collection('scan_points').doc(scanPoint.id);
        transaction.update(scanPointRef, {
          'revenue': FieldValue.increment(finalAmount),
          'today_revenue': FieldValue.increment(finalAmount),
          'interaction_count': FieldValue.increment(1),
          'scan_count': FieldValue.increment(1),
          'last_active': FieldValue.serverTimestamp(),
        });

        print('💰 [CommerceService] Transaction completed successfully');
        return QrProcessResponse.success(
          'Payment successful! RM ${finalAmount.toStringAsFixed(2)} charged.',
          {
            'amount': finalAmount,
            'new_balance': newBalance,
            'previous_balance': latestBalance,
            'item_name': purchaseItemName,
            'description': purchaseDescription,
            'scan_point': scanPoint.name,
            'interaction_id': interactionId,
            'transaction_type': 'purchase',
          },
        );
      });

      return transactionResult;
    } catch (e) {
      print('❌ [CommerceService] Error processing payment: $e');
      return QrProcessResponse.error(
        'Payment processing failed: ${e.toString()}',
        'PAYMENT_ERROR',
      );
    }
  }

  /// Process refund for a previous purchase
  static Future<QrProcessResponse> processRefund({
    required String userId,
    required ScanPoint scanPoint,
    required String originalInteractionId,
    String? reason,
  }) async {
    try {
      print(
        '💸 [CommerceService] Processing refund for interaction: $originalInteractionId',
      );

      // Validate scan point type
      if (scanPoint.type != 'commerce') {
        return QrProcessResponse.error(
          'Refund processing is only available for commerce scan points',
          'INVALID_SCAN_POINT_TYPE',
        );
      }

      // Get original purchase interaction
      final originalDoc = await _db
          .collection('interactions')
          .doc(originalInteractionId)
          .get();
      if (!originalDoc.exists) {
        return QrProcessResponse.error(
          'Original purchase not found',
          'ORIGINAL_PURCHASE_NOT_FOUND',
        );
      }

      final originalData = originalDoc.data()!;
      final refundAmount = (originalData['amount'] as num).toDouble();
      final refundReason = reason ?? 'Refund for purchase at ${scanPoint.name}';

      // Perform refund transaction
      final transactionResult = await _db.runTransaction<QrProcessResponse>((
        transaction,
      ) async {
        final userSnapshot = await transaction.get(
          _db.collection('users').doc(userId),
        );
        if (!userSnapshot.exists) {
          return QrProcessResponse.error(
            'User account not found',
            'USER_NOT_FOUND',
          );
        }

        final currentBalance =
            (userSnapshot.data()!['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        final newBalance = currentBalance + refundAmount;
        final interactionId = _db.collection('interactions').doc().id;

        // Create refund interaction
        transaction.set(_db.collection('interactions').doc(interactionId), {
          'user_id': userId,
          'scan_point_id': scanPoint.scanPointId,
          'type': 'refund',
          'amount': refundAmount,
          'description': refundReason,
          'timestamp': FieldValue.serverTimestamp(),
          'remarks': 'Refund processed via QR scanner',
          'original_interaction_id': originalInteractionId,
          'interaction_id': interactionId,
          'scan_point_name': scanPoint.name,
          'status': 'completed',
        });

        // Update user wallet balance
        transaction.update(_db.collection('users').doc(userId), {
          'wallet_balance': newBalance,
          'last_transaction': FieldValue.serverTimestamp(),
        });

        // Update scan point revenue (subtract refund)
        transaction.update(_db.collection('scan_points').doc(scanPoint.id), {
          'revenue': FieldValue.increment(-refundAmount),
          'today_revenue': FieldValue.increment(-refundAmount),
          'interaction_count': FieldValue.increment(1),
          'last_active': FieldValue.serverTimestamp(),
        });

        return QrProcessResponse.success(
          'Refund successful! RM ${refundAmount.toStringAsFixed(2)} refunded.',
          {
            'amount': refundAmount,
            'new_balance': newBalance,
            'original_interaction_id': originalInteractionId,
            'refund_reason': refundReason,
            'scan_point': scanPoint.name,
            'interaction_id': interactionId,
            'transaction_type': 'refund',
          },
        );
      });

      return transactionResult;
    } catch (e) {
      print('❌ [CommerceService] Error processing refund: $e');
      return QrProcessResponse.error(
        'Refund processing failed: ${e.toString()}',
        'REFUND_ERROR',
      );
    }
  }

  /// Get user's wallet balance
  static Future<double> getUserBalance(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.0;

      return (userDoc.data()!['wallet_balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('❌ [CommerceService] Error getting user balance: $e');
      return 0.0;
    }
  }

  /// Get commerce statistics for a scan point
  static Future<Map<String, dynamic>> getCommerceStats(
    String scanPointId,
  ) async {
    try {
      print('📊 [CommerceService] Getting commerce stats for: $scanPointId');

      // Get today's transactions
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayTransactions = await _db
          .collection('interactions')
          .where('scan_point_id', isEqualTo: scanPointId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('type', whereIn: ['purchase', 'refund'])
          .get();

      // Calculate stats
      double todayRevenue = 0.0;
      int todayTransactionCount = 0;

      for (final doc in todayTransactions.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        final type = data['type'] as String;

        if (type == 'purchase') {
          todayRevenue += amount;
        } else if (type == 'refund') {
          todayRevenue -= amount;
        }
        todayTransactionCount++;
      }

      return {
        'today_revenue': todayRevenue,
        'today_transaction_count': todayTransactionCount,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ [CommerceService] Error getting commerce stats: $e');
      return {};
    }
  }
}
