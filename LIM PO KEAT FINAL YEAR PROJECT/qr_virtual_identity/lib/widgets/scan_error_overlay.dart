import 'dart:async';
import 'package:flutter/material.dart';
import 'package:apid/theme/app_theme.dart';

/// ❌ Scan Error Overlay
/// A unified, full-screen, animated overlay for displaying scan errors.
/// Automatically dismisses after a set duration.
class ScanErrorOverlay extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onDismiss;
  final Duration duration;

  const ScanErrorOverlay({
    super.key,
    this.title = 'Scan Failed',
    this.subtitle,
    required this.onDismiss,
    this.duration = const Duration(seconds: 3), // Slightly longer for errors to be readable
  });

  @override
  State<ScanErrorOverlay> createState() => _ScanErrorOverlayState();
}

class _ScanErrorOverlayState extends State<ScanErrorOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto-dismiss timer
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _startDismissal();
      }
    });
  }

  void _startDismissal() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: GestureDetector(
        onTap: _startDismissal, // Allow tap to dismiss early
        child: Container(
          // Adaptive background color
          color: isDark
              ? Colors.red.shade900.withOpacity(0.95)
              : AppTheme.errorColor.withOpacity(0.9),
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Error Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.backgroundSurfaceDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.shadowStrong,
                    ),
                    child: Icon(
                      Icons.error_rounded,
                      size: 64,
                      color: isDark ? Colors.redAccent : AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 16),
                    // Subtitle (Error Message)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Dismiss Hint
                  Text(
                    'Tap to dismiss',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
