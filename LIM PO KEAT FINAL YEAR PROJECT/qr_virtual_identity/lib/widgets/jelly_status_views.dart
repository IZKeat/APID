import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../pages_admin/theme/jelly_theme.dart';

/// 🍬 Jelly Processing View
/// A glassmorphism overlay with bouncing dots and pulsing background.
class JellyProcessingView extends StatelessWidget {
  const JellyProcessingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Glassmorphism Blur Background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: JellyTheme.primary.withOpacity(0.2), // Tinted overlay
          ),
        ),

        // 2. Center Content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔴 Bouncing Dots Animation
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(0),
                  const SizedBox(width: 12),
                  _buildDot(200), // Delay 200ms
                  const SizedBox(width: 12),
                  _buildDot(400), // Delay 400ms
                ],
              ),
              const SizedBox(height: 32),
              
              // 📝 Text with Fade
              Text(
                "Processing...",
                style: JellyTheme.headlineMedium.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: JellyTheme.primary.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .fadeIn(duration: 600.ms)
               .then()
               .fadeOut(duration: 600.ms, delay: 1000.ms),
               
              const SizedBox(height: 8),
              Text(
                "Verifying secure data",
                style: JellyTheme.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int delayMs) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: JellyTheme.secondary, // Lime Green
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
    ).animate(onPlay: (c) => c.repeat())
     .moveY(
       begin: 0, 
       end: -20, 
       duration: 500.ms, 
       curve: Curves.easeOutQuad, // Jump up
       delay: Duration(milliseconds: delayMs)
     )
     .then()
     .moveY(
       begin: -20, 
       end: 0, 
       duration: 500.ms, 
       curve: Curves.bounceOut // Bounce down
     );
  }
}

/// 🎉 Jelly Success View
/// Full screen success card with elastic pop-in animation.
class JellySuccessView extends StatelessWidget {
  final String message;
  final Map<String, dynamic>? data;
  final VoidCallback onDone;

  const JellySuccessView({
    super.key,
    required this.message,
    this.data,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JellyTheme.background,
      body: Stack(
        children: [
          // Background Blobs (Optional decoration)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: JellyTheme.secondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut).fade(),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Success Icon with Elastic Pop
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: JellyTheme.jellyShadow,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 64,
                      color: JellyTheme.success,
                    ),
                  ).animate()
                   .scale(
                     duration: 800.ms, 
                     curve: Curves.elasticOut, // 🟢 Jelly Pop
                     begin: const Offset(0, 0),
                     end: const Offset(1, 1),
                   ),

                  const SizedBox(height: 32),

                  // 📝 Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: JellyTheme.headlineMedium.copyWith(
                      color: JellyTheme.primary,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, end: 0),

                  if (data != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: JellyTheme.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: data!.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${e.key}: ", 
                                style: JellyTheme.labelSmall.copyWith(color: JellyTheme.textSecondary)
                              ),
                              Text(
                                "${e.value}", 
                                style: JellyTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ],

                  const SizedBox(height: 48),

                  // 🔘 Done Button with Squash & Stretch
                  _JellyButton(
                    text: "Done",
                    onPressed: onDone,
                    color: JellyTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ⚠️ Jelly Error View
/// Full screen error with shake animation.
class JellyErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback? onBack;

  const JellyErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JellyTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ❌ Error Icon with Shake
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: JellyTheme.error.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: JellyTheme.error,
                ),
              ).animate()
               .shake(duration: 600.ms, hz: 4, curve: Curves.easeInOut), // 🔴 Shake

              const SizedBox(height: 32),

              Text(
                "Oops!",
                style: JellyTheme.headlineMedium.copyWith(color: JellyTheme.error),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: JellyTheme.bodyMedium.copyWith(color: JellyTheme.textSecondary),
              ),

              const SizedBox(height: 48),

              // 🔘 Retry Button
              _JellyButton(
                text: "Try Again",
                onPressed: onRetry,
                color: JellyTheme.primary, // Use primary for action
              ),
              
              if (onBack != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onBack,
                  child: Text(
                    "Back to Home",
                    style: JellyTheme.labelSmall.copyWith(fontSize: 14),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔘 Internal Jelly Button
/// Implements Squash & Stretch on press.
class _JellyButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const _JellyButton({
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_JellyButton> createState() => _JellyButtonState();
}

class _JellyButtonState extends State<_JellyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Fast squash
      reverseDuration: const Duration(milliseconds: 600), // Slow elastic rebound
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward(); // Squash
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse(from: 0.9); // Elastic rebound
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(50), // Stadium
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
