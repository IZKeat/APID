import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ProductCardJelly extends StatefulWidget {
  final String name;
  final double price;
  final String? imageUrl; // Changed from IconData to String? imageUrl
  final int qty;
  final VoidCallback onTap;

  const ProductCardJelly({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    required this.qty,
    required this.onTap,
  });

  @override
  State<ProductCardJelly> createState() => _ProductCardJellyState();
}

class _ProductCardJellyState extends State<ProductCardJelly> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // 🍮 Jelly Physics: Overshoot curve for bouncy feel
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) => _controller.forward();
  void _handleTapUp(_) {
    _controller.reverse();
    widget.onTap();
  }
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * (_isHovered ? 1.02 : 1.0),
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7E22CE).withOpacity(_isHovered ? 0.15 : 0.05),
                  blurRadius: _isHovered ? 24 : 12,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image / Icon Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isHovered ? const Color(0xFFF3E8FF) : const Color(0xFFF3F4F6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: CachedNetworkImage(
                              imageUrl: widget.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  color: Colors.white,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF3F4F6),
                                child: Icon(
                                  Icons.fastfood_rounded,
                                  size: 48,
                                  color: const Color(0xFF9CA3AF).withOpacity(0.5),
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.fastfood_rounded,
                            size: 48,
                            color: _isHovered 
                                ? const Color(0xFF9333EA) 
                                : const Color(0xFF9CA3AF).withOpacity(0.5),
                          ),
                  ),
                ),
                
                // Content Area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit( // Youthful font
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'RM ${widget.price.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7E22CE),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Add Button / Qty Indicator
                      if (widget.qty > 0)
                        _buildQtyBadge()
                      else
                        _buildAddButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Color(0xFF7E22CE), size: 20),
    );
  }

  Widget _buildQtyBadge() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFF7E22CE),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${widget.qty}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
