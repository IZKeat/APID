// lib/widgets/ticket_verification_dialog.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 🎫 Ticket Verification Dialog
/// Shows animated success/error feedback for ticket scanning
class TicketVerificationDialog extends StatelessWidget {
  final bool success;
  final String title;
  final String message;
  final Map<String, dynamic>? ticketData;
  final VoidCallback? onClose;

  const TicketVerificationDialog({
    super.key,
    required this.success,
    required this.title,
    required this.message,
    this.ticketData,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation
            _buildAnimation(),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: success
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(green: 0.3)
                    : Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),

            // Ticket details (if successful)
            if (success && ticketData != null) ...[
              const SizedBox(height: 24),
              _buildTicketDetails(context),
            ],

            const SizedBox(height: 32),

            // Action button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onClose?.call();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: success
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(green: 0.3)
                      : Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  success ? 'Continue Scanning' : 'Try Again',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    return Builder(
      builder: (context) {
        if (success) {
          // Success animation
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: _AnimatedCheck(),
          );
        } else {
          // Error animation
          return Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: _AnimatedError(),
          );
        }
      },
    );
  }

  Widget _buildTicketDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            Icons.event,
            'Event',
            ticketData!['event_name'] ?? 'Unknown Event',
            context,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.person,
            'Attendee',
            ticketData!['user_email'] ?? 'Unknown User',
            context,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.access_time,
            'Verified',
            _formatTimestamp(DateTime.now()),
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Show success dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String message,
    Map<String, dynamic>? ticketData,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TicketVerificationDialog(
        success: true,
        title: 'Ticket Verified! ✓',
        message: message,
        ticketData: ticketData,
        onClose: onClose,
      ),
    );
  }

  /// Show error dialog
  static Future<void> showError({
    required BuildContext context,
    required String message,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TicketVerificationDialog(
        success: false,
        title: 'Verification Failed ✗',
        message: message,
        onClose: onClose,
      ),
    );
  }
}

/// Animated check mark for success
class _AnimatedCheck extends StatefulWidget {
  @override
  State<_AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<_AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }
}

/// Animated error icon
class _AnimatedError extends StatefulWidget {
  @override
  State<_AnimatedError> createState() => _AnimatedErrorState();
}

class _AnimatedErrorState extends State<_AnimatedError>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(
              math.sin(_shakeAnimation.value * 3.14159 * 4) * 5,
              0,
            ),
            child: const Icon(Icons.error, size: 60, color: Colors.red),
          ),
        );
      },
    );
  }
}
