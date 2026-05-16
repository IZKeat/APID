import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityCharts extends StatefulWidget {
  final String selectedFilter;

  const ActivityCharts({super.key, required this.selectedFilter});

  @override
  State<ActivityCharts> createState() => _ActivityChartsState();
}

class _ActivityChartsState extends State<ActivityCharts>
    with TickerProviderStateMixin {
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  Map<String, dynamic> _weeklyStats = {};
  Map<String, int> _categoryStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchWeeklyStats();
  }

  void _initAnimations() {
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchWeeklyStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );

      // Get last 7 days of data
      final query = FirebaseFirestore.instance
          .collection('interactions')
          .where('user_id', isEqualTo: user.uid)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDate),
          )
          .where('status', isEqualTo: 'success');

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _weeklyStats = _calculateWeeklyStats(snapshot.docs, weekStartDate);
          _categoryStats = _calculateCategoryStats(snapshot.docs);
          _isLoading = false;
        });
        _chartAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _calculateWeeklyStats(
    List<QueryDocumentSnapshot> docs,
    DateTime weekStart,
  ) {
    final Map<int, int> dailyActivities = {};
    final Map<int, double> dailyAmounts = {};
    double totalWeeklyAmount = 0.0;
    int totalWeeklyActivities = 0;

    // Initialize days of the week (0 = Monday, 6 = Sunday)
    for (int i = 0; i < 7; i++) {
      dailyActivities[i] = 0;
      dailyAmounts[i] = 0.0;
    }

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;

      if (timestamp != null) {
        final date = timestamp.toDate();
        final dayIndex = date.difference(weekStart).inDays;

        if (dayIndex >= 0 && dayIndex < 7) {
          dailyActivities[dayIndex] = (dailyActivities[dayIndex] ?? 0) + 1;
          totalWeeklyActivities++;

          final amount = data['amount'] as num?;
          if (amount != null) {
            dailyAmounts[dayIndex] =
                (dailyAmounts[dayIndex] ?? 0) + amount.toDouble();
            totalWeeklyAmount += amount.toDouble();
          }
        }
      }
    }

    return {
      'dailyActivities': dailyActivities,
      'dailyAmounts': dailyAmounts,
      'totalWeeklyAmount': totalWeeklyAmount,
      'totalWeeklyActivities': totalWeeklyActivities,
    };
  }

  Map<String, int> _calculateCategoryStats(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> stats = {
      'library': 0,
      'commerce': 0,
      'access': 0,
      'booking': 0,
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'borrow':
        case 'return':
          stats['library'] = (stats['library'] ?? 0) + 1;
          break;
        case 'purchase':
        case 'refund':
          stats['commerce'] = (stats['commerce'] ?? 0) + 1;
          break;
        case 'entry':
        case 'exit':
        case 'attendance':
          stats['access'] = (stats['access'] ?? 0) + 1;
          break;
        case 'booking':
          stats['booking'] = (stats['booking'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              const Text(
                '📈 Weekly Statistical Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A1B9A), // Stronger purple
                ),
              ),
              const SizedBox(height: 16),

              // Weekly summary cards
              _buildWeeklySummary(),
              const SizedBox(height: 24),

              // Daily activity chart
              _buildDailyActivityChart(),
              const SizedBox(height: 24),

              // Category distribution chart
              _buildCategoryChart(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF6A1B9A),
                ), // Stronger purple
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary() {
    final totalActivities = _weeklyStats['totalWeeklyActivities'] ?? 0;
    final totalAmount = _weeklyStats['totalWeeklyAmount'] ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Weekly Total Activities',
            totalActivities.toString(),
            Icons.timeline,
            const Color(0xFF2E7D32), // Stronger green
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Weekly Spending',
            'RM ${totalAmount.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            const Color(0xFFE65100), // Stronger orange
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Transform.scale(
      scale: _chartAnimation.value,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyActivityChart() {
    final dailyActivities =
        _weeklyStats['dailyActivities'] as Map<int, int>? ?? {};
    final maxY = dailyActivities.values.isNotEmpty
        ? dailyActivities.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 5.0;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Activity Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
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
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY > 0 ? maxY : 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: dailyActivities.entries
                        .map(
                          (e) => FlSpot(e.key.toDouble(), e.value.toDouble()),
                        )
                        .toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(
                          0xFF6A1B9A,
                        ).withOpacity(0.9), // Stronger purple
                        const Color(0xFF6A1B9A).withOpacity(0.1),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(
                            0xFF6A1B9A,
                          ), // Stronger purple
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(
                            0xFF6A1B9A,
                          ).withOpacity(0.3), // Stronger purple
                          const Color(
                            0xFF8E24AA,
                          ).withOpacity(0.05), // Stronger purple variant
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    final totalCategories = _categoryStats.values.fold(
      0,
      (sum, count) => sum + count,
    );

    if (totalCategories == 0) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No categorical data available',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),

                // Legend
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildLegend(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final totalCategories = _categoryStats.values.fold(
      0,
      (sum, count) => sum + count,
    );
    const colors = [
      Color(0xFF1565C0), // Library - Stronger Blue
      Color(0xFF2E7D32), // Commerce - Stronger Green
      Color(0xFFE65100), // Access - Stronger Orange
      Color(0xFF7B1FA2), // Booking - Stronger Purple
    ];

    final categories = ['library', 'commerce', 'access', 'booking'];
    final sections = <PieChartSectionData>[];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final count = _categoryStats[category] ?? 0;

      if (count > 0) {
        final percentage = (count / totalCategories) * 100;
        sections.add(
          PieChartSectionData(
            color: colors[i],
            value: count.toDouble(),
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return sections;
  }

  List<Widget> _buildLegend() {
    final colors = [
      const Color(0xFF1565C0), // Library - Stronger Blue
      const Color(0xFF2E7D32), // Commerce - Stronger Green
      const Color(0xFFE65100), // Access - Stronger Orange
      const Color(0xFF7B1FA2), // Booking - Stronger Purple
    ];

    final labels = ['Library', 'Shopping', 'Access', 'Booking'];
    final categories = ['library', 'commerce', 'access', 'booking'];

    return List.generate(4, (index) {
      final count = _categoryStats[categories[index]] ?? 0;
      if (count == 0) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${labels[index]} ($count)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
