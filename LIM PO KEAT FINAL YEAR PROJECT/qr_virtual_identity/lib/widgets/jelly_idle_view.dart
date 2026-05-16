import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:apid/widgets/jelly_card.dart';
import '../pages_admin/theme/jelly_theme.dart';

/// 🍬 Jelly Idle View (Camera Overlay Edition)
/// The "Waiting for Scan" screen with Jelly aesthetics.
/// Redesigned to match SP002 (Commerce Scanner) style:
/// - Transparent background to show camera feed
/// - Split layout (Header & Footer cards)
/// - Center clear for camera frame
class JellyIdleView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eventName;
  final String instruction;

  const JellyIdleView({
    super.key,
    required this.title,
    this.subtitle,
    this.eventName,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Top Header Card (Event Info)
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: JellyCard(
            delay: 200.ms,
            color: Colors.white.withOpacity(0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: JellyTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event, color: JellyTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                if (eventName != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    eventName!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: JellyTheme.primary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .shimmer(duration: 2000.ms, color: JellyTheme.primary.withOpacity(0.3)),
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 2. Bottom Status / Instruction Card
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: JellyCard(
            delay: 400.ms,
            color: Colors.black.withOpacity(0.8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20)
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 3000.ms),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        instruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Align Identity QR code within frame',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
