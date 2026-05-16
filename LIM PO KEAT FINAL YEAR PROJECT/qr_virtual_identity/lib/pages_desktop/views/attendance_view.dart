import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceView extends StatefulWidget {
  final String organizerName;
  final Function(String? eventId, String? eventName) onTriggerAttendance;
  final bool isTriggered;
  final bool isProcessing;
  final VoidCallback onStop;

  const AttendanceView({
    super.key,
    required this.organizerName,
    required this.onTriggerAttendance,
    required this.isTriggered,
    required this.isProcessing,
    required this.onStop,
  });

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  String? _selectedEventId;
  String? _selectedEventName;

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

              // Event Selector
              _buildEventSelector(),
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
        // Animated Icon Placeholder
        widget.isTriggered
            ? const _RadarPulse()
            : Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white, size: 48),
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
                      text: 'sp007@apu.edu.my',
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

  Widget _buildEventSelector() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 672),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Event for Attendance',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                // .where('organizer', isEqualTo: widget.organizerName) // 🔓 UNLOCKED FOR DEMO: Show all events
                .where('is_active', isEqualTo: true)
                .orderBy('date') // Sort by date
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error loading events: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }

              final events = snapshot.data!.docs;

              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No active events found.',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                initialValue: _selectedEventId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2), // violet-500
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: const Icon(Icons.event_rounded, color: Color(0xFF8B5CF6)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: events.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] as String? ?? 'Unnamed Event';
                  final date = data['date'] as String? ?? '';
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      '$name ($date)',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(),
                    ),
                  );
                }).toList(),
                onChanged: widget.isTriggered
                    ? null // Disable change while scanning
                    : (value) {
                        setState(() {
                          _selectedEventId = value;
                          if (value != null) {
                            final match = events.firstWhere(
                              (doc) => doc.id == value,
                            );
                            final data = match.data() as Map<String, dynamic>;
                            _selectedEventName =
                                data['name'] as String? ?? 'Unnamed Event';
                          } else {
                            _selectedEventName = null;
                          }
                        });
                      },
                hint: Text('Select an event to start...', style: GoogleFonts.inter()),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOperations(BuildContext context) {
    if (widget.isTriggered) {
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
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Scanner Active on Mobile',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your phone to scan.',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: widget.onStop,
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
            'Attendance Operations',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937), // gray-800
            ),
          ),
          const SizedBox(height: 24),
          // Attendance Button
          _OperationButton(
            title: 'Start Attendance Mode',
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF8B5CF6), // violet-500
            shadowColor: const Color(0xFFDDD6FE), // violet-200
            borderColor: const Color(0xFF6D28D9), // violet-700
            onTap: () {
              if (_selectedEventId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select an event first'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              widget.onTriggerAttendance(_selectedEventId, _selectedEventName);
            },
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
          _InstructionStep(number: 1, text: 'Select an event from the dropdown above'),
          _InstructionStep(number: 2, text: 'Click "Start Attendance Mode"'),
          _InstructionStep(number: 3, text: 'Mobile scanner will activate automatically'),
          _InstructionStep(number: 4, text: 'Scan student IDs to mark attendance'),
        ],
      ),
    );
  }
}

class _OperationButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _OperationButton({
    required this.title,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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

class _RadarPulse extends StatefulWidget {
  const _RadarPulse();

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse 1
          _buildPulse(0),
          // Pulse 2
          _buildPulse(0.5),
          // Center Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)], // violet to pink
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.wifi_tethering_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulse(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value + delay) % 1.0;
        return Opacity(
          opacity: (1.0 - value) * 0.6, // Fade out
          child: Transform.scale(
            scale: 1.0 + (value * 1.5), // Expand to 2.5x
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFEC4899).withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
