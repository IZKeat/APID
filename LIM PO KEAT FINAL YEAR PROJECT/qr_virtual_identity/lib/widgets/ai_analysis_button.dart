// lib/widgets/ai_analysis_button.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ai_analysis_modal.dart';

class AiAnalysisButton extends StatelessWidget {
  const AiAnalysisButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AiAnalysisModal(),
        );
      },
      child: Container(
        width: 80, // Match other Quick Utility cards width if possible or adaptive
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Shimmering Background
                Shimmer.fromColors(
                  baseColor: Colors.purple.shade100,
                  highlightColor: Colors.purple.shade50,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.shade400.withOpacity(0.2),
                        Colors.blue.shade400.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: Colors.purple,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "AI Insights",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
