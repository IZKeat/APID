import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 🍮 Jelly Card
/// A card widget that animates in with a jelly/bouncy effect.
/// Used for high-impact UI elements like payment confirmation or status updates.
/// Supports both custom [child] or a preset list tile style with [title].
class JellyCard extends StatelessWidget {
  /// Main content of the card.
  /// If [title] is provided, this is displayed BELOW the header.
  /// If [title] is null, this is the sole content of the card.
  final Widget? child;

  /// Alias for [child], used in legacy calls.
  final Widget? content;

  final String? title;
  final String? subtitle;
  final IconData? icon;
  
  final Color? color;
  final Color? backgroundColor; // Alias for color
  final Color? contentColor;
  
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool isVisible;
  
  /// Delay before animation starts.
  /// Accepts [Duration] or [double] (seconds).
  final dynamic delay;
  
  /// Spacing between the header (title/icon) and the [content]/[child].
  final double contentSpacing;

  const JellyCard({
    super.key,
    this.child,
    this.content,
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.backgroundColor,
    this.contentColor,
    this.padding,
    this.onTap,
    this.isVisible = true,
    this.delay,
    this.contentSpacing = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    // 1. Resolve Colors
    final effectiveColor = color ?? backgroundColor ?? Colors.white;
    final effectiveContentColor = contentColor ?? const Color(0xFF1D192B);

    // 2. Resolve Delay
    Duration effectiveDelay = Duration.zero;
    if (delay is Duration) {
      effectiveDelay = delay;
    } else if (delay is num) {
      effectiveDelay = Duration(milliseconds: (delay * 1000).round());
    }

    // 3. Resolve Content
    final effectiveBody = content ?? child;

    // 4. Build Layout
    Widget cardContent;

    if (title != null || subtitle != null || icon != null) {
      // HEADER MODE (Title + Optional Content)
      cardContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: effectiveContentColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: effectiveContentColor, size: 24),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: effectiveContentColor,
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: effectiveContentColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null && effectiveBody == null)
                Icon(Icons.chevron_right, color: effectiveContentColor.withOpacity(0.3)),
            ],
          ),
          
          // Add body content if present
          if (effectiveBody != null) ...[
            SizedBox(height: contentSpacing),
            effectiveBody,
          ],
        ],
      );
    } else {
      // SIMPLE MODE (Just Content)
      cardContent = effectiveBody ?? const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: cardContent,
      )
      .animate()
      .scale(
        duration: 600.ms,
        curve: Curves.elasticOut,
        begin: const Offset(0.8, 0.8),
        end: const Offset(1, 1),
        delay: effectiveDelay,
      )
      .fadeIn(duration: 400.ms),
    );
  }
}
