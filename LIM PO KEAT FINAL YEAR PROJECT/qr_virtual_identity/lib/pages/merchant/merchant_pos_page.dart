import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart'; // 🎉 Confetti
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import 'package:apid/controllers/pos_controller.dart';
import 'package:apid/models/cart_item.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:apid/widgets/product_card_jelly.dart';

import 'package:apid/widgets/jelly_notification.dart';

class MerchantPOSPage extends StatefulWidget {
  final String scanPointId;
  const MerchantPOSPage({super.key, required this.scanPointId});

  @override
  State<MerchantPOSPage> createState() => _MerchantPOSPageState();
}

class _MerchantPOSPageState extends State<MerchantPOSPage> {
  late POSController _controller;
  late ConfettiController _confettiController;
  final Map<String, bool> _productToggleState = {};
  TransactionStatus _lastStatus = TransactionStatus.idle;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    final user = FirebaseAuth.instance.currentUser;
    _controller = POSController(
      scanPointId: widget.scanPointId,
      merchantUid: user!.uid,
    );
    _controller.init(); // Initialize data fetching
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (_controller.status != _lastStatus) {
      if (_controller.status == TransactionStatus.success) {
        _confettiController.play();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7), // green-100
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 48),
                  ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Successful!',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Transaction completed.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        
        // Auto close after 3s
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
            _controller.reset(); // Reset to idle
          }
        });
      } else if (_controller.status == TransactionStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage ?? 'Unknown error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _lastStatus = _controller.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Stack(
          children: [
            Row(
              children: [
                // LEFT: Product Area (Flexible)
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF), // purple-100
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.store_rounded, color: Color(0xFF9333EA), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Smokey Café",
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  "POS System • Morning Shift",
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            

                            const SizedBox(width: 16),

                            // Search Bar
                            Container(
                              width: 320,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      onChanged: (value) => _controller.search(value), // Connect Search
                                      decoration: InputDecoration(
                                        hintText: 'Search menu...',
                                        hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category Filter
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Selector<POSController, String>(
                          selector: (_, c) => c.selectedCategory,
                          builder: (context, selectedCategory, _) {
                            return Row(
                              children: [
                                _CategoryChip(
                                  label: 'All', 
                                  isSelected: selectedCategory == 'All',
                                  onTap: () => _controller.setCategory('All'),
                                ),
                                const SizedBox(width: 12),
                                _CategoryChip(
                                  label: 'Rice', 
                                  isSelected: selectedCategory == 'Rice',
                                  onTap: () => _controller.setCategory('Rice'),
                                ),
                                const SizedBox(width: 12),
                                _CategoryChip(
                                  label: 'Noodles', 
                                  isSelected: selectedCategory == 'Noodles',
                                  onTap: () => _controller.setCategory('Noodles'),
                                ),
                                const SizedBox(width: 12),
                                _CategoryChip(
                                  label: 'Drinks', 
                                  isSelected: selectedCategory == 'Drinks',
                                  onTap: () => _controller.setCategory('Drinks'),
                                ),
                                const SizedBox(width: 12),
                                _CategoryChip(
                                  label: 'Western', 
                                  isSelected: selectedCategory == 'Western',
                                  onTap: () => _controller.setCategory('Western'),
                                ),
                                const SizedBox(width: 12),
                                _CategoryChip(
                                  label: 'Snacks', 
                                  isSelected: selectedCategory == 'Snacks',
                                  onTap: () => _controller.setCategory('Snacks'),
                                ),
                              ],
                            );
                          }
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Product Grid
                      Expanded(
                        child: Selector<POSController, List<Map<String, dynamic>>>(
                          selector: (_, c) => c.products,
                          builder: (context, products, _) {
                            if (products.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No items found",
                                      style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[400]),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final productId = product['id'] as String;
                                
                                return Selector<POSController, int>(
                                  selector: (_, c) => c.cart[productId]?.qty ?? 0,
                                  builder: (context, qty, _) {
                                    return ProductCardJelly(
                                      name: product['name'],
                                      price: (product['price'] as num).toDouble(),
                                      imageUrl: null, // Force null to disable image
                                      qty: qty,
                                      onTap: () => _controller.addToCart(productId, product),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT: Floating Cart Sidebar
                Consumer<POSController>(
                  builder: (context, controller, _) {
                    final cart = controller.cart;
                    return Container(
                      width: 400,
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Cart Header
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED), // orange-50
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFEA580C)),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Current Order',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () => _controller.clearCart(),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                  tooltip: 'Clear Cart',
                                ),
                              ],
                            ),
                          ),

                          // Recommendation (Upsell)
                          if (cart.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED), // orange-50
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFF97316), size: 24)
                                      .animate(onPlay: (c) => c.repeat(reverse: true))
                                      .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Recommended",
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF9A3412),
                                          ),
                                        ),
                                        Text(
                                          "Add Drinks to complete meal!", // Static for now
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: const Color(0xFFC2410C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                          // Cart Items List
                          Expanded(
                            child: cart.isEmpty
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[200])
                                          .animate(onPlay: (c) => c.repeat(reverse: true))
                                          .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
                                      const SizedBox(height: 24),
                                      Text(
                                        "Cart is empty",
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    itemCount: cart.length,
                                    itemBuilder: (context, index) {
                                      final item = cart.values.toList()[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            // Image Placeholder
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.fastfood_rounded, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.name,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: const Color(0xFF111827),
                                                    ),
                                                  ),
                                                  Text(
                                                    'RM ${item.price.toStringAsFixed(2)}',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      color: const Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Qty Controls
                                            Row(
                                              children: [
                                                _QtyBtn(
                                                  icon: Icons.remove,
                                                  onTap: () => _controller.updateQuantity(item.productId, -1),
                                                ),
                                                SizedBox(
                                                  width: 24,
                                                  child: Center(
                                                    child: Text(
                                                      '${item.qty}',
                                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                                _QtyBtn(
                                                  icon: Icons.add,
                                                  onTap: () => _controller.updateQuantity(item.productId, 1),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ).animate().fadeIn().slideX(begin: 0.2, end: 0, delay: (50 * index).ms);
                                    },
                                  ),
                          ),

                          // Footer (Total & Pay)
                          Consumer<POSController>(
                            builder: (context, controller, _) {
                              final total = controller.total;
                              final isProcessing = controller.isProcessing;
                              
                              return Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7E22CE).withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, -4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          'RM ${total.toStringAsFixed(2)}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF111827),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 64,
                                      child: ElevatedButton(
                                        onPressed: total > 0 && !isProcessing ? controller.startTransaction : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF111827), // gray-900
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ).copyWith(
                                          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
                                        ),
                                        child: isProcessing
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.qr_code_scanner_rounded, size: 24),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Scan User QR',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ).animate(target: total > 0 ? 1 : 0).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                                  ],
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            // 🎉 Confetti Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),

            // FIX: Restore "Waiting for Scan" Overlay
            // This overlay appears when the transaction is in 'processing' state (waiting for user scan)
            Consumer<POSController>(
              builder: (context, controller, _) {
                if (controller.status != TransactionStatus.processing) return const SizedBox.shrink();

                return Stack(
                  children: [
                    // 1. Blur Effect
                    Positioned.fill(
                      child: BackdropFilter(
                        filter:  ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                    ),

                    // 2. Central Dialog
                    Center(
                      child: Container(
                        width: 400,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated Icon
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF), // blue-50
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Color(0xFF3B82F6), // blue-500
                                size: 48,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms)
                            .then()
                            .shimmer(duration: 2000.ms, color: Colors.blue.withOpacity(0.3)),

                            const SizedBox(height: 24),

                            Text(
                              'Waiting for Scan...',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ask customer to scan the QR code on their mobile app.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: const Color(0xFF6B7280),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Cancel Button
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => controller.cancelTransaction(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: Text(
                                  'Cancel Operation',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF4444), // red-500
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🧠 Smart Upsell Logic (Simple Rule-Based)
  List<String> getUpsellRecommendations() {
    if (_controller.cart.isEmpty) return [];
    
    final cartNames = _controller.cart.values.map((e) => e.name.toLowerCase()).toList();
    final recommendations = <String>[];

    // Rule 1: If buying Rice/Noodles, recommend Drinks
    if (cartNames.any((n) => n.contains('rice') || n.contains('noodle'))) {
       recommendations.add('Drinks'); 
    }
    
    return recommendations;
  }
}



class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CategoryChip({
    required this.label, 
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}



class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 16, color: Colors.grey[600]),
      ),
    );
  }
}
