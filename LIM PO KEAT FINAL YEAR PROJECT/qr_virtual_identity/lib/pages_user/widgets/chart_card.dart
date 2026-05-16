// lib/pages_user/widgets/chart_card.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// 📊 Chart Card Widget
/// Container for analytics charts with title and optional actions
class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final Widget? action;
  final double height;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.action,
    this.height = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppTheme.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTheme.heading3),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(subtitle!, style: AppTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: AppTheme.spacingMD),
            // Chart
            SizedBox(height: height, child: chart),
          ],
        ),
      ),
    );
  }
}

/// 📈 Empty Chart Placeholder
class EmptyChartPlaceholder extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyChartPlaceholder({
    super.key,
    required this.message,
    this.icon = Icons.insert_chart_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textHint),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
