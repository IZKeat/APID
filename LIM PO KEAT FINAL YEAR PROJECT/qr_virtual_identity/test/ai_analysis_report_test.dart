// test/ai_analysis_report_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:apid/models/ai_analysis_report.dart';

void main() {
  group('AiAnalysisReport', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        "summary": "You had a great month!",
        "keywords": ["Studious", "Active"],
        "persona": "Campus Star",
        "spendingBreakdown": {
          "Food": 100.0,
          "Transport": 50.5
        },
        "suggestion": "Try the new cafe."
      };

      final report = AiAnalysisReport.fromJson(json);

      expect(report.summary, "You had a great month!");
      expect(report.keywords, ["Studious", "Active"]);
      expect(report.persona, "Campus Star");
      expect(report.spendingBreakdown["Food"], 100.0);
      expect(report.spendingBreakdown["Transport"], 50.5);
      expect(report.suggestion, "Try the new cafe.");
    });

    test('fromRawJson handles malformed JSON gracefully', () {
      const rawJson = "This is not JSON";
      final report = AiAnalysisReport.fromRawJson(rawJson);

      expect(report.summary, contains("Could not generate report"));
      expect(report.keywords, ["Error"]);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{}; // Empty map
      final report = AiAnalysisReport.fromJson(json);

      expect(report.summary, "No summary available.");
      expect(report.keywords, isEmpty);
      expect(report.persona, "Campus Explorer");
      expect(report.spendingBreakdown, isEmpty);
    });
  });
}
