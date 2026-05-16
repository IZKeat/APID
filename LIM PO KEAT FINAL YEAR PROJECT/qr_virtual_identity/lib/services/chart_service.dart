import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartService {
  List<FlSpot> generateSpendingTrendData() {
    return [
      const FlSpot(0, 20),
      const FlSpot(1, 35),
      const FlSpot(2, 15),
      const FlSpot(3, 45),
      const FlSpot(4, 25),
      const FlSpot(5, 60),
      const FlSpot(6, 40),
    ];
  }

  List<PieChartSectionData> generateCategoryPieData() {
    return [
      PieChartSectionData(color: Colors.deepPurple, value: 35, title: '35%', radius: 50),
      PieChartSectionData(color: Colors.amber, value: 25, title: '25%', radius: 50),
      PieChartSectionData(color: Colors.blue, value: 20, title: '20%', radius: 50),
      PieChartSectionData(color: Colors.green, value: 20, title: '20%', radius: 50),
    ];
  }

  List<BarChartGroupData> generateAttendanceData() {
    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.green, width: 16)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: Colors.green, width: 16)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 6, color: Colors.green, width: 16)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.green, width: 16)]),
    ];
  }

  List<PieChartSectionData> generateInteractionData() {
    return [
      PieChartSectionData(color: Colors.blue, value: 40, title: '40%', radius: 50),
      PieChartSectionData(color: Colors.orange, value: 30, title: '30%', radius: 50),
      PieChartSectionData(color: Colors.purple, value: 20, title: '20%', radius: 50),
      PieChartSectionData(color: Colors.teal, value: 10, title: '10%', radius: 50),
    ];
  }

  LineChartData createLineChartData(List<FlSpot> spots, Color color) {
    return LineChartData(
      gridData: FlGridData(show: true),
      lineBarsData: [LineChartBarData(spots: spots, color: color, barWidth: 3)],
    );
  }

  PieChartData createPieChartData(List<PieChartSectionData> sections) {
    return PieChartData(sections: sections, centerSpaceRadius: 40);
  }

  BarChartData createBarChartData(List<BarChartGroupData> barGroups, Color color) {
    return BarChartData(barGroups: barGroups, gridData: const FlGridData(show: false));
  }
}
