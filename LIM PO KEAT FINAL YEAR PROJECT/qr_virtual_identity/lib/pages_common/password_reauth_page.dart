import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../widgets/jelly_input.dart';
import '../utils/auth_exception_handler.dart';

class PasswordReauthPage extends StatefulWidget {
  const PasswordReauthPage({super.key});

  @override
  State<PasswordReauthPage> createState() => _PasswordReauthPageState();
}

class _PasswordReauthPageState extends State<PasswordReauthPage> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _verifyPassword() async {
    if (_passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception("No user logged in");
      }

      // 1. Re-authenticate with Firebase
      // strict security rule: Must prove ownership before enabling biometrics
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      debugPrint("✅ Re-authentication successful");

      // 2. Trigger Biometric Enrollment
      final bioSuccess = await BiometricService().authenticate();
      if (!bioSuccess) {
        throw Exception("Biometric enrollment failed. Please ensure you have a fingerprint or FaceID enrolled in your device settings.");
      }

      // 3. Generate & Save Secure Token
      final token = const Uuid().v4(); // Generate a random secure token
      await StorageService().setBiometricToken(token);
      await StorageService().setBiometricEnabled(true);
      
      debugPrint("🔐 Biometric enabled with token: $token");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Biometric Login Enabled Successfully"),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Return success

    } catch (e) {
      debugPrint("❌ Re-auth error: $e");
      if (!mounted) return;
      
      final msg = AuthExceptionHandler.handleException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Verification"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security_rounded, size: 64, color: Color(0xFF6750A4))
                .animate()
                .scale(),
            const SizedBox(height: 24),
            const Text(
              "Verify it's you",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "For your security, please enter your password to enable biometric login.",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            JellyInput(
              label: 'Current Password',
              icon: Icons.lock_outline,
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              rightIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6750A4),
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6750A4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify & Enable", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
