import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class JellyNotification extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? amount;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const JellyNotification({
    super.key,
    required this.title,
    required this.subtitle,
    this.amount,
    this.icon,
    this.color,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GestureDetector(
            onTap: onTap,
            onVerticalDragEnd: (_) => onDismiss(), // Swipe up to dismiss
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (color ?? Colors.green).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon ?? Icons.check_circle, 
                      color: color ?? Colors.green.shade600, 
                      size: 24
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms),
                  
                  const SizedBox(width: 16),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          amount != null ? '$subtitle • $amount' : subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Chevron
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          )
          .animate()
          .slideY(begin: -2, end: 0, duration: 600.ms, curve: Curves.elasticOut) // Jelly Slide In
          .fadeIn(duration: 400.ms),
        ),
    );
  }
}
