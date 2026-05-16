import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_animate/flutter_animate.dart';

class JellyToggle extends StatefulWidget {
  final bool isOn;
  final VoidCallback onToggle;

  const JellyToggle({
    super.key,
    required this.isOn,
    required this.onToggle,
  });

  @override
  State<JellyToggle> createState() => _JellyToggleState();
}

class _JellyToggleState extends State<JellyToggle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // 📳 Haptic
        widget.onToggle();
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: 300.ms,
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: widget.isOn ? const Color(0xFF6750A4) : const Color(0xFFE7E0EC),
          borderRadius: BorderRadius.circular(16),
          border: widget.isOn
              ? null
              : Border.all(color: const Color(0xFF79747E)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: 300.ms,
              curve: Curves.easeOutBack,
              alignment: widget.isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: 200.ms,
                width: _isPressed ? 28 : 24, // Squish effect
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isOn ? Colors.white : const Color(0xFF79747E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
