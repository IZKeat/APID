
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MobilePaymentScannerPage extends StatefulWidget {
  final Map<String, dynamic> triggerData;

  const MobilePaymentScannerPage({super.key, required this.triggerData});

  @override
  State<MobilePaymentScannerPage> createState() =>
      _MobilePaymentScannerPageState();
}

class _MobilePaymentScannerPageState extends State<MobilePaymentScannerPage> {
  bool processing = false;

  Future<void> processPayment(String uid) async {
    if (processing) return;
    processing = true;

    final db = FirebaseFirestore.instance;

    try {
      // Get user
      final userDoc = await db.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _fail("User not found");
        return;
      }

      final balance = (userDoc['balance'] ?? 0).toDouble();
      
      // 🌟 GUEST LOGIC
      final role = userDoc.data()?['role'] as String? ?? 'unknown';
      double total = (widget.triggerData['totalAmount']).toDouble();
      final originalTotal = total;
      
      if (role == 'guest') {
        total += 1.00;
        print('👤 Guest user detected. Added RM1.00 fee.');
      }

      if (balance < total) {
        await _fail("Insufficient balance");
        return;
      }

      // Deduct balance
      await db.collection('users').doc(uid).update({
        'balance': balance - total,
      });

      // Create interaction
      await db.collection('interactions').add({
        'user_id': uid,
        'user_email': userDoc['email'],
        'scan_point_id': 'SP001',
        'scan_point_name': 'Smokey Café',
        'type': 'purchase',
        'status': 'success',
        'amount': total,
        'currency': 'MYR',
        'payment_method': 'QR Pay',
        'items': widget.triggerData['cartItems'],
        'metadata': {
          'guest_fee_applied': role == 'guest',
          'original_amount': originalTotal,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      // Clear trigger
      await db.collection('scanner_triggers').doc('SP001').update({
        'trigger': false,
        'status': 'payment_success',
        'completed_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Payment Successful"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                Text(
                  'Paid: RM ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (role == 'guest')
                  const Text(
                    '(Incl. RM 1.00 Guest Fee)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close scanner page
                },
                child: const Text("Done"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      await _fail("Payment failed");
    }
  }

  Future<void> _fail(String msg) async {
    processing = false;

    await FirebaseFirestore.instance
        .collection('scanner_triggers')
        .doc('SP001')
        .update({
          'status': 'payment_failed',
          'trigger': false,
          'error_message': msg,
          'failed_at': FieldValue.serverTimestamp(),
        });

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Payment Failed"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 80),
              const SizedBox(height: 16),
              Text(msg),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close scanner page
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = (widget.triggerData['totalAmount'] ?? 0.0).toDouble();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Payment Scanner"),
      ),
      body: Column(
        children: [
          // Payment info
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Payment Request",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: RM ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan your QR code to pay',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          // Scanner
          Expanded(
            child: MobileScanner(
              onDetect: (capture) async {
                if (processing) return;

                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final raw = barcodes.first.rawValue ?? "";
                  if (raw.isNotEmpty) {
                    await processPayment(raw);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
