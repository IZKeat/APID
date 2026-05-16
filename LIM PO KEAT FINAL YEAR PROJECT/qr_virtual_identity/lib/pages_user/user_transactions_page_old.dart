// lib/pages_user/user_transactions_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_card.dart';
import 'transaction_history_page.dart';

/// 💰 Smart Transactions Page
/// E-wallet style transaction center with tiered layout
class UserTransactionsPage extends StatefulWidget {
  const UserTransactionsPage({super.key});

  @override
  State<UserTransactionsPage> createState() => _UserTransactionsPageState();
}

class _UserTransactionsPageState extends State<UserTransactionsPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Data
  List<Map<String, dynamic>> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              // Header with title
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.1),
                        AppTheme.backgroundLight,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your wallet and view history',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // (A) Quick Action Section
              SliverToBoxAdapter(child: _buildQuickActions()),

              // (B) Recent Transactions Section
              SliverToBoxAdapter(child: _buildRecentTransactions()),
            ],
          ),
        ),
      ),
    );
  }

  // ========== (A) Quick Action Section ==========
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.add_circle_outline,
              label: 'Top Up',
              onTap: _showTopUpModal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: Icons.send_outlined,
              label: 'Transfer',
              onTap: _showTransferModal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== (B) Recent Transactions Section ==========
  Widget _buildRecentTransactions() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _navigateToFullTransactionHistory,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildRecentTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList() {
    if (_allTransactions.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined, size: 32, color: AppTheme.textHint),
            const SizedBox(height: 8),
            Text(
              'No transactions yet',
              style: TextStyle(color: AppTheme.textHint, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final recentTransactions = _allTransactions.take(5).toList();
    return Column(
      children: recentTransactions.map((transaction) {
        return TransactionCard(
          transaction: transaction,
          onTap: () => _showTransactionDetails(transaction),
        );
      }).toList(),
    );
  }

  // ========== Data Loading ==========
  Future<void> _loadTransactions() async {
    final user = _auth.currentUser;
    if (user?.email == null) return;

    try {
      final query = _db
          .collection('interactions')
          .where('user_email', isEqualTo: user!.email)
          .where('status', isEqualTo: 'success')
          .orderBy('timestamp', descending: true)
          .limit(20); // Only load 20 most recent

      final snapshot = await query.get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _allTransactions = transactions;
      });
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  // ========== Event Handlers ==========
  Future<void> _refreshData() async {
    await _loadTransactions();
  }

  void _navigateToFullTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionHistoryPage()),
    );
  }

  void _showTopUpModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: const Text('Top up functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTransferModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transfer Money'),
        content: const Text('Transfer functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Transaction Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow(
                        'Transaction ID',
                        transaction['interaction_id'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Type',
                        (transaction['type'] as String? ?? '').toUpperCase(),
                      ),
                      _buildDetailRow(
                        'Status',
                        (transaction['status'] as String? ?? '').toUpperCase(),
                      ),
                      _buildDetailRow(
                        'Location',
                        transaction['scan_point_name'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Description',
                        transaction['remarks'] ?? 'N/A',
                      ),
                      if (transaction['amount'] != null)
                        _buildDetailRow(
                          'Amount',
                          'RM ${(transaction['amount'] as num).toStringAsFixed(2)}',
                        ),
                      if (transaction['payment_method'] != null)
                        _buildDetailRow(
                          'Payment Method',
                          transaction['payment_method'],
                        ),
                      if (transaction['timestamp'] != null)
                        _buildDetailRow(
                          'Date & Time',
                          _formatTimestamp(transaction['timestamp']),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== Helper Methods ==========
  String _formatTimestamp(dynamic timestamp) {
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'N/A';
    }

    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }
}
