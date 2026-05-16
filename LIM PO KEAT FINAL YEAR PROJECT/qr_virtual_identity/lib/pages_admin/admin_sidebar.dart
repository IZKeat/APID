// lib/pages_admin/admin_sidebar.dart
import 'package:flutter/material.dart';
import 'package:apid/pages_admin/utils/admin_theme.dart';

/// 🎯 Admin Sidebar Navigation
/// Provides navigation menu for admin dashboard sections
class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigationChanged;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure selectedIndex is within valid range (0-1)
    // Ensure selectedIndex is within valid range (0-3)
    final safeSelectedIndex = selectedIndex.clamp(0, 3);

    return NavigationRail(
      selectedIndex: safeSelectedIndex,
      onDestinationSelected: onNavigationChanged,
      backgroundColor: AdminTheme.backgroundWhite,
      selectedIconTheme: const IconThemeData(
        color: AdminTheme.primaryColor,
        size: 28,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: AdminTheme.primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      unselectedIconTheme: const IconThemeData(
        color: AdminTheme.textSecondary,
        size: 24,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AdminTheme.textSecondary,
        fontSize: 12,
      ),
      labelType: NavigationRailLabelType.all,
      minWidth: 80,
      destinations: const [
        // NavigationRailDestination(
        //   icon: Icon(Icons.dashboard),
        //   selectedIcon: Icon(Icons.dashboard),
        //   label: Text('Overview'),
        // ),
        NavigationRailDestination(
          icon: Icon(Icons.qr_code),
          selectedIcon: Icon(Icons.qr_code),
          label: Text('ScanPoints'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people),
          selectedIcon: Icon(Icons.people),
          label: Text('Users'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.list_alt),
          selectedIcon: Icon(Icons.list_alt),
          label: Text('Logs'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.warning_amber_rounded),
          selectedIcon: Icon(Icons.warning_amber_rounded),
          label: Text('Anomalies'),
        ),
      ],
    );
  }
}
