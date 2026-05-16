import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class JellyInput extends StatefulWidget {
  final String label;
  final IconData icon;
  final Widget? rightIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const JellyInput({
    super.key,
    required this.label,
    required this.icon,
    this.rightIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<JellyInput> createState() => _JellyInputState();
}

class _JellyInputState extends State<JellyInput> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6750A4),
              letterSpacing: 1.0,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
        ),
        AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeOut, // FIX: easeOutBack caused negative blurRadius crash
          transform: Matrix4.diagonal3Values(
              _isFocused ? 1.02 : 1.0, _isFocused ? 1.02 : 1.0, 1.0),
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : const Color(0xFFF3EDF7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isFocused ? const Color(0xFF6750A4) : Colors.transparent,
              width: 2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 16),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF6750A4),
                  size: 20,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  style: const TextStyle(
                    color: Color(0xFF1D192B),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    isDense: true,
                  ),
                ),
              ),
              if (widget.rightIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: widget.rightIcon,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
