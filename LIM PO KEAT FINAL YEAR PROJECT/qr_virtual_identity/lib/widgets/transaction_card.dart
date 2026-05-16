// lib/widgets/transaction_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Transaction Card Widget
/// Displays individual transaction with proper styling and type-based formatting
class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = transaction['type'] as String? ?? '';
    final status = transaction['status'] as String? ?? '';
    final scanPointName = transaction['scan_point_name'] as String? ?? '';
    final remarks = transaction['remarks'] as String? ?? '';
    final amount = (transaction['amount'] as num?)?.toDouble();
    final paymentMethod = transaction['payment_method'] as String? ?? '';
    final timestamp = transaction['timestamp'];

    // Format timestamp
    String formattedTime = '';
    if (timestamp != null) {
      DateTime dateTime;
      if (timestamp.runtimeType.toString() == 'Timestamp') {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        dateTime = DateTime.now();
      }
      formattedTime = DateFormat('MMM dd, HH:mm').format(dateTime);
    }

    // Get icon and color based on transaction type
    final iconData = _getTransactionIcon(type);
    final iconColor = _getTransactionColor(type);

    // Format amount display
    String amountDisplay = '';
    Color amountColor = AppTheme.textSecondary;
    if (amount != null) {
      final isPositive = _isPositiveTransaction(type);
      final sign = isPositive ? '+' : '-';
      amountDisplay = '$sign RM ${amount.abs().toStringAsFixed(2)}';
      amountColor = isPositive ? AppTheme.successColor : AppTheme.errorColor;
    }

    // Get title and subtitle
    final title = _getTransactionTitle(type, scanPointName);
    final subtitle = _getTransactionSubtitle(type, remarks, paymentMethod);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (amount != null)
                    Text(
                      amountDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: amountColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return Icons.shopping_cart_outlined;
      case 'refund':
        return Icons.undo_outlined;
      case 'borrow':
        return Icons.library_books_outlined;
      case 'return':
        return Icons.assignment_return_outlined;
      case 'entry':
        return Icons.login_outlined;
      case 'exit':
        return Icons.logout_outlined;
      case 'attendance':
        return Icons.school_outlined;
      case 'booking':
        return Icons.event_seat_outlined;
      case 'topup':
        return Icons.add_circle_outline;
      case 'transfer':
        return Icons.send_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'purchase':
        return AppTheme.purchaseColor;
      case 'refund':
        return AppTheme.refundColor;
      case 'borrow':
        return AppTheme.borrowColor;
      case 'return':
        return AppTheme.returnColor;
      case 'entry':
        return AppTheme.entryColor;
      case 'exit':
        return AppTheme.exitColor;
      case 'attendance':
        return AppTheme.attendanceColor;
      case 'booking':
        return AppTheme.bookingColor;
      case 'topup':
        return AppTheme.successColor;
      case 'transfer':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'denied':
      case 'failed':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  bool _isPositiveTransaction(String type) {
    // Positive transactions (money coming in)
    return ['refund', 'topup'].contains(type.toLowerCase());
  }

  String _getTransactionTitle(String type, String scanPointName) {
    if (scanPointName.isNotEmpty &&
        !scanPointName.toLowerCase().contains('unknown')) {
      return scanPointName;
    }

    switch (type.toLowerCase()) {
      case 'purchase':
        return 'Purchase';
      case 'refund':
        return 'Refund';
      case 'borrow':
        return 'Book Borrowed';
      case 'return':
        return 'Book Returned';
      case 'entry':
        return 'Campus Entry';
      case 'exit':
        return 'Campus Exit';
      case 'attendance':
        return 'Attendance';
      case 'booking':
        return 'Booking';
      case 'topup':
        return 'Top Up';
      case 'transfer':
        return 'Transfer';
      default:
        return 'Transaction';
    }
  }

  String _getTransactionSubtitle(
    String type,
    String remarks,
    String paymentMethod,
  ) {
    // If there are meaningful remarks, use them
    if (remarks.isNotEmpty && !remarks.toLowerCase().contains('unknown')) {
      return remarks;
    }

    // Otherwise, show payment method if available
    if (paymentMethod.isNotEmpty &&
        !paymentMethod.toLowerCase().contains('unknown')) {
      return 'via $paymentMethod';
    }

    // Fallback to type-specific subtitle
    switch (type.toLowerCase()) {
      case 'purchase':
        return 'Payment processed';
      case 'refund':
        return 'Amount refunded';
      case 'borrow':
        return 'Library transaction';
      case 'return':
        return 'Book returned';
      case 'entry':
      case 'exit':
        return 'Access control';
      case 'attendance':
        return 'Class attendance';
      case 'booking':
        return 'Resource booking';
      case 'topup':
        return 'Wallet top up';
      case 'transfer':
        return 'Money transfer';
      default:
        return 'Campus transaction';
    }
  }
}
