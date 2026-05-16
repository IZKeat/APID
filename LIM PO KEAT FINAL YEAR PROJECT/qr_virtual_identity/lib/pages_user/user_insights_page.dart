// lib/pages_user/user_insights_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import 'widgets/chart_card.dart';

/// 📊 User Insights Page
/// Data visualization with charts for spending, scan points, and analytics
class UserInsightsPage extends StatefulWidget {
  const UserInsightsPage({super.key});

  @override
  State<UserInsightsPage> createState() => _UserInsightsPageState();
}

class _UserInsightsPageState extends State<UserInsightsPage> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Your Insights'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            children: [
              _buildMonthlySpendingChart(user.uid),
              const SizedBox(height: AppTheme.spacingLG),
              _buildScanPointsDistribution(user.uid),
              const SizedBox(height: AppTheme.spacingLG),
              _buildQuickStats(user.uid),
              const SizedBox(height: AppTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  // ========== Monthly Spending Trend ==========
  Widget _buildMonthlySpendingChart(String uid) {
    return FutureBuilder<Map<String, double>>(
      future: UserService.getMonthlySpending(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ChartCard(
            title: 'Monthly Spending Trend',
            subtitle: 'Last 6 months',
            chart: const Center(child: CircularProgressIndicator()),
          );
        }

        final monthlyData = snapshot.data!;

        if (monthlyData.isEmpty) {
          return ChartCard(
            title: 'Monthly Spending Trend',
            subtitle: 'Last 6 months',
            chart: const EmptyChartPlaceholder(
              message: 'No spending data yet',
              icon: Icons.show_chart,
            ),
          );
        }

        // Prepare data for chart
        final sortedMonths = monthlyData.keys.toList()..sort();
        final spots = <FlSpot>[];

        for (var i = 0; i < sortedMonths.length; i++) {
          final month = sortedMonths[i];
          final amount = monthlyData[month]!;
          spots.add(FlSpot(i.toDouble(), amount));
        }

        return ChartCard(
          title: 'Monthly Spending Trend',
          subtitle: 'Last ${sortedMonths.length} months',
          chart: Padding(
            padding: const EdgeInsets.only(right: 16, top: 16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textHint.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedMonths.length) {
                          final month = sortedMonths[value.toInt()];
                          final parts = month.split('-');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${parts[1]}/${parts[0].substring(2)}',
                              style: AppTheme.caption,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'RM${value.toInt()}',
                          style: AppTheme.caption,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========== Scan Points Distribution ==========
  Widget _buildScanPointsDistribution(String uid) {
    return FutureBuilder<Map<String, int>>(
      future: UserService.getScanPointsDistribution(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ChartCard(
            title: 'Most Visited Scan Points',
            subtitle: 'All time',
            chart: const Center(child: CircularProgressIndicator()),
          );
        }

        final distribution = snapshot.data!;

        if (distribution.isEmpty) {
          return ChartCard(
            title: 'Most Visited Scan Points',
            subtitle: 'All time',
            chart: const EmptyChartPlaceholder(
              message: 'No scan point data yet',
              icon: Icons.pie_chart,
            ),
          );
        }

        // Get top 5 scan points
        final sortedEntries = distribution.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sortedEntries.take(5).toList();

        final total = top5.fold<int>(0, (sum, e) => sum + e.value);

        // Define colors for each section
        final colors = [
          AppTheme.primaryColor,
          AppTheme.accentColor,
          AppTheme.borrowColor,
          AppTheme.entryColor,
          AppTheme.attendanceColor,
        ];

        return ChartCard(
          title: 'Most Visited Scan Points',
          subtitle: 'Top ${top5.length} locations',
          chart: Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(top5.length, (index) {
                      final entry = top5[index];
                      final percentage = (entry.value / total * 100);
                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: entry.value.toDouble(),
                        title: '${percentage.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(top5.length, (index) {
                    final entry = top5[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== Quick Stats Cards ==========
  Widget _buildQuickStats(String uid) {
    return FutureBuilder<Map<String, dynamic>>(
      future: UserService.getSmartSummary(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final summary = snapshot.data!;
        final totalSpent = summary['total_spent'] as double;
        final totalInteractions = summary['total_interactions'] as int;

        final avgTransaction = totalInteractions > 0
            ? totalSpent / totalInteractions
            : 0.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Stats', style: AppTheme.heading3),
                const SizedBox(height: AppTheme.spacingMD),
                _buildStatRow(
                  icon: Icons.trending_up,
                  label: 'Average Transaction',
                  value: 'RM ${avgTransaction.toStringAsFixed(2)}',
                  color: AppTheme.accentColor,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  icon: Icons.receipt_long,
                  label: 'Total Interactions',
                  value: totalInteractions.toString(),
                  color: AppTheme.primaryColor,
                ),
                const Divider(height: 24),
                _buildStatRow(
                  icon: Icons.account_balance_wallet,
                  label: 'Total Spending',
                  value: 'RM ${totalSpent.toStringAsFixed(2)}',
                  color: AppTheme.purchaseColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppTheme.spacingMD),
        Expanded(child: Text(label, style: AppTheme.bodyMedium)),
        Text(value, style: AppTheme.heading3.copyWith(color: color)),
      ],
    );
  }
}
