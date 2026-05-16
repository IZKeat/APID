// lib/pages_user/user_transactions_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_card.dart';
import '../components/transactions/wallet_balance_card.dart';
import '../components/transactions/wallet_action_button.dart';
import '../components/transactions/topup_modal.dart';
import '../components/transactions/transfer_modal.dart';
import 'transaction_history_page.dart';

/// Smart Wallet Transactions Page
/// Modern e-wallet interface with top-up and transfer functionality
class UserTransactionsPage extends StatefulWidget {
  const UserTransactionsPage({super.key});

  @override
  State<UserTransactionsPage> createState() => _UserTransactionsPageState();
}

class _UserTransactionsPageState extends State<UserTransactionsPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Data
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadRecentTransactions();
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to access your wallet',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshData,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(child: _buildHeader()),

              // Wallet Balance Card
              SliverToBoxAdapter(child: _buildWalletBalance()),

              // Action Buttons
              SliverToBoxAdapter(child: _buildActionButtons()),

              // Recent Transactions Header
              SliverToBoxAdapter(child: _buildRecentTransactionsHeader()),

              // Recent Transactions List
              _buildRecentTransactionsList(),
            ],
          ),
        ),
      ),
    );
  }

  // ========== UI Components ==========

  Widget _buildHeader() {
    return Container(
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
            'Smart Wallet',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your funds with ease',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalance() {
    return WalletBalanceCard(onRefresh: _refreshData);
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: WalletActionButton(
              icon: Icons.account_balance_wallet,
              label: 'Top Up',
              onTap: _showTopUpModal,
              backgroundColor: AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: WalletActionButton(
              icon: Icons.swap_horiz,
              label: 'Transfer',
              onTap: _showTransferModal,
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryPage(),
                ),
              );
            },
            icon: Icon(
              Icons.arrow_forward,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            label: Text(
              'View All',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentTransactions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppTheme.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions yet',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Start by topping up your wallet',
                style: TextStyle(color: AppTheme.textHint, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final transaction = _recentTransactions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TransactionCard(
              transaction: transaction,
              onTap: () => _showTransactionDetails(transaction),
            ),
          );
        }, childCount: _recentTransactions.length),
      ),
    );
  }

  // ========== Modal Functions ==========

  void _showTopUpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, // Decrease initial height
        maxChildSize: 0.9, // Decrease max height
        minChildSize: 0.5,
        builder: (context, scrollController) =>
            TopupModal(onSuccess: _onTransactionSuccess),
      ),
    );
  }

  void _showTransferModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, // Decrease initial height
        maxChildSize: 0.9, // Decrease max height
        minChildSize: 0.5,
        builder: (context, scrollController) =>
            TransferModal(onSuccess: _onTransactionSuccess),
      ),
    );
  }

  void _onTransactionSuccess() {
    // Refresh all data after successful transaction
    _refreshIndicatorKey.currentState?.show();
  }

  // ========== Transaction Details Modal ==========

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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTransactionIcon(transaction['type'] ?? ''),
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTransactionTitle(transaction['type'] ?? ''),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            _formatTransactionStatus(
                              transaction['status'] ?? '',
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(
                                transaction['status'] ?? '',
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (transaction['interaction_id'] != null)
                        _buildDetailRow(
                          'Transaction ID',
                          transaction['interaction_id'],
                        ),
                      if (transaction['amount'] != null)
                        _buildDetailRow(
                          'Amount',
                          'RM ${(transaction['amount'] as num).toStringAsFixed(2)}',
                        ),
                      if (transaction['type']?.toString().contains(
                            'transfer',
                          ) ==
                          true)
                        ..._buildTransferDetails(transaction),
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
                      if (transaction['remarks'] != null)
                        _buildDetailRow('Remarks', transaction['remarks']),
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

  List<Widget> _buildTransferDetails(Map<String, dynamic> transaction) {
    final isTransferOut = transaction['type'] == 'transfer_out';
    final isTransferIn = transaction['type'] == 'transfer_in';

    List<Widget> details = [];

    if (isTransferOut && transaction['receiver_name'] != null) {
      details.add(_buildDetailRow('To', transaction['receiver_name']));
      if (transaction['receiver_email'] != null) {
        details.add(
          _buildDetailRow('Recipient Email', transaction['receiver_email']),
        );
      }
    }

    if (isTransferIn && transaction['sender_name'] != null) {
      details.add(_buildDetailRow('From', transaction['sender_name']));
      if (transaction['sender_email'] != null) {
        details.add(
          _buildDetailRow('Sender Email', transaction['sender_email']),
        );
      }
    }

    return details;
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

  // ========== Data Loading ==========

  Future<void> _loadRecentTransactions() async {
    try {
      setState(() => _isLoading = true);

      final user = _auth.currentUser;
      if (user?.email == null) return;

      final querySnapshot = await _db
          .collection('interactions')
          .where('user_email', isEqualTo: user!.email)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      final transactions = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      setState(() {
        _recentTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // ========== Helper Methods ==========

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'topup':
        return Icons.account_balance_wallet;
      case 'transfer_out':
        return Icons.call_made;
      case 'transfer_in':
        return Icons.call_received;
      default:
        return Icons.receipt;
    }
  }

  String _getTransactionTitle(String type) {
    switch (type.toLowerCase()) {
      case 'topup':
        return 'Top Up';
      case 'transfer_out':
        return 'Transfer Sent';
      case 'transfer_in':
        return 'Transfer Received';
      default:
        return 'Transaction';
    }
  }

  String _formatTransactionStatus(String status) {
    return status.toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

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
