import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<CustomBottomNavigationItem> items;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 88, // Matches React h-[88px]
          padding: const EdgeInsets.only(top: 8, bottom: 20), // pb-safe pt-2
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9), // bg-white/90
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade100, // border-gray-100
                width: 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Sliding Pill Background
              AnimatedAlign(
                alignment: Alignment(
                  -1.0 + (2.0 * currentIndex / (items.length - 1)),
                  -0.8, // Adjust vertical alignment to be near top
                ),
                duration: 500.ms,
                curve: Curves.easeOutBack, // Spring-like feel
                child: FractionallySizedBox(
                  widthFactor: 1 / items.length,
                  child: Center(
                    child: Container(
                      width: 64, // w-16
                      height: 32, // h-8
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8DEF8), // M3 Surface Container High
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation Items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = currentIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      key: item.key, // 🗝️ Assign Key
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon Container
                          SizedBox(
                            height: 32,
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 1.0,
                                  end: isActive ? 1.1 : 1.0,
                                ),
                                duration: 200.ms,
                                curve: Curves.easeOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Icon(
                                      isActive ? item.selectedIcon : item.icon,
                                      size: 24,
                                      color: isActive
                                          ? const Color(0xFF1D192B)
                                          : const Color(0xFF49454F),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Label
                          AnimatedDefaultTextStyle(
                            duration: 200.ms,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: isActive
                                  ? const Color(0xFF1D192B)
                                  : const Color(0xFF49454F),
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomBottomNavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final GlobalKey? key; // 🗝️ Key for Guide

  const CustomBottomNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.key,
  });
}
