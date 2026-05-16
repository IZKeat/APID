// lib/services/wallet_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's wallet balance
  static Future<double> getCurrentBalance() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return (userDoc.data()!['wallet_balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('Error getting wallet balance: $e');
      return 0.0;
    }
  }

  // Stream of wallet balance updates
  static Stream<double> getBalanceStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0.0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return (snapshot.data()!['wallet_balance'] as num?)?.toDouble() ?? 0.0;
      }
      return 0.0;
    });
  }

  // Top up wallet with atomic batch update
  ///
  /// [amount] - The amount to add to the wallet (must be positive).
  /// [method] - The payment method used (e.g., 'Credit Card', 'E-Wallet').
  ///
  /// Returns `true` if the top-up was successful, `false` otherwise.
  /// Throws [FirebaseException] if the database operation fails.
  static Future<bool> topUpWallet(double amount, String method) async {
    // 1. Input Validation (Business Logic Limits)
    if (amount <= 0) {
      print('Error: Top-up amount must be positive.');
      return false;
    }
    if (amount < 5.0) {
      print('Error: Top-up amount is below minimum limit (RM 5.00).');
      return false;
    }
    if (amount > 1000.0) {
      print('Error: Top-up amount exceeds maximum limit (RM 1000.00).');
      return false;
    }

    final user = _auth.currentUser;
    if (user == null) {
      print('Error: User not authenticated.');
      return false;
    }

    try {
      // 2. Prepare Batch Operation for Atomicity
      // We use a batch to ensure both the transaction record and the balance update
      // happen together. If one fails, both fail.
      final batch = _firestore.batch();
      
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final transactionRef = _firestore.collection('interactions').doc();

      // 3. Create Transaction Record
      // This log is crucial for audit trails and user history.
      final transactionData = {
        'user_id': user.uid,
        'type': 'topup',
        'amount': amount,
        'method': method,
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Wallet top-up via $method',
        'status': 'completed',
        'reference_id': transactionRef.id, // Link back to document ID
        'platform': 'mobile', // Track source
      };

      batch.set(transactionRef, transactionData);

      // 4. Atomic Balance Update
      // Using FieldValue.increment is critical to prevent race conditions.
      // If two top-ups happen simultaneously, increment ensures both are counted,
      // whereas reading -> adding -> writing could overwrite one of them.
      batch.update(userDocRef, {
        'wallet_balance': FieldValue.increment(amount),
        'last_transaction_time': FieldValue.serverTimestamp(),
      });

      // 5. Commit Batch
      await batch.commit();
      
      print('Success: Wallet topped up by RM$amount via $method');
      return true;

    } catch (e) {
      // 6. Error Handling
      print('Critical Error in topUpWallet: $e');
      // In a real app, you might want to log this to Crashlytics
      return false;
    }
  }

  // Transfer money to another user
  static Future<bool> transferMoney(String recipientId, double amount, String note) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Check current balance
      final currentBalance = await getCurrentBalance();
      if (currentBalance < amount) {
        return false; // Insufficient funds
      }

      final batch = _firestore.batch();
      final senderRef = _firestore.collection('users').doc(user.uid);
      final recipientRef = _firestore.collection('users').doc(recipientId);

      // Create transfer record for sender
      final senderTransactionRef = _firestore.collection('interactions').doc();
      batch.set(senderTransactionRef, {
        'user_id': user.uid,
        'type': 'transfer',
        'amount': -amount,
        'recipient_id': recipientId,
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Transfer to user - $note',
        'status': 'completed',
      });

      // Create transfer record for recipient
      final recipientTransactionRef = _firestore.collection('interactions').doc();
      batch.set(recipientTransactionRef, {
        'user_id': recipientId,
        'type': 'transfer',
        'amount': amount,
        'sender_id': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Received transfer - $note',
        'status': 'completed',
      });

      // Update balances
      batch.update(senderRef, {
        'wallet_balance': FieldValue.increment(-amount),
      });
      batch.update(recipientRef, {
        'wallet_balance': FieldValue.increment(amount),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error transferring money: $e');
      return false;
    }
  }

  // Get transaction history with filtering
  static Stream<QuerySnapshot> getTransactionHistory({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    Query query = _firestore
        .collection('interactions')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (type != null && type != 'all') {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots();
  }

  // Get spending statistics for charts
  static Future<Map<String, dynamic>> getSpendingStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _firestore
          .collection('interactions')
          .where('user_id', isEqualTo: user.uid)
          .where('type', isEqualTo: 'purchase')
          .where('timestamp', isGreaterThan: startOfMonth)
          .get();

      double totalSpent = 0;
      Map<String, double> categorySpending = {};
      Map<String, double> dailySpending = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final category = data['category'] as String? ?? 'Other';
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

        totalSpent += amount.abs();
        
        // Category breakdown
        categorySpending[category] = (categorySpending[category] ?? 0) + amount.abs();
        
        // Daily breakdown
        final day = '${timestamp.day}/${timestamp.month}';
        dailySpending[day] = (dailySpending[day] ?? 0) + amount.abs();
      }

      return {
        'totalSpent': totalSpent,
        'categorySpending': categorySpending,
        'dailySpending': dailySpending,
      };
    } catch (e) {
      print('Error getting spending stats: $e');
      return {};
    }
  }
}