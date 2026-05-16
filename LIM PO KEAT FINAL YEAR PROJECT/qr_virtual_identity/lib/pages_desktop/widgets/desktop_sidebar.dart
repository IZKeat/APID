import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopSidebar extends StatefulWidget {
  final String activeView;
  final Function(String) onNavigate;
  final VoidCallback onLogout;
  final String? userEmail;

  const DesktopSidebar({
    super.key,
    required this.activeView,
    required this.onNavigate,
    required this.onLogout,
    this.userEmail,
  });

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  List<_MenuItem> get _menuItems {
    final email = widget.userEmail ?? '';
    if (email.startsWith('sp002')) {
      return [
        _MenuItem(icon: Icons.menu_book_rounded, label: 'Library', view: 'LIBRARY'),
        _MenuItem(icon: Icons.person_rounded, label: 'Profile', view: 'PROFILE'),
      ];
    }
    if (email.startsWith('sp006')) {
      return [
        _MenuItem(icon: Icons.security_rounded, label: 'Access', view: 'ACCESS'),
        _MenuItem(icon: Icons.person_rounded, label: 'Profile', view: 'PROFILE'),
      ];
    }
    if (email.startsWith('sp007')) {
      return [
        _MenuItem(icon: Icons.people_alt_rounded, label: 'Attendance', view: 'ATTENDANCE'),
        _MenuItem(icon: Icons.person_rounded, label: 'Profile', view: 'PROFILE'),
      ];
    }
    // Default POS
    return [
      _MenuItem(icon: Icons.grid_view_rounded, label: 'POS', view: 'POS'),
      _MenuItem(icon: Icons.person_rounded, label: 'Profile', view: 'PROFILE'),
    ];
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    if (confirmed == true) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _menuItems;
    final logoIcon = menuItems.isNotEmpty ? menuItems.first.icon : Icons.store_rounded;

    return Container(
      width: 96, // w-24 (24 * 4 = 96)
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Area
          _AnimatedLogo(icon: logoIcon),
          const SizedBox(height: 40),
          // Navigation Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: menuItems.map((item) {
                  final isActive = widget.activeView == item.view;
                  return _SidebarItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: isActive,
                    onTap: () => widget.onNavigate(item.view),
                  );
                }).toList(),
              ),
            ),
          ),
          // Logout Button
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: _LogoutButton(onTap: _handleLogout),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String view;

  _MenuItem({required this.icon, required this.label, required this.view});
}

class _AnimatedLogo extends StatefulWidget {
  final IconData icon;
  const _AnimatedLogo({required this.icon});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 48,
        height: 48,
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.1 : 1.0)
          ..rotateZ(_isHovered ? 0.26 : 0), // ~15 degrees
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF), // purple-100
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(
          widget.icon,
          color: const Color(0xFF9333EA), // purple-600
          size: 24,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 24),
          width: double.infinity,
          height: 64, // aspect-square roughly
          transform: Matrix4.identity()..scale(_isPressed ? 0.85 : (_isHovered ? 1.05 : 1.0)),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFFF3E8FF) // purple-100
                : (_isHovered ? const Color(0xFFF9FAFB) : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: 22,
                      color: widget.isActive
                          ? const Color(0xFF7E22CE) // purple-700
                          : (_isHovered ? const Color(0xFF9333EA) : Colors.grey.shade400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: widget.isActive
                            ? const Color(0xFF7E22CE)
                            : (_isHovered ? const Color(0xFF9333EA) : Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA855F7), // purple-500
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.9 : (_isHovered ? 1.1 : 1.0))
            ..rotateZ(_isHovered ? 0.08 : 0), // ~5 degrees
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFFEE2E2) : Colors.transparent, // red-100
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.logout_rounded,
            size: 22,
            color: _isHovered ? const Color(0xFFDC2626) : const Color(0xFFF87171), // red-600 : red-400
          ),
        ),
      ),
    );
  }
}
