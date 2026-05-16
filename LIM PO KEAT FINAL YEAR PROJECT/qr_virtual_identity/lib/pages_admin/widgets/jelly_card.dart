import 'package:flutter/material.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';

/// 🍮 JellyCard
/// A container that behaves like jelly!
/// - Hovers: Floats up slightly with increased shadow.
/// - Taps: Squashes down (scales) with elastic recovery.
class JellyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const JellyCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.width,
    this.height,
  });

  @override
  State<JellyCard> createState() => _JellyCardState();
}

class _JellyCardState extends State<JellyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    // ⚙️ Spring Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Quick squash
      reverseDuration: const Duration(milliseconds: 600), // Bouncy release
    );

    // 📉 Scale from 1.0 to 0.95 (Squash effect)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad, // Smooth squash
        reverseCurve: Curves.elasticOut, // 🏀 BOING! Elastic release
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward(); // Squash
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse(); // Release
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: widget.width,
                height: widget.height,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: widget.color ?? JellyTheme.surface,
                  borderRadius: JellyTheme.cardRadius,
                  boxShadow: _isHovering ? JellyTheme.hoverShadow : JellyTheme.jellyShadow,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}
