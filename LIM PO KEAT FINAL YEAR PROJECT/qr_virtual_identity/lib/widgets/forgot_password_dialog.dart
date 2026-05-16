import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../controllers/login_controller.dart';
import '../widgets/jelly_status_views.dart';

class RecoveryWizardDialog extends StatefulWidget {
  final String? initialEmail;
  final LoginController loginController;

  const RecoveryWizardDialog({
    Key? key,
    this.initialEmail,
    required this.loginController,
  }) : super(key: key);

  @override
  State<RecoveryWizardDialog> createState() => _RecoveryWizardDialogState();
}

class _RecoveryWizardDialogState extends State<RecoveryWizardDialog> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  // Focus Nodes
  final FocusNode _otpFocusNode = FocusNode();

  // State
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  
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
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    _newPassController.addListener(_updateStrength);
    _confirmPassController.addListener(() => setState(() {})); // 🛡️ Rebuild for Match Icon
  }

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    _otpFocusNode.dispose();
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

  void _nextPage() {
    _pageController.nextPage(
      duration: 600.ms, 
      curve: Curves.elasticOut,
    );
    setState(() => _currentStep++);
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: 400.ms, 
      curve: Curves.easeOutQuad,
    );
    setState(() => _currentStep--);
  }

  void _startResendTimer() {
    setState(() => _resendCountdown = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  // --- LOGIC HANDLERS ---

  void _sendCode() {
    if (_resendCountdown > 0) return;

    widget.loginController.sendOtp(
      email: _emailController.text,
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code sent! Check your email.")),
        );
        _startResendTimer();
        if (_currentStep == 0) _nextPage();
      },
      onError: (msg) => _showError(msg),
      // 🔒 PROD MODE: We do NOT show the code in the UI anymore.
      // It will still be logged in the console by the controller/cloud function if in dev mode.
      onMessage: null, 
    );
  }

  void _verifyCode() {
    widget.loginController.verifyOtp(
      email: _emailController.text,
      code: _otpController.text,
      onSuccess: () {
        _nextPage();
      },
      onError: (msg) => _showError(msg),
    );
  }

  void _resetPassword() {
    if (_newPassController.text != _confirmPassController.text) {
      _showError("Passwords do not match");
      return;
    }
    if (_strength < 0.8) {
      _showError("Password is too weak");
      return;
    }

    widget.loginController.resetPasswordWithOtp(
      email: _emailController.text,
      newPassword: _newPassController.text,
      code: _otpController.text,
      onSuccess: () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => JellySuccessView(
              message: "Password Reset!",
              onDone: () => Navigator.pop(context),
            ),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      },
      onError: (msg) => _showError(msg),
    );
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

    return ChangeNotifierProvider.value(
      value: widget.loginController,
      child: Consumer<LoginController>(
        builder: (context, controller, child) {
          return Center(
            child: SingleChildScrollView(
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 450,
                      height: 600,
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
                                _buildStep1Email(controller),
                                _buildStep2Otp(controller),
                                _buildStep3Reset(controller),
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
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _prevPage,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStepTitle(),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1D192B),
                  ),
                ),
                Text(
                  "Step ${_currentStep + 1} of 3",
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

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return "Find Account";
      case 1: return "Verify Code";
      case 2: return "New Password";
      default: return "Recovery";
    }
  }

  Widget _buildStep1Email(LoginController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            "Enter your email to receive a verification code.",
            style: GoogleFonts.outfit(color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          _buildInput(
            controller: _emailController,
            label: "Email Address",
            icon: Icons.email_outlined,
          ),
          const Spacer(),
          _buildButton(
            text: "Send Code",
            onPressed: _sendCode,
            isLoading: controller.isLoading,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep2Otp(LoginController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            "Enter the 6-digit code sent to ${_emailController.text}",
            style: GoogleFonts.outfit(color: Colors.grey[700]),
          ),
          const SizedBox(height: 30),
          
          // OTP Input
          TextField(
            controller: _otpController,
            focusNode: _otpFocusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 32, letterSpacing: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              hintText: "000000",
              hintStyle: const TextStyle(color: Colors.black12, letterSpacing: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF3EDF7),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.length == 6) {
                FocusScope.of(context).unfocus();
                _verifyCode(); // Auto-verify
              }
            },
          ),
          
          const SizedBox(height: 20),
          TextButton(
            onPressed: _resendCountdown > 0 ? null : _sendCode,
            child: Text(
              _resendCountdown > 0 
                  ? "Resend Code in ${_resendCountdown}s" 
                  : "Resend Code",
              style: TextStyle(
                color: _resendCountdown > 0 ? Colors.grey : const Color(0xFF6750A4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          _buildButton(
            text: "Verify",
            onPressed: _verifyCode,
            isLoading: controller.isLoading,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep3Reset(LoginController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildInput(
            controller: _newPassController,
            label: "New Password",
            icon: Icons.lock_outline,
            obscure: _obscureNewPass,
            onToggle: () => setState(() => _obscureNewPass = !_obscureNewPass),
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
            obscure: _obscureConfirmPass,
            onToggle: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            // 🛡️ Poka-Yoke: Real-time Match Check
            suffix: _confirmPassController.text.isNotEmpty 
              ? Icon(
                  _newPassController.text == _confirmPassController.text 
                      ? Icons.check_circle 
                      : Icons.error,
                  color: _newPassController.text == _confirmPassController.text 
                      ? Colors.green 
                      : Colors.red,
                )
              : null,
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
            text: "Reset Password",
            onPressed: _resetPassword,
            isLoading: controller.isLoading,
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
    bool obscure = false,
    VoidCallback? onToggle,
    Widget? suffix, // 🆕
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6750A4)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suffix != null) Padding(padding: const EdgeInsets.only(right: 8), child: suffix),
            if (onToggle != null)
              IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggle,
              ),
          ],
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
    required bool isLoading,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: const Color(0xFF6750A4).withOpacity(0.4),
        ),
        child: isLoading
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
    ).animate(target: isLoading ? 0 : 1).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      duration: 200.ms,
    );
  }
}
