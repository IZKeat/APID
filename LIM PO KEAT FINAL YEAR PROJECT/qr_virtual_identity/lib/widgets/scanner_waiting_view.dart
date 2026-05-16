// lib/widgets/scanner_waiting_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';
import 'package:apid/pages_admin/widgets/jelly_card.dart';
import 'package:apid/pages_admin/widgets/jelly_button.dart';
import '../services/scan_point_service.dart';

/// ⏳ Scanner Waiting View
/// Displayed when scanner is idle, waiting for desktop trigger
/// Redesigned with "Jelly" aesthetic: Youthful, Lively, and Smooth.
class ScannerWaitingView extends StatelessWidget {
  final ScanPoint? scanPoint;
  final VoidCallback? onManualStart; // 🚨 Emergency Manual Start

  const ScannerWaitingView({
    super.key, 
    required this.scanPoint,
    this.onManualStart,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🎨 Animated Background Blobs
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: JellyTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 3.seconds)
           .move(begin: const Offset(0, 0), end: const Offset(20, 20), duration: 4.seconds),
        ),
        Positioned(
          bottom: 100,
          right: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: JellyTheme.secondary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 4.seconds)
           .move(begin: const Offset(0, 0), end: const Offset(-20, -20), duration: 5.seconds),
        ),

        // 📄 Main Content
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🟣 Pulsing Jelly Icon
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: JellyTheme.primary.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            JellyTheme.primary.withOpacity(0.1),
                            JellyTheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 64,
                        color: JellyTheme.primary,
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.5.seconds, curve: Curves.easeInOut)
                .then()
                .shimmer(duration: 2.seconds, delay: 1.seconds, color: JellyTheme.primary.withOpacity(0.3)),

                const SizedBox(height: 40),

                // 📝 Title & Status
                const Text(
                  'Scanner Terminal Ready',
                  style: JellyTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 12),
                
                Text(
                  'Waiting for signal from desktop...\nReady to receive commands.',
                  style: JellyTheme.bodyMedium.copyWith(color: JellyTheme.textSecondary),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 40),

                // ℹ️ Info Card (Jelly Style)
                JellyCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: JellyTheme.info.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.info_rounded, color: JellyTheme.info, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'How it works',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: JellyTheme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStep(1, 'Login to desktop with same account'),
                      _buildStep(2, 'Click "Trigger Mobile Scanner"'),
                      _buildStep(3, 'Camera starts automatically'),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
                
                const SizedBox(height: 40),
                
                // 🔘 Actions
                if (onManualStart != null) ...[
                  JellyButton(
                    text: 'Scan Desktop Login QR',
                    icon: Icons.desktop_windows_rounded,
                    onTap: onManualStart!, 
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  TextButton.icon(
                    onPressed: onManualStart,
                    icon: const Icon(Icons.warning_amber_rounded, size: 18, color: JellyTheme.jellyOrange),
                    label: const Text(
                      "Emergency Manual Start",
                      style: TextStyle(
                        color: JellyTheme.jellyOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: JellyTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: JellyTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: JellyTheme.bodyMedium.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
