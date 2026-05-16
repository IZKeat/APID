// lib/pages_admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apid/pages_admin/widgets/jelly_sidebar.dart';
import 'package:apid/pages_admin/components/scanpoints_page.dart';
import 'package:apid/pages_admin/components/users_page.dart';
import 'package:apid/pages_admin/utils/admin_guard.dart';
import 'package:apid/pages_admin/theme/jelly_theme.dart';
import 'package:apid/pages_admin/components/audit_logs_page.dart';
import 'package:apid/pages_admin/components/anomalies_page.dart';

/// 🎛️ Admin Dashboard Main Page
/// Container for admin navigation and component pages
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedPage = 0;
  bool _isLoading = true;

  final List<Widget> _pages = [
    const ScanPointsPage(),
    const UsersPage(),
    const AuditLogsPage(),
    const AnomaliesPage(),
  ];

  final List<String> _pageTitles = [
    '🎯 Scan Points Management',
    '👥 Users Management',
    '📋 Audit Logs',
    '⚠️ Security Anomalies',
  ];

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }

  Future<void> _verifyAdminAccess() async {
    final hasAccess = await AdminGuard.verifyAccess(context);
    if (!hasAccess && mounted) {
      return; // Already redirected to login
    }
    setState(() => _isLoading = false);
  }

  void _onNavigationChanged(int index) {
    setState(() => _selectedPage = index);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚪 Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: JellyTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AdminGuard.logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: JellyTheme.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: JellyTheme.background,
      body: Row(
        children: [
          // 🧊 Jelly Sidebar
          JellySidebar(
            selectedIndex: _selectedPage,
            onNavigationChanged: _onNavigationChanged,
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // 🎩 Top Bar (Header)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      // Page Title
                      Text(
                        _pageTitles[_selectedPage],
                        style: JellyTheme.displayLarge.copyWith(fontSize: 28),
                      ),
                      const Spacer(),
                      
                      // Admin Profile & Logout
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: JellyTheme.jellyShadow,
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: JellyTheme.primary,
                              child: Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              user?.email ?? 'Admin',
                              style: JellyTheme.bodyMedium,
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: JellyTheme.error),
                              tooltip: 'Logout',
                              onPressed: _handleLogout,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 📄 Page Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: _pages[_selectedPage],
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
}
