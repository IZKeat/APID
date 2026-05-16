import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../widgets/jelly_card.dart';

class PaymentSuccessPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const PaymentSuccessPage({super.key, required this.data});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  @override
  Widget build(BuildContext context) {
    final amount = widget.data['amount'];
    final merchant = widget.data['scan_point_name'] ?? 'Merchant';
    final items = widget.data['items'] as List<dynamic>? ?? [];
    final date = (widget.data['timestamp'] as dynamic)?.toDate() ?? DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFDCFCE7), // Success Green Background
      body: SafeArea(
        child: Stack(
          children: [
            // 🟢 Background Blobs (Optional, keep simple for now)
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Animated Checkmark
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 80,
                      color: Color(0xFF14532D),
                    ),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 1200.ms, color: Colors.greenAccent),

                  const SizedBox(height: 32),

                  // 💰 Amount
                  Text(
                    'RM ${amount?.toStringAsFixed(2) ?? "0.00"}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF14532D),
                      letterSpacing: -1.0,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.5, end: 0, delay: 200.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 8),

                  Text(
                    'Payment Successful',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14532D).withOpacity(0.7),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 48),

                  // 🧾 Receipt Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: JellyCard(
                      color: Colors.white.withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Merchant', style: TextStyle(color: Colors.grey)),
                                Text(merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Date', style: TextStyle(color: Colors.grey)),
                                Text(DateFormat('MMM d, h:mm a').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (items.isNotEmpty) ...[
                              const Divider(height: 32),
                              Container(
                                constraints: const BoxConstraints(maxHeight: 100),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: items.map((item) {
                                      final i = item as Map<String, dynamic>;
                                      final quantity = (i['quantity'] as num?)?.toInt() ?? 1;
                                      final price = (i['price'] as num?)?.toDouble() ?? 0.0;
                                      final name = i['name'] ?? 'Item';
                                      
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${quantity}x $name', style: const TextStyle(fontSize: 12)),
                                            Text('RM ${(price * quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),

                  const Spacer(),

                  // 🔘 Done Button
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14532D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 1.0, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
