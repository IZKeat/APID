import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';
import 'package:apid/pages_admin/widgets/jelly_card.dart';

class MerchantMobilePaymentScannerPage extends StatefulWidget {
  final DocumentReference triggerRef;
  final Map<String, dynamic> triggerData;

  const MerchantMobilePaymentScannerPage({
    super.key,
    required this.triggerRef,
    required this.triggerData,
  });

  @override
  State<MerchantMobilePaymentScannerPage> createState() =>
      _MerchantMobilePaymentScannerPageState();
}

class _MerchantMobilePaymentScannerPageState
    extends State<MerchantMobilePaymentScannerPage> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processPayment(String uid) async {
    final db = FirebaseFirestore.instance;
    final totalAmount =
        (widget.triggerData['total_amount'] as num?)?.toDouble() ?? 0.0;
    final cartItems = Map<String, dynamic>.from(
      widget.triggerData['cart_items'] ?? {},
    );

    try {
      final userDoc = await db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        await widget.triggerRef.update({
          'status': 'payment_failed',
          'trigger': false,
          'error_message': 'User not found',
        });
        _showJellyDialog(
            isError: true, title: 'User Unknown', message: 'User ID not found.');
        return;
      }

      final userData = userDoc.data()!;
      // 🟢 LOGIC CHECK: Using 'balance' as valid source of truth
      final balance = (userData['wallet_balance'] as num?)?.toDouble() ?? 0.0;
      
      // 🌟 GUEST LOGIC
      final role = userData['role'] as String? ?? 'unknown';
      double finalAmount = totalAmount;
      String guestNote = '';

      if (role == 'guest') {
        finalAmount += 1.00;
        guestNote = ' (+RM1.00 Guest Fee)';
      }

      if (balance < finalAmount) {
        await widget.triggerRef.update({
          'status': 'payment_failed',
          'trigger': false,
          'error_message': 'Insufficient balance',
        });
        _showJellyDialog(
          isError: true,
          title: 'Insufficient Funds',
          message: 'User balance: RM ${balance.toStringAsFixed(2)}\nRequired: RM ${finalAmount.toStringAsFixed(2)}',
        );
        return;
      }

      // 1. Deduct balance (Source of Truth: 'balance')
      await db.collection('users').doc(uid).update({
        'wallet_balance': balance - finalAmount,
      });

      // 2. Create interaction record
      await db.collection('interactions').add({
        'user_id': uid,
        'user_email': userData['email'],
        'scan_point_id': widget.triggerData['scan_point_id'] ?? 'SP001',
        'scan_point_name': 'Smokey Café',
        'type': 'purchase',
        'status': 'success',
        'amount': finalAmount,
        'items': cartItems,
        'metadata': {
          'guest_fee_applied': role == 'guest',
          'original_amount': totalAmount,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      // 3. Update trigger for desktop
      await widget.triggerRef.update({
        'status': 'payment_success',
        'trigger': false,
        'completed_at': FieldValue.serverTimestamp(),
        'last_result': {
          'user_id': uid,
          'user_email': userData['email'],
          'amount': finalAmount,
          'guest_fee_applied': role == 'guest',
        },
      });

      if (mounted) {
        _showJellyDialog(
          isError: false,
          title: 'Payment Success!',
          message: 'RM ${finalAmount.toStringAsFixed(2)} collected from\n${userData['email'] ?? 'User'}$guestNote',
          onClose: () {
            Navigator.pop(context); // Close Dialog
            Navigator.pop(context); // Close Page
          },
        );
      }
    } catch (e) {
      await widget.triggerRef.update({
        'status': 'payment_failed',
        'trigger': false,
        'error_message': 'Payment error: $e',
      });
      _showJellyDialog(isError: true, title: 'System Error', message: e.toString());
    }
  }

  void _showJellyDialog({
    required bool isError,
    required String title,
    required String message,
    VoidCallback? onClose,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: JellyCard(
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with Pulse
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isError ? JellyTheme.error : JellyTheme.success).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_rounded : Icons.check_circle_rounded,
                  color: isError ? JellyTheme.error : JellyTheme.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                title,
                style: JellyTheme.titleLarge.copyWith(
                  color: isError ? JellyTheme.error : JellyTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: JellyTheme.bodyMedium.copyWith(color: JellyTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: onClose ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? JellyTheme.error : JellyTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text('Okay'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = (widget.triggerData['total_amount'] ?? 0.0).toDouble();

    return Scaffold(
      backgroundColor: JellyTheme.background,
      body: Stack(
        children: [
          Column(
            children: [
              // 🟣 Header Area
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [JellyTheme.primary, JellyTheme.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: JellyTheme.jellyShadow,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Collect Payment",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 💰 Amount Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          'RM ${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 📷 Scanner Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        MobileScanner(
                          onDetect: (BarcodeCapture capture) async {
                            if (_isProcessing) return;
                            setState(() => _isProcessing = true);
                            
                            final barcodes = capture.barcodes;
                            if (barcodes.isEmpty) {
                              setState(() => _isProcessing = false);
                              return;
                            }
                            final raw = barcodes.first.rawValue ?? '';
                            if (raw.isEmpty) {
                              setState(() => _isProcessing = false);
                              return;
                            }

                            await _processPayment(raw);
                          },
                        ),
                        
                        // Scanner Overlay Guide
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        
                        // Pulse Animation for User Focus
                        Center(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: JellyTheme.secondary.withOpacity(1.0 - _pulseController.value),
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🔙 Back Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: JellyTheme.textSecondary),
                  label: const Text('Cancel Payment', style: TextStyle(color: JellyTheme.textSecondary)),
                ),
              ),
            ],
          ),

          // 🌀 Processing Overlay
          if (_isProcessing)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.white.withOpacity(0.5),
                child: Center(
                  child: JellyCard(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: JellyTheme.primary),
                        const SizedBox(height: 20),
                        Text(
                          'Processing...',
                          style: JellyTheme.titleLarge.copyWith(color: JellyTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
