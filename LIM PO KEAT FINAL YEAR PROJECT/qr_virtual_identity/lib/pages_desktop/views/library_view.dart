import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LibraryView extends StatelessWidget {
  final VoidCallback onTriggerBorrow;
  final VoidCallback onTriggerReturn;
  final bool isTriggered;
  final bool isProcessing;
  final VoidCallback onStop;

  const LibraryView({
    super.key,
    required this.onTriggerBorrow,
    required this.onTriggerReturn,
    required this.isTriggered,
    required this.isProcessing,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              // Header Section
              _buildHeader(),
              const SizedBox(height: 48),
              
              // Operations Buttons
              _buildOperations(context),
              const SizedBox(height: 48),

              // Instructions
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated Icon Placeholder (Static for now, can add animation later)
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.indigo],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        Text(
          'Mobile QR Scanner',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827), // gray-900
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Trigger your mobile device to open the QR scanner',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280), // gray-500
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // blue-50
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDBEAFE)), // blue-100
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_rounded, size: 18, color: Color(0xFF2563EB)), // blue-600
              const SizedBox(width: 12),
              Text.rich(
                TextSpan(
                  text: 'Logged in as: ',
                  style: GoogleFonts.inter(color: const Color(0xFF1E40AF)), // blue-800
                  children: [
                    TextSpan(
                      text: 'sp002@apu.edu.my',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperations(BuildContext context) {
    if (isTriggered) {
       return Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 📡 Radar Pulse Animation
            SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse 1
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(duration: 2.seconds)
                      .fadeOut(duration: 2.seconds),

                  // Pulse 2
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  )
                      .animate(
                        delay: 1.seconds,
                        onPlay: (controller) => controller.repeat(),
                      )
                      .scale(duration: 2.seconds)
                      .fadeOut(duration: 2.seconds),

                  // Center Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // blue-50
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sensors_rounded,
                      color: Color(0xFF2563EB), // blue-600
                      size: 40,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        duration: 1.seconds,
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.1, 1.1),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Waiting for Mobile Scan...',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2.seconds, color: const Color(0xFF93C5FD)),
            const SizedBox(height: 8),
            Text(
              'Check your phone to scan.',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop Scanner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
       );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
      child: Column(
        children: [
          Text(
            'Library Operations',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937), // gray-800
            ),
          ),
          const SizedBox(height: 24),
          // Borrow Button
          _OperationButton(
            title: 'Borrow Mode',
            subtitle: 'Student + Book',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF10B981), // emerald-500
            shadowColor: const Color(0xFFA7F3D0), // emerald-200
            borderColor: const Color(0xFF047857), // emerald-700
            onTap: onTriggerBorrow,
          ),
          const SizedBox(height: 24),
          // Return Button
          _OperationButton(
            title: 'Return Mode',
            subtitle: 'Book Only',
            icon: Icons.rotate_left_rounded,
            color: const Color(0xFF0EA5E9), // sky-500
            shadowColor: const Color(0xFFBAE6FD), // sky-200
            borderColor: const Color(0xFF0369A1), // sky-700
            onTap: onTriggerReturn,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 672),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // amber-50
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFFEF3C7)), // amber-100
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // amber-100
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706)), // amber-600
              ),
              const SizedBox(width: 12),
              Text(
                'How to Use',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF78350F), // amber-900
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InstructionStep(number: 1, text: 'Open your mobile app (Android/iOS)'),
          _InstructionStep(number: 2, text: 'Login with the SAME merchant account'),
          _InstructionStep(number: 3, text: 'Mobile will show QR Scanner page'),
          _InstructionStep(number: 4, text: 'Click "Trigger" button above'),
        ],
      ),
    );
  }
}

class _OperationButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _OperationButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.shadowColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_OperationButton> createState() => _OperationButtonState();
}

class _OperationButtonState extends State<_OperationButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0)),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border(
              bottom: BorderSide(
                color: widget.borderColor,
                width: _isPressed ? 0 : 4,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1), // indigo-500
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151), // gray-700
            ),
          ),
        ],
      ),
    );
  }
}
