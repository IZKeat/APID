import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as android_ui; // Use consistent alias
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/jelly_card.dart';
import '../widgets/jelly_toggle.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../services/user_service.dart'; // Import UserService
import '../pages_common/password_reauth_page.dart';
import '../widgets/change_password_dialog.dart';
import '../pages_common/privacy_policy_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Local state for UI toggles (mocking persistence for now)
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _darkMode = false;
  bool _biometricEnabled = false;
  bool _canCheckBiometrics = false;
  bool _isGuest = false; // 🆕 Track if user is guest

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bioEnabled = await StorageService().isBiometricEnabled();
    final canCheck = await BiometricService().canCheckBiometrics();
    final push = await StorageService().isPushEnabled();
    final email = await StorageService().isEmailEnabled();
    final dark = await StorageService().isDarkMode();

    // 🕵️‍♂️ Check User Role (Security)
    final user = FirebaseAuth.instance.currentUser;
    bool isGuest = false;
    if (user != null) {
      final doc = await UserService.getUserProfile(user.uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        isGuest = (data['role'] == 'guest');
      }
    }

    if (mounted) {
      setState(() {
        _biometricEnabled = bioEnabled;
        _canCheckBiometrics = canCheck;
        _pushEnabled = push;
        _emailEnabled = email;
        _darkMode = dark;
        _isGuest = isGuest;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // 🔒 Enable Flow: Must Re-auth first
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const PasswordReauthPage()),
      );

      if (!mounted) return;
      if (success == true) {
        await StorageService().setBiometricEnabled(true);
        setState(() => _biometricEnabled = true);
      }
    } else {
      // 🔓 Disable Flow: Just turn it off
      await StorageService().setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _togglePush(bool value) async {
    await StorageService().setPushEnabled(value);
    setState(() => _pushEnabled = value);
  }

  Future<void> _toggleEmail(bool value) async {
    await StorageService().setEmailEnabled(value);
    setState(() => _emailEnabled = value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    await StorageService().setDarkMode(value);
    setState(() => _darkMode = value);
    // Note: Real dark mode switching would require a ThemeProvider or similar.
    // For now, we just persist the preference.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF),
      body: Stack(
        children: [
          // 📄 Main Content (Scrollable)
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // 🏀 Bouncy Scroll
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80, // Space for header
              left: 24,
              right: 24,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notifications Section
                _buildSectionHeader('NOTIFICATIONS', delay: 0),
                JellyCard(
                  title: '',
                  backgroundColor: Colors.white,
                  contentColor: const Color(0xFF1D192B),
                  content: Column(
                    children: [
                      _buildSettingRow(
                        icon: Icons.smartphone_rounded,
                        label: 'Push Notifications',
                        subLabel: 'Events & Security alerts',
                        control: JellyToggle(
                          isOn: _pushEnabled,
                          onToggle: () => _togglePush(!_pushEnabled),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                // Appearance Section
                _buildSectionHeader('APPEARANCE', delay: 1),
                JellyCard(
                  title: '',
                  backgroundColor: Colors.white,
                  contentColor: const Color(0xFF1D192B),
                  content: _buildSettingRow(
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark Mode',
                    subLabel: 'Reduce eye strain',
                    control: JellyToggle(
                      isOn: _darkMode,
                      onToggle: () => _toggleDarkMode(!_darkMode),
                    ),
                  ),
                ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                // Security Section
                _buildSectionHeader('SECURITY', delay: 2),
                JellyCard(
                  title: '',
                  backgroundColor: Colors.white,
                  contentColor: const Color(0xFF1D192B),
                  content: Column(
                    children: [
                      _buildActionRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        onTap: _handleChangePassword,
                      ),
                      const Divider(height: 1),
                      _buildActionRow(
                        icon: Icons.shield_outlined,
                        label: 'Privacy Policy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                // Biometric Section (Secure)
                if (!_isGuest) ...[
                   if (_canCheckBiometrics) ...[
                    _buildSectionHeader('BIOMETRICS', delay: 3),
                    JellyCard(
                      title: '',
                      backgroundColor: Colors.white,
                      contentColor: const Color(0xFF1D192B),
                      content: _buildSettingRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Biometric Login',
                        subLabel: 'FaceID / Fingerprint',
                        control: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_biometricEnabled)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                               .scale(duration: 800.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
                            
                            JellyToggle(
                              isOn: _biometricEnabled,
                              onToggle: () => _toggleBiometric(!_biometricEnabled),
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.elasticOut),
                  ],
                ],

                const SizedBox(height: 48),

                // 🕵️‍♂️ Guest Indicators or Footer
                if (_isGuest)
                  _buildGuestIndicator().animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0)
                else
                  const Center(
                    child: Text(
                      'Account ID: 9942-XJ-22',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  
                const SizedBox(height: 40),
              ],
            ),
          ),

          // 🧊 Sticky Glass Header
          ClipRect(
            child: BackdropFilter(
              filter: android_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 24,
                  right: 24,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7), // Semi-transparent
                  border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 24, // Larger title
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1D192B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {double delay = 0}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6750A4),
          letterSpacing: 1.2,
        ),
      ),
    ).animate().fadeIn(delay: (200 + (delay * 100)).ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildGuestIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8DEF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCAC4D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: Color(0xFF6750A4)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Guest Mode Active",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D192B),
                    fontSize: 14,
                  ),
                ),
                 Text(
                  "Some security features like Biometrics are disabled for guest accounts.",
                  style: TextStyle(
                    color: Color(0xFF49454F),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String subLabel,
    required Widget control,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDF7),
              borderRadius: BorderRadius.circular(16), // Rounded
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF49454F)), // Slightly larger icon
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D192B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          control,
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8DEF8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF1D192B)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D192B),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2), // Jelly dim
      builder: (context) => const ChangePasswordDialog(),
    );
  }
}
