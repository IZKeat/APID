// lib/models/ai_analysis_report.dart
import 'dart:convert';

/// 📊 AI Analysis Report Model
/// Represents the structured response from the AI Smart Contextual Advisor.
class AiAnalysisReport {
  final String summary;
  final List<String> keywords;
  final String persona;
  final Map<String, double> spendingBreakdown;
  final String suggestion;
  final DateTime generatedAt;

  AiAnalysisReport({
    required this.summary,
    required this.keywords,
    required this.persona,
    required this.spendingBreakdown,
    required this.suggestion,
    required this.generatedAt,
  });

  /// Factory constructor to create an instance from a JSON map.
  /// Robustly handles missing or malformed data.
  factory AiAnalysisReport.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse double values
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to safely parse map of doubles
    Map<String, double> parseSpendingBreakdown(dynamic map) {
      if (map is! Map) return {};
      final result = <String, double>{};
      map.forEach((key, value) {
        result[key.toString()] = parseDouble(value);
      });
      return result;
    }

    return AiAnalysisReport(
      summary: json['summary']?.toString() ?? 'No summary available.',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      persona: json['persona']?.toString() ?? 'Campus Explorer',
      spendingBreakdown: parseSpendingBreakdown(json['spendingBreakdown']),
      suggestion: json['suggestion']?.toString() ?? 'Keep exploring campus!',
      generatedAt: DateTime.now(),
    );
  }

  /// Factory constructor to create an instance from a raw JSON string.
  /// Useful when parsing direct API responses.
  factory AiAnalysisReport.fromRawJson(String str) {
    try {
      final decoded = json.decode(str);
      return AiAnalysisReport.fromJson(decoded);
    } catch (e) {
      // Fallback for malformed JSON
      print('Error parsing AI Report JSON: $e');
      return AiAnalysisReport(
        summary: 'Could not generate report due to a format error.',
        keywords: ['Error'],
        persona: 'Unknown',
        spendingBreakdown: {},
        suggestion: 'Please try again later.',
        generatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'keywords': keywords,
      'persona': persona,
      'spendingBreakdown': spendingBreakdown,
      'suggestion': suggestion,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
