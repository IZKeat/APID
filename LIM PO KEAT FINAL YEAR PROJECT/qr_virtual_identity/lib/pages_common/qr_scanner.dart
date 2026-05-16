import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/scanner_service.dart';
import '../widgets/ticket_verification_dialog.dart';
import '../utils/ticket_parser.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  
  bool _isProcessing = false;
  final bool _isPaused = false;
  
  // 🔦 Torch State
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    // Start scanner automatically
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🔍 Unified QR Processing Logic
  Future<void> _processQr(String rawValue) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final scanned = rawValue.trim();
      print("🔍 Scanned: $scanned");

      // 1. 🎫 Ticket Verification (Priority 1)
      final ticket = TicketParser.fromQrData(scanned);
      if (ticket != null) {
        await _processTicketVerification(scanned);
        return;
      }

      // 2. 📅 Event Check-in (Priority 2)
      // Check if it looks like an Event ID (simple alphanumeric or UUID)
      if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(scanned)) {
        await _processEventCheckIn(scanned, user);
        return;
      }

      // 3. ❌ Unknown Format
      throw Exception("Unknown QR Code format");

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Resume scanning after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }



  /// 📅 Process Event Check-in
  Future<void> _processEventCheckIn(String eventId, User user) async {
    // Check if event exists
    final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
    
    if (!eventDoc.exists) {
      // Try searching by field if ID match fails
      final query = await FirebaseFirestore.instance
          .collection('events')
          .where('event_id', isEqualTo: eventId)
          .limit(1)
          .get();
          
      if (query.docs.isEmpty) {
        throw Exception("Event not found");
      }
    }

    // ✅ Check-in Logic
    final eventName = eventDoc.exists 
        ? (eventDoc.data()?['event_name'] ?? 'Event') 
        : 'Event'; // Simplified for query case

    await FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('attendees')
        .doc(user.email)
        .set({
          'checked_in': true,
          'timestamp': FieldValue.serverTimestamp(),
          'email': user.email,
          'user_id': user.uid,
          'method': 'qr_scan',
        });

    if (mounted) {
      await TicketVerificationDialog.showSuccess(
        context: context,
        message: 'Checked in to $eventName!',
        ticketData: {'Event': eventName, 'Time': DateTime.now().toString()},
      );
    }
  }

  /// 🎫 Process Ticket Verification
  Future<void> _processTicketVerification(String qrData) async {
    final result = await ScannerService.verifyTicket(qrData);
    if (mounted) {
      if (result.success) {
        await TicketVerificationDialog.showSuccess(
          context: context,
          message: result.message,
          ticketData: result.data,
        );
      } else {
        await TicketVerificationDialog.showError(
          context: context,
          message: result.message,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 📷 Camera Layer
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _processQr(barcodes.first.rawValue!);
              }
            },
          ),

          // 2. 🌫️ Glassmorphism Overlay
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      _buildGlassButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      
                      // Title
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            color: Colors.black.withOpacity(0.3),
                            child: const Text(
                              "Scan QR Code",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Torch Button
                      _buildGlassButton(
                        icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        onTap: () {
                          _controller.toggleTorch();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                        isActive: _isTorchOn,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 🎯 Scan Frame
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Corner Markers
                        _buildCorner(Alignment.topLeft),
                        _buildCorner(Alignment.topRight),
                        _buildCorner(Alignment.bottomLeft),
                        _buildCorner(Alignment.bottomRight),
                        
                        // Scanning Animation
                        if (!_isProcessing)
                          Center(
                            child: Container(
                              height: 2,
                              width: 260,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD0BCFF), // M3 Primary Light
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD0BCFF).withOpacity(0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                             .slideY(begin: -60, end: 60, duration: 2000.ms, curve: Curves.easeInOut),
                          ),
                          
                        // Processing Indicator
                        if (_isProcessing)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 12),
                                  Text(
                                    "Processing...",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Footer Instructions
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        color: Colors.black.withOpacity(0.3),
                        child: const Text(
                          "Align QR code within the frame",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y == -1 ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: alignment.y == 1 ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: alignment.x == -1 ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: alignment.x == 1 ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
