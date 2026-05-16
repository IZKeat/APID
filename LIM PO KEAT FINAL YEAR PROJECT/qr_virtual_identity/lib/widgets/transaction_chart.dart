// lib/widgets/transaction_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

/// Interactive Transaction Chart Widget
/// Bar chart showing spending breakdown by category with tap interactions
class TransactionChart extends StatefulWidget {
  final Map<String, double> categoryData;
  final String? selectedCategory;
  final Function(String category)? onCategoryTap;
  final double maxAmount;

  const TransactionChart({
    super.key,
    required this.categoryData,
    this.selectedCategory,
    this.onCategoryTap,
    this.maxAmount = 100.0,
  });

  @override
  State<TransactionChart> createState() => _TransactionChartState();
}

class _TransactionChartState extends State<TransactionChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) {
      return Container(
        height: 200,
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: AppTheme.textHint,
              ),
              SizedBox(height: 8),
              Text(
                'No spending data available',
                style: TextStyle(color: AppTheme.textHint, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppTheme.primaryColor.withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final categoryName = _getCategoryNames()[groupIndex];
                      final amount = rod.toY;
                      return BarTooltipItem(
                        '$categoryName\\nRM ${amount.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = null;
                        return;
                      }
                      touchedIndex =
                          barTouchResponse.spot!.touchedBarGroupIndex;
                    });

                    // Handle category tap
                    if (event is FlTapUpEvent &&
                        barTouchResponse?.spot != null &&
                        widget.onCategoryTap != null) {
                      final categoryIndex =
                          barTouchResponse!.spot!.touchedBarGroupIndex;
                      final categoryName = _getCategoryNames()[categoryIndex];
                      widget.onCategoryTap!(categoryName);
                    }
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
                        final categories = _getCategoryNames();
                        if (value.toInt() >= 0 &&
                            value.toInt() < categories.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _getShortCategoryName(categories[value.toInt()]),
                              style: TextStyle(
                                color:
                                    widget.selectedCategory ==
                                        categories[value.toInt()]
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight:
                                    widget.selectedCategory ==
                                        categories[value.toInt()]
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'RM${value.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: widget.maxAmount / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.textHint.withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                maxY: widget.maxAmount,
                minY: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  List<String> _getCategoryNames() {
    return widget.categoryData.keys.toList();
  }

  String _getShortCategoryName(String fullName) {
    final Map<String, String> shortNames = {
      'Smokey Café': 'Café',
      'Campus Mart': 'Mart',
      'Library Counter': 'Library',
      'Lab A Room Booking': 'Lab',
      'Lecture Hall B Attendance': 'Lecture',
      'Main Gate Access': 'Access',
    };

    return shortNames[fullName] ??
        (fullName.length > 8 ? fullName.substring(0, 8) : fullName);
  }

  Color _getCategoryColor(String category, int index) {
    final colors = [
      AppTheme.purchaseColor,
      AppTheme.accentColor,
      AppTheme.borrowColor,
      AppTheme.bookingColor,
      AppTheme.attendanceColor,
      AppTheme.successColor,
    ];

    final isSelected = widget.selectedCategory == category;
    final isTouched = touchedIndex == index;

    Color baseColor = colors[index % colors.length];

    if (isSelected || isTouched) {
      return baseColor;
    } else if (widget.selectedCategory != null) {
      return baseColor.withOpacity(0.3);
    }

    return baseColor;
  }

  List<BarChartGroupData> _getBarGroups() {
    final categories = _getCategoryNames();
    final List<BarChartGroupData> groups = [];

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final amount = widget.categoryData[category] ?? 0.0;
      final color = _getCategoryColor(category, i);

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: color,
              width: 24,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: widget.maxAmount,
                color: AppTheme.backgroundLight,
              ),
            ),
          ],
        ),
      );
    }

    return groups;
  }

  Widget _buildLegend() {
    final categories = _getCategoryNames();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final amount = widget.categoryData[category] ?? 0.0;
        final color = _getCategoryColor(category, index);
        final isSelected = widget.selectedCategory == category;

        return GestureDetector(
          onTap: () => widget.onCategoryTap?.call(category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: color, width: 1) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getShortCategoryName(category),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? color : AppTheme.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'RM${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? color : AppTheme.textHint,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
