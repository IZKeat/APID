// lib/widgets/ai_analysis_modal.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/ai_analysis_service.dart';
import '../pages_user/ai_report_view.dart';

class AiAnalysisModal extends StatefulWidget {
  const AiAnalysisModal({super.key});

  @override
  State<AiAnalysisModal> createState() => _AiAnalysisModalState();
}

class _AiAnalysisModalState extends State<AiAnalysisModal> {
  String _statusMessage = "Connecting to Campus Brain...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    try {
      // simulate steps for better UX
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _statusMessage = "Aggregating your data...");

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _statusMessage = "Analyzing spending habits...");

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _statusMessage = "Generating your persona...");

      // Real API Call
      final report = await AiAnalysisService().generateReport();

      if (!mounted) return;

      if (report != null) {
        // Close modal and open report
        Navigator.of(context).pop(); // Close modal
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AiReportView(report: report),
          ),
        );
      } else {
        setState(() {
          _hasError = true;
          _statusMessage = "Failed to generate report. Please try again.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = "An error occurred: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation
            SizedBox(
              height: 150,
              width: 150,
              child: _hasError
                  ? const Icon(Icons.error_outline,
                      size: 60, color: Colors.red)
                  : Lottie.network(
                      'https://lottie.host/956e1e4f-8c9e-4f1a-b6a3-2c9a1b5c9b1d/7Z5Z5Z5Z5Z.json', // Placeholder Robot Animation
                      errorBuilder: (context, error, stackTrace) {
                        return const CircularProgressIndicator(
                          color: Colors.purple,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            // Status Text
            Text(
              _hasError ? "Oops!" : "AI Analysis",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            // Close Button (only if error)
            if (_hasError)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
          ],
        ),
      ),
    );
  }
}
