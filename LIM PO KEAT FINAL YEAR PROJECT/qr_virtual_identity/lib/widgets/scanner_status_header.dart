// lib/widgets/scanner_status_header.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';
import '../services/scan_point_service.dart';

/// 📊 Scanner Status Header
/// Displays scanner status, user info, and scan point details
/// Redesigned with Jelly aesthetic
class ScannerStatusHeader extends StatelessWidget {
  final bool isScanning;
  final bool isProcessing;
  final ScanPoint? scanPoint;

  const ScannerStatusHeader({
    super.key,
    required this.isScanning,
    required this.isProcessing,
    required this.scanPoint,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final statusColor = isScanning ? JellyTheme.success : JellyTheme.jellyOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: JellyTheme.primary.withOpacity(0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: JellyTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator dot (Pulsing)
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 1.seconds),
          
          const SizedBox(width: 16),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isScanning
                      ? '📱 Camera Active'
                      : '⏳ Waiting for Trigger...',
                  style: JellyTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (user != null)
                  Text(
                    'Logged in as: ${user.email}',
                    style: JellyTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
