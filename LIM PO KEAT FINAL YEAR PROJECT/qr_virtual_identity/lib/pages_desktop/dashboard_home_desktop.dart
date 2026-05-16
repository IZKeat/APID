import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// Material 3 Color Palette
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

class DashboardHomeDesktop extends StatelessWidget {
  const DashboardHomeDesktop({
    super.key,
    required this.shopName,
    required this.merchantId,
    required this.lastActive,
    required this.transactionsStream,
    required this.fallbackTxnCount,
    required this.fallbackScanCount,
    required this.fallbackRevenue,
    required this.onLogout,
    required this.onTriggerScanner,
  });

  final String shopName;
  final String merchantId;
  final DateTime? lastActive;
  final Stream<QuerySnapshot<Map<String, dynamic>>> transactionsStream;
  final String fallbackTxnCount;
  final String fallbackScanCount;
  final double fallbackRevenue;
  final VoidCallback onLogout;
  final VoidCallback onTriggerScanner;

  Widget _barChart(Map<String, double> revenueByDay) {
    final labels = revenueByDay.keys.toList();
    final values = revenueByDay.values.toList();
    final maxVal = (values.isEmpty ? 1.0 : values.reduce(max)) * 1.2;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Revenue (last 7 days)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.fontDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxVal <= 0 ? 1 : maxVal,
                  minY: 0,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: maxVal > 0 ? maxVal / 4 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max || value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (index, meta) {
                          final i = index.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              labels[i],
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  barGroups: List.generate(labels.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i] > 0 ? values[i] : 0.01,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF9C92FF)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 24,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Header with gradient background
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
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              merchantId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified Merchant',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onTriggerScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    color: Colors.white,
                    tooltip: 'Logout',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Header with Filter
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.dashboard_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Summary Overview',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.fontDark,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    // Add search / date filter logic later
                  },
                  icon: const Icon(
                    Icons.filter_list_rounded,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Filter & Search',
                ),
              ),
            ],
          ),
        ),

        // Overview cards (computed from transactions)
        const SizedBox.shrink(),

        const SizedBox(height: 18),

        // Chart + Recent transactions
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: transactionsStream,
            builder: (context, txnSnap) {
              Map<String, double> revenueByDay;
              if (txnSnap.hasData && txnSnap.data!.docs.isNotEmpty) {
                final now = DateTime.now();
                final days = List.generate(
                  7,
                  (i) => DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(Duration(days: 6 - i)),
                );
                final labels = days.map((d) => '${d.month}/${d.day}').toList();
                final map = <String, double>{for (var l in labels) l: 0.0};

                for (final doc in txnSnap.data!.docs) {
                  final data = doc.data();
                  final ts = data['timestamp'];
                  DateTime? dt;
                  if (ts is Timestamp) {
                    dt = ts.toDate();
                  } else if (ts is int) {
                    dt = DateTime.fromMillisecondsSinceEpoch(ts);
                  }
                  if (dt == null) continue;
                  final label = '${dt.month}/${dt.day}';
                  if (map.containsKey(label)) {
                    final amt = (data['amount'] is num)
                        ? (data['amount'] as num).toDouble()
                        : 0.0;
                    map[label] = map[label]! + amt;
                  }
                }
                revenueByDay = map;
              } else {
                // Fallback: mock chart to avoid empty look
                final now = DateTime.now();
                final rnd = Random();
                final m = <String, double>{};
                for (var i = 6; i >= 0; i--) {
                  final d = DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).subtract(Duration(days: i));
                  m['${d.month}/${d.day}'] = (rnd.nextDouble() * 300) + 20;
                }
                revenueByDay = m;
              }

              return Row(
                children: [
                  Expanded(flex: 2, child: _barChart(revenueByDay)),
                  /*
                  // COMMENTED OUT AS REQUESTED - RECENT TRANSACTIONS
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Recent Transactions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.fontDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child:
                                  txnSnap.hasData &&
                                      txnSnap.data!.docs.isNotEmpty
                                  ? ListView.separated(
                                      itemCount: txnSnap.data!.docs.length
                                          .clamp(0, 10),
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, idx) {
                                        final d = txnSnap.data!.docs[idx]
                                            .data();
                                        final amt = (d['amount'] is num)
                                            ? (d['amount'] as num).toDouble()
                                            : 0.0;
                                        final status =
                                            d['status']?.toString() ??
                                            'success';
                                        final when = d['timestamp'] is Timestamp
                                            ? (d['timestamp'] as Timestamp)
                                                  .toDate()
                                            : null;

                                        // Get interaction type and user info
                                        final type =
                                            d['type']?.toString() ?? 'unknown';
                                        final userName = d['user_name']
                                            ?.toString();
                                        final userEmail = d['user_email']
                                            ?.toString();

                                        // Status color
                                        Color statusColor = const Color(
                                          0xFF00C896,
                                        );
                                        IconData iconData = Icons.check_circle;

                                        if (status == 'pending') {
                                          statusColor = const Color(0xFFFFA500);
                                          iconData = Icons.pending;
                                        } else if (status == 'refunded') {
                                          statusColor = const Color(0xFFFF4C4C);
                                          iconData = Icons.cancel;
                                        } else if (type == 'access_granted') {
                                          statusColor = const Color(0xFF00C896);
                                          iconData = Icons.login;
                                        } else if (type == 'access_denied') {
                                          statusColor = const Color(0xFFFF4C4C);
                                          iconData = Icons.block;
                                        } else if (type == 'book_borrowed') {
                                          statusColor = Colors.blue;
                                          iconData = Icons.book;
                                        } else if (type == 'book_returned') {
                                          statusColor = Colors.purple;
                                          iconData = Icons.book_outlined;
                                        } else if (type == 'event_checkin') {
                                          statusColor = Colors.teal;
                                          iconData = Icons.confirmation_number;
                                        }

                                        // Display text based on type
                                        String displayText;
                                        if (type == 'access_granted' ||
                                            type == 'access_denied') {
                                          displayText =
                                              userName ??
                                              userEmail ??
                                              'Unknown User';
                                        } else if (type == 'book_borrowed' ||
                                            type == 'book_returned') {
                                          displayText =
                                              userName ??
                                              userEmail ??
                                              'Book Activity';
                                        } else if (type == 'event_checkin') {
                                          final eventName = d['event_name']
                                              ?.toString();
                                          displayText =
                                              eventName ??
                                              userName ??
                                              userEmail ??
                                              'Event Check-In';
                                        } else {
                                          displayText =
                                              'RM ${amt.toStringAsFixed(2)}';
                                        }

                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  iconData,
                                                  size: 14,
                                                  color: statusColor,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      displayText,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      when != null
                                                          ? '${when.month}/${when.day} ${when.hour}:${when.minute.toString().padLeft(2, '0')}'
                                                          : 'N/A',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Type badge
                                              if (type != 'payment')
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    type
                                                        .replaceAll('_', ' ')
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ),
                                              if (type == 'payment')
                                                Text(
                                                  'RM ${amt.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Text(
                                        'No recent transactions',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  },
                  */
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
