import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Material 3 Color Palette (same as dashboard)
class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFFE9E7FD);
  static const cardBg = Color(0xFFFFFFFF);
  static const fontDark = Color(0xFF1E1E1E);
  static const success = Color(0xFF00C896);
  static const error = Color(0xFFFF4C4C);
  static const warning = Color(0xFFFFA500);
  static const lightGrey = Color(0xFFF5F5F5);
}

class TransactionsDesktopPage extends StatefulWidget {
  const TransactionsDesktopPage({super.key, required this.stream});

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  @override
  State<TransactionsDesktopPage> createState() =>
      _TransactionsDesktopPageState();
}

class _TransactionsDesktopPageState extends State<TransactionsDesktopPage> {
  String _filter = 'all'; // all, success, pending, refunded
  String _searchQuery = '';

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'refunded':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'refunded':
        return Icons.undo_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txnDate = DateTime(dt.year, dt.month, dt.day);

    String dateStr;
    if (txnDate == today) {
      dateStr = 'Today';
    } else if (txnDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dt.month}/${dt.day}/${dt.year}';
    }

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$dateStr • $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, txnSnap) {
        // Calculate statistics
        int totalCount = 0;
        double totalRevenue = 0;
        int successCount = 0;
        int pendingCount = 0;
        int refundedCount = 0;

        List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs = [];

        if (txnSnap.hasData) {
          final allDocs = txnSnap.data!.docs;
          totalCount = allDocs.length;

          for (final doc in allDocs) {
            final data = doc.data();
            final amt = (data['amount'] is num)
                ? (data['amount'] as num).toDouble()
                : 0.0;
            final status = (data['status']?.toString() ?? 'success')
                .toLowerCase();

            totalRevenue += amt;
            if (status == 'success') successCount++;
            if (status == 'pending') pendingCount++;
            if (status == 'refunded') refundedCount++;

            // Apply filters
            if (_filter != 'all' && status != _filter) continue;
            if (_searchQuery.isNotEmpty) {
              final searchLower = _searchQuery.toLowerCase();
              final amtStr = amt.toString();
              final remarks = data['remarks']?.toString().toLowerCase() ?? '';
              if (!amtStr.contains(searchLower) &&
                  !remarks.contains(searchLower)) {
                continue;
              }
            }

            filteredDocs.add(doc);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Header with purple background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF8B7FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Total Revenue
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.payments_rounded,
                      label: 'Total Revenue',
                      value: 'RM ${totalRevenue.toStringAsFixed(2)}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  // Total Transactions
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Total Transactions',
                      value: totalCount.toString(),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  // Success Rate
                  Expanded(
                    child: _summaryItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Success Rate',
                      value: totalCount > 0
                          ? '${((successCount / totalCount) * 100).toStringAsFixed(1)}%'
                          : '0%',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Filter and Search Bar
            Row(
              children: [
                // Filter chips
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('All', 'all', totalCount),
                      _filterChip('Success', 'success', successCount),
                      _filterChip('Pending', 'pending', pendingCount),
                      _filterChip('Refunded', 'refunded', refundedCount),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Search bar
                SizedBox(
                  width: 300,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: AppColors.lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Transactions List
            Expanded(
              child: filteredDocs.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: filteredDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final data = filteredDocs[idx].data();
                        final amt = (data['amount'] is num)
                            ? (data['amount'] as num).toDouble()
                            : 0.0;
                        final status = data['status']?.toString() ?? 'success';
                        final remarks =
                            data['remarks']?.toString() ?? 'No remarks';
                        final transId = data['trans_id']?.toString() ?? 'N/A';
                        final timestamp = data['timestamp'];
                        DateTime? dt;
                        if (timestamp is Timestamp) {
                          dt = timestamp.toDate();
                        } else if (timestamp is int) {
                          dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
                        }

                        // Extract items list safely
                        List<Map<String, dynamic>>? items;
                        if (data['items'] != null && data['items'] is List) {
                          items = List<Map<String, dynamic>>.from(
                            (data['items'] as List).map(
                              (item) => Map<String, dynamic>.from(item),
                            ),
                          );
                        }

                        return _transactionCard(
                          amount: amt,
                          status: status,
                          remarks: remarks,
                          transId: transId,
                          dateTime: dt,
                          items: items,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = selected ? value : 'all');
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.secondary,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  Widget _transactionCard({
    required double amount,
    required String status,
    required String remarks,
    required String transId,
    DateTime? dateTime,
    List<Map<String, dynamic>>? items,
  }) {
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.fontDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                remarks,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateTime != null ? _formatDateTime(dateTime) : 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.tag_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transId,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (items != null && items.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              // Product Table Header
              const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "Item",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Price",
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Qty",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Total",
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Product List
              ...items.map((item) {
                final name = item['name'] ?? 'Unknown Item';
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final qty = (item['qty'] as num?)?.toInt() ?? 1;
                final total = price * qty;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          price.toStringAsFixed(2),
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          qty.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          total.toStringAsFixed(2),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "No detailed item list available for this transaction.",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions found',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter != 'all'
                ? 'Try changing your filter'
                : 'Start by scanning a QR code\nto make your first payment',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
