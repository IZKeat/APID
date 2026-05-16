import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 🎨 JellyGuideOverlay
///
/// A wrapper around [TutorialCoachMark] that provides a consistent
/// "Jelly-style" look and feel for user guides.
class JellyGuideOverlay {
  static void show({
    required BuildContext context,
    required List<TargetFocus> targets,
    Function()? onFinish,
    Function()? onSkip,
  }) {
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.85,
      onFinish: onFinish,
      onSkip: () {
        // 🛑 Intercept Skip: Show Confirmation Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Skip Guide?"),
            content: const Text(
              "Are you sure? You will lose 10 marks for completing this guide.",
              style: TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Cancel
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close Dialog
                  onSkip?.call(); // Trigger actual skip logic (which calls skipLevel)
                },
                child: const Text("Skip & Lose Marks", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return false; // Prevent default skip until confirmed
      },
      onClickTarget: (target) {
        // Continue to next tip when target is clicked
        // Note: This might need adjustment based on specific interaction requirements
      },
      onClickOverlay: (target) {
        // Continue to next tip when overlay is clicked
      },
      // Customizing the skip button
      skipWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Text(
          "Skip Guide",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    ).show(context: context);
  }

  /// Helper to create a standard Jelly Target
  static TargetFocus createTarget({
    required GlobalKey key,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.bottom,
    ShapeLightFocus shape = ShapeLightFocus.RRect,
    double radius = 20,
    Function(TargetFocus)? onFocus, // 🎯 Add onFocus callback
  }) {
    return TargetFocus(
      identify: title,
      keyTarget: key,
      alignSkip: Alignment.topRight,
      shape: shape,
      radius: radius,
      focusAnimationDuration: 600.ms,
      unFocusAnimationDuration: 600.ms,
      paddingFocus: 10,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) {
            // 🎯 Trigger onFocus callback here (Workaround for missing onFocus in TargetFocus)
            if (onFocus != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onFocus(TargetFocus(identify: title, keyTarget: key)); 
              });
            }

            return Animate(
              effects: [
                FadeEffect(duration: 400.ms),
                SlideEffect(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                  curve: Curves.elasticOut,
                  duration: 800.ms,
                ),
              ],
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6750A4), // Primary Purple
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      description,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: const Color(0xFF49454F),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // "Next" Hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Tap to continue",
                          style: GoogleFonts.caveat(
                            fontSize: 16,
                            color: const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.touch_app_rounded,
                          size: 16,
                          color: Color(0xFF9E9E9E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
