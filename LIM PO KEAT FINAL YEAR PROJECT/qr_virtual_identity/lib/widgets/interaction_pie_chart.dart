import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/chart_service.dart';

class InteractionPieChart extends StatelessWidget {
  const InteractionPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final chartService = ChartService();
    final pieData = chartService.createPieChartData(
      chartService.generateInteractionData(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.donut_small, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Campus Interactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(pieData),
            ),
          ],
        ),
      ),
    );
  }
}