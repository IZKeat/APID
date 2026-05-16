import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/chart_service.dart';

class SpendingLineChart extends StatelessWidget {
  const SpendingLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    final chartService = ChartService();
    final lineData = chartService.createLineChartData(
      chartService.generateSpendingTrendData(),
      Colors.deepPurple,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Spending Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(lineData),
            ),
          ],
        ),
      ),
    );
  }
}