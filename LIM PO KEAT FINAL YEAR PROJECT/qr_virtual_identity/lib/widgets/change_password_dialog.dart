import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import '../widgets/jelly_status_views.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // State
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  // Password Strength
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  double _strength = 0.0;
  Color _strengthColor = Colors.grey;
  String _strengthText = "Enter Password";

  @override
  void initState() {
    super.initState();
    _newPassController.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final pass = _newPassController.text;
    setState(() {
      _hasMinLength = pass.length >= 8;
      _hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      _hasLowercase = pass.contains(RegExp(r'[a-z]'));
      _hasNumber = pass.contains(RegExp(r'[0-9]'));
      _hasSymbol = pass.contains(RegExp(r'[@$!%*?&]'));

      int score = 0;
      if (_hasMinLength) score++;
      if (_hasUppercase) score++;
      if (_hasLowercase) score++;
      if (_hasNumber) score++;
      if (_hasSymbol) score++;

      _strength = score / 5.0;
      if (score <= 2) {
        _strengthColor = Colors.redAccent;
        _strengthText = "Weak";
      } else if (score <= 4) {
        _strengthColor = Colors.orangeAccent;
        _strengthText = "Medium";
      } else {
        _strengthColor = Colors.green;
        _strengthText = "Strong";
      }
      
      if (pass.isEmpty) {
        _strength = 0.0;
        _strengthText = "Enter Password";
        _strengthColor = Colors.grey;
      }
    });
  }

  Future<void> _verifyCurrentPassword() async {
    if (_currentPassController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    // 🔒 Verify with Firebase
    final isValid = await AuthService.verifyPassword(_currentPassController.text);
    
    setState(() => _isLoading = false);

    if (isValid) {
      _pageController.nextPage(
        duration: 600.ms, 
        curve: Curves.elasticOut,
      );
      setState(() => _currentStep = 1);
    } else {
      _showError("Incorrect password");
    }
  }

  Future<void> _updatePassword() async {
    if (_newPassController.text != _confirmPassController.text) {
      _showError("Passwords do not match");
      return;
    }
    if (_strength < 0.8) { // Require at least 4/5
      _showError("Password is too weak");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.changePassword(
        currentPassword: _currentPassController.text,
        newPassword: _newPassController.text,
      );

      if (!mounted) return;
      
      // 🎉 Show Success View
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => JellySuccessView(
            message: "Password Updated!",
            onDone: () => Navigator.pop(context),
          ),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );

    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: SingleChildScrollView(
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 420,
                height: 550,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Content
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1Verify(),
                          _buildStep2Update(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                _pageController.previousPage(
                  duration: 400.ms, 
                  curve: Curves.easeOutQuad
                );
                setState(() => _currentStep = 0);
              },
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentStep == 0 ? "Security Check" : "New Password",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D192B),
                  ),
                ),
                Text(
                  _currentStep == 0 ? "Verify it's you" : "Create strong password",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Verify() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildInput(
            controller: _currentPassController,
            label: "Current Password",
            icon: Icons.lock_outline,
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const Spacer(),
          _buildButton(
            text: "Verify",
            onPressed: _verifyCurrentPassword,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep2Update() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildInput(
            controller: _newPassController,
            label: "New Password",
            icon: Icons.vpn_key_outlined,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 8),
          // Strength Meter
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _strength,
                  backgroundColor: Colors.grey[200],
                  color: _strengthColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _strengthText,
                style: TextStyle(
                  color: _strengthColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInput(
            controller: _confirmPassController,
            label: "Confirm Password",
            icon: Icons.check_circle_outline,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          
          const SizedBox(height: 24),
          // Checklist
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildCheck("8+ chars", _hasMinLength),
              _buildCheck("A-Z", _hasUppercase),
              _buildCheck("a-z", _hasLowercase),
              _buildCheck("0-9", _hasNumber),
              _buildCheck("Symbol", _hasSymbol),
            ],
          ),

          const Spacer(),
          _buildButton(
            text: "Change Password",
            onPressed: _updatePassword,
            color: const Color(0xFF6750A4),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6750A4)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF3EDF7),
      ),
    );
  }

  Widget _buildCheck(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? Colors.green : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check : Icons.circle_outlined,
            size: 12,
            color: active ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.green[700] : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    Color color = const Color(0xFF6750A4),
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: color.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    ).animate(target: _isLoading ? 0 : 1).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      duration: 200.ms,
    );
  }
}
