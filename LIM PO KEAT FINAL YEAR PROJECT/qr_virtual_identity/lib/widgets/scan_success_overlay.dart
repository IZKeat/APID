import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:apid/theme/app_theme.dart';

/// A reusable success overlay for scanner strategies.
///
/// Features:
/// - Semi-transparent green background (Adaptive)
/// - Animated checkmark (ScaleTransition)
/// - Title and Subtitle (Scan Point Name + Timestamp)
/// - Auto fade-out/dismiss callback
class ScanSuccessOverlay extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? scanPointName;
  final VoidCallback? onDismiss;
  final Duration duration;

  const ScanSuccessOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.scanPointName,
    this.onDismiss,
    this.duration = const Duration(seconds: 2, milliseconds: 500),
  });

  @override
  State<ScanSuccessOverlay> createState() => _ScanSuccessOverlayState();
}

class _ScanSuccessOverlayState extends State<ScanSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Animation for the checkmark pop-in
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();

    // Auto-dismiss timer
    _timer = Timer(widget.duration, () {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('h:mm a').format(DateTime.now());
    final dateString = DateFormat('MMM d, yyyy').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Container(
        // Adaptive background color
        color: isDark
            ? Colors.green.shade900.withOpacity(0.95)
            : AppTheme.successColor.withOpacity(0.92),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Checkmark
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.backgroundSurfaceDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.shadowStrong,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 80,
                      color: isDark ? Colors.greenAccent : AppTheme.successColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                // Subtitle (Custom or Default)
                if (widget.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      widget.subtitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Footer Info (Scan Point + Time)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (widget.scanPointName != null) ...[
                        Text(
                          widget.scanPointName!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        '$dateString • $timeString',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
