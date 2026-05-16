import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../controllers/session_controller.dart';
import '../pages_desktop/merchant_dashboard_desktop.dart';
import '../widgets/jelly_input.dart';
import '../widgets/desktop_qr_login_view.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/biometric_onboarding_dialog.dart';
import '../controllers/login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController _loginController = LoginController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _showQrLogin = false; // Local UI state for QR overlay

  @override
  void initState() {
    super.initState();
    // Check session on startup
    _loginController.checkSessionAndBiometrics(
      onSessionOpen: (user) => _handleUserRouting(user),
      onBiometricAuthRequired: () => _authenticateWithBiometrics(),
      onLoadCredentials: (email, password) {
        _emailController.text = email;
        _passwordController.text = password;
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loginController.dispose();
    super.dispose();
  }

  void _handleUserRouting(User user) {
    _loginController.handleUserRouting(
      user,
      onNavigate: (route) {
        if (route == '/home') {
          Navigator.pushReplacementNamed(context, Routes.home);
        } else if (route == '/admin_dashboard') {
          Navigator.pushReplacementNamed(context, Routes.adminDashboard);
        } else {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      onMerchantRoute: (uid, userModel) =>
          _loginController.routeMerchantByScanPointType(
        uid,
        userModel,
        onNavigate: (route) {
          if (route == 'MERCHANT_DESKTOP') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const MerchantDashboardDesktop()),
            );
          } else if (route == '/mobile_scanner_terminal') {
            Navigator.pushReplacementNamed(context, Routes.mobileScannerTerminal);
          }
        },
        onShowMessage: (msg) =>
            _showCustomSnackBar(context, msg, isError: true),
        isWeb: kIsWeb,
        isDesktop: Platform.isWindows || Platform.isMacOS,
      ),
      onError: (msg) => _showCustomSnackBar(context, msg, isError: true),
    );
  }

  // 📳 Haptic & Visual Feedback State
  int _shakeCount = 0; // Increment to trigger shake

  void _authenticateWithBiometrics() {
    _loginController.authenticateWithBiometrics(
      currentEmail: _emailController.text,
      currentPassword: _passwordController.text,
      onSuccess: (user) => _handleUserRouting(user),
      onError: (msg) {
        _showCustomSnackBar(context, msg, isError: true);
        // 🛡️ Poka-Yoke: High-priority feedback on failure
        if (msg.contains('Switching to Password') || msg.contains('Security Changed')) {
           _triggerSmartFallback();
        }
    },
    onManualLoginRequired: () {
        // 🛡️ Smart Fallback: User cancelled or failed
        debugPrint("🔓 Manual Login Required - Triggering Smart Fallback");
        _triggerSmartFallback();
    },
      onStopSessionListener: () {
        if (mounted) context.read<SessionController>().setPaused(true);
      },
      onStartSessionListener: () {
        if (mounted) {
          final sessionController = context.read<SessionController>();
          sessionController.setPaused(false);
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) sessionController.startSessionListener(user.uid);
        }
      },
    );
  }

  // 🧠 Smart Fallback: Shake + Haptic + Focus
  void _triggerSmartFallback() {
    setState(() {
      _shakeCount++; // Trigger animation
    });
    HapticFeedback.mediumImpact(); // 📳 Tactile "No"
    
    // Auto-focus password field for zero-friction typing
    Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
           FocusScope.of(context).requestFocus(_passwordFocus);
        }
    });
  }

  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showCustomSnackBar(context, "Please enter email and password", isError: true);
      _triggerSmartFallback(); // Reset focus and shake
      return;
    }

    await _loginController.loginUser(
      email: _emailController.text,
      password: _passwordController.text,
      onSuccess: (user) async {
        // Check for onboarding prompt BEFORE routing
        if (mounted) {
          final shouldShow = await _loginController.shouldShowBiometricOnboarding();
          if (shouldShow) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => BiometricOnboardingDialog(
                onDismiss: () {
                  // User said later, proceed to home
                  _handleUserRouting(user);
                },
                onEnable: () async {
                  // User said yes, route to home (Settings red dot will handle it)
                  _handleUserRouting(user);
                },
              ),
            );
          } else {
            _handleUserRouting(user);
          }
        }
      },
      onError: (msg) => _showCustomSnackBar(context, msg, isError: true),
      onStopSessionListener: () {
        // 🛑 Pause listener to prevent race condition
        if (mounted) {
          context.read<SessionController>().setPaused(true);
        }
      },
      onStartSessionListener: () {
        // ▶️ Resume listener and manually start it if user is logged in
        if (mounted) {
          final sessionController = context.read<SessionController>();
          sessionController.setPaused(false);
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            sessionController.startSessionListener(user.uid);
          }
        }
      },
    );
  }

  void _signInWithGoogle() {
    _loginController.signInWithGoogle(
      onSuccess: (user) => _handleUserRouting(user),
      onError: (msg) => _showCustomSnackBar(context, msg, isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ListenableBuilder(
      listenable: _loginController,
      builder: (context, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false, // Handle scrolling manually
          body: Stack(
            children: [
              // 🎨 Animated Background Blobs
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE8DEF8).withOpacity(0.6),
                        const Color(0xFFD0BCFF).withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                )
                    .animate(
                        onPlay: (controller) => controller.repeat(reverse: true))
                    .scaleXY(
                        begin: 1.0,
                        end: 1.2,
                        duration: 4.seconds,
                        curve: Curves.easeInOut)
                    .rotate(begin: 0, end: 0.1, duration: 5.seconds),
              ),

              // 📄 Main Content
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding:
                          EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - bottomInset,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 🎓 Hero Section - 3D Logo
                            Center(
                              child: Hero(
                                tag: 'app_logo',
                                child: Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6750A4),
                                    borderRadius: BorderRadius.circular(36),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6750A4)
                                            .withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(36),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            'assets/icon/icon.png',
                                            fit: BoxFit.cover,
                                          ),
                                          // Subtle shimmer overlay for "glass" effect
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withOpacity(0.2),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ),
                              )
                                  .animate()
                                  .scaleXY(
                                      begin: 0,
                                      end: 1,
                                      duration: 600.ms,
                                      curve: Curves.elasticOut)
                                  .then()
                                  .shimmer(
                                      duration: 1.5.seconds, delay: 2.seconds),
                            ),
                            const SizedBox(height: 32),

                            Text(
                              'Welcome Back',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1D192B),
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to access your APID',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF49454F),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            )
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 48),

                            // ⌨️ Input Section
                            JellyInput(
                              label: 'Student Email',
                              icon: Icons.mail_outline_rounded,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .slideX(begin: -0.1, end: 0),
                            const SizedBox(height: 20),
                            // 🔑 Password Field with Smart Shake
                            Animate(
                              key: ValueKey(_shakeCount), // 🔄 Replays animation on error
                              effects: _shakeCount > 0
                                  ? [
                                      const ShakeEffect(
                                          hz: 8,
                                          curve: Curves.easeInOutCubic,
                                          duration: Duration(milliseconds: 500))
                                    ]
                                  : [
                                      const FadeEffect(
                                          delay: Duration(milliseconds: 500)),
                                      const SlideEffect(
                                          begin: Offset(-0.1, 0),
                                          end: Offset.zero,
                                          delay: Duration(milliseconds: 500))
                                    ],
                              child: JellyInput(
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: !_loginController.isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _loginUser(),
                                rightIcon: GestureDetector(
                                  onTap: () =>
                                      _loginController.togglePasswordVisibility(),
                                  child: Icon(
                                    _loginController.isPasswordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: const Color(0xFF6750A4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 👆 Biometric Login Button (Only if available & enabled)
                            if (_loginController.canCheckBiometrics)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: _authenticateWithBiometrics,
                                    icon:
                                        const Icon(Icons.fingerprint, size: 24),
                                    label: const Text(
                                        "Login with FaceID / Fingerprint"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6750A4),
                                      side: const BorderSide(
                                          color: Color(0xFF6750A4)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 600.ms),
                              ),

                            // 🧠 Remember Me & Forgot
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.9,
                                      child: Checkbox(
                                        value: _loginController.rememberMe,
                                        activeColor: const Color(0xFF6750A4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        onChanged: (value) {
                                          _loginController
                                              .setRememberMe(value ?? false);
                                        },
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _loginController.setRememberMe(
                                            !_loginController.rememberMe);
                                      },
                                      child: const Text(
                                        'Remember Me',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF49454F),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => RecoveryWizardDialog(
                                        loginController: _loginController,
                                        initialEmail: _emailController.text.isNotEmpty
                                            ? _emailController.text
                                            : null,
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6750A4),
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 600.ms),
                            const SizedBox(height: 32),
                            // 🛡️ Login Button / Lockout Timer
                            Builder(
                              builder: (context) {
                                final lockoutTime = _loginController.lockoutEndTime;
                                final isLocked = lockoutTime != null && lockoutTime.isAfter(DateTime.now());
                                
                                if (isLocked) {
                                  // 📳 Haptic Feedback on Lockout Appearance
                                  HapticFeedback.lightImpact();

                                  // 🕒 Countdown Timer (Jelly Style)
                                  return StreamBuilder(
                                    stream: Stream.periodic(const Duration(seconds: 1)),
                                    builder: (context, snapshot) {
                                      final now = DateTime.now();
                                      if (lockoutTime!.isBefore(now)) {
                                        // Timer expired, trigger rebuild to show button
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          _loginController.notifyListeners(); // Hack to refresh controller state
                                        });
                                        return const SizedBox(); 
                                      }
                                      
                                      final remaining = lockoutTime.difference(now);
                                      final seconds = remaining.inSeconds;

                                      return Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.errorContainer, // 🔴 Red/Pink background
                                          borderRadius: BorderRadius.circular(28),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.colorScheme.error.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.timer_off_rounded, color: theme.colorScheme.onErrorContainer),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Try again in ${seconds}s",
                                              style: TextStyle(
                                                color: theme.colorScheme.onErrorContainer,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                fontFamily: 'Monospace', // 🔠 Monospace to prevent jitter
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                      .scaleXY(end: 1.02, duration: 1.seconds) // 💓 Pulse Animation
                                      .shake(hz: 4, curve: Curves.easeInOutCubic); // Initial Shake
                                    },
                                  );
                                }

                                return AnimatedContainer(
                                  duration: 600.ms, // ⏱️ Slower duration for elastic effect
                                  curve: Curves.elasticOut, // 🍮 Jelly Physics
                                  height: 56,
                                  width: _loginController.isLoginSuccess
                                      ? 56
                                      : MediaQuery.of(context).size.width,
                                  child: ElevatedButton(
                                    onPressed: _loginController.isLoading ||
                                            _loginController.isLoginSuccess
                                        ? null
                                        : _loginUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _loginController.isLoginSuccess
                                              ? const Color(
                                                  0xFF4CAF50) // Green for success
                                              : const Color(0xFF6750A4),
                                      foregroundColor: Colors.white,
                                      elevation:
                                          _loginController.isLoginSuccess ? 0 : 8,
                                      padding: EdgeInsets
                                          .zero, // Remove padding for perfect circle
                                      shadowColor: const Color(0xFF6750A4)
                                          .withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            _loginController.isLoginSuccess
                                                ? 50
                                                : 28),
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: 300.ms,
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        );
                                      },
                                      child: _loginController.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        Colors.white),
                                              ),
                                            )
                                          : _loginController.isLoginSuccess
                                              ? const Icon(Icons.check_rounded,
                                                  size: 32, color: Colors.white)
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: const [
                                                    Text(
                                                      'Login',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Icon(
                                                        Icons.arrow_forward_rounded,
                                                        size: 20),
                                                  ],
                                                ),
                                    ),
                                  ),
                                );
                              }
                            )
                                .animate()
                                .fadeIn(delay: 700.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 24),

                            if (!kIsWeb &&
                                (Platform.isAndroid || Platform.isIOS)) ...[
                              Row(
                                children: [
                                  Expanded(
                                      child:
                                          Divider(color: Colors.grey.shade300)),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child:
                                          Divider(color: Colors.grey.shade300)),
                                ],
                              ).animate().fadeIn(delay: 800.ms),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: _loginController.isGoogleSignIn
                                      ? null
                                      : _signInWithGoogle,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFFCAC4D0), width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    foregroundColor: const Color(0xFF1D192B),
                                  ),
                                  child: _loginController.isGoogleSignIn
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Continue as Guest',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 900.ms)
                                  .slideY(begin: 0.2, end: 0),
                            ],

                            // 🖥️ Desktop QR Login Button
                            if (kIsWeb ||
                                Platform.isWindows ||
                                Platform.isMacOS ||
                                Platform.isLinux) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 56,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => _showQrLogin = true),
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text("Login with QR Code"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6750A4),
                                    side: const BorderSide(
                                        color: Color(0xFF6750A4)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 1000.ms)
                                  .slideY(begin: 0.2, end: 0),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🖥️ QR Login Overlay
              if (_showQrLogin)
                Container(
                  color: Colors.black54,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: DesktopQrLoginView(
                      onCancel: () => setState(() => _showQrLogin = false),
                    ),
                  ),
                ).animate().fadeIn(),
            ],
          ),
        );
      },
    );
  }


  void _showCustomSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (isError) {
      HapticFeedback.heavyImpact(); // 📳 Poka-Yoke: Tactile Error Feedback
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFB3261E) : const Color(0xFF21005D), // Material 3 Error / Primary Container
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
