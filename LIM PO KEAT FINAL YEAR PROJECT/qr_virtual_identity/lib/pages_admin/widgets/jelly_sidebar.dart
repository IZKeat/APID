import 'package:flutter/material.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';

/// 🧊 JellySidebar
/// Navigation rail with animated background pill for selected item.
class JellySidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigationChanged;

  const JellySidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🏷️ Logo / Brand
          const Padding(
            padding: EdgeInsets.only(bottom: 40, left: 12),
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: JellyTheme.primary, size: 32),
                SizedBox(width: 12),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: JellyTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // 🧭 Navigation Items
          _buildNavItem(0, 'Scan Points', Icons.qr_code_scanner_rounded),
          _buildNavItem(1, 'Users', Icons.people_alt_rounded),
          _buildNavItem(2, 'Audit Logs', Icons.assignment_rounded),
          _buildNavItem(3, 'Anomalies', Icons.warning_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onNavigationChanged(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack, // 🏎️ Smooth entry
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? JellyTheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // 🎨 Animated Icon Color
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? JellyTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : JellyTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // 📝 Text
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? JellyTheme.primary : JellyTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
