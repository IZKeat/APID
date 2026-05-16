import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../pages_desktop/merchant_dashboard_desktop.dart';

class DesktopQrLoginView extends StatefulWidget {
  final VoidCallback onCancel;

  const DesktopQrLoginView({super.key, required this.onCancel});

  @override
  State<DesktopQrLoginView> createState() => _DesktopQrLoginViewState();
}

class _DesktopQrLoginViewState extends State<DesktopQrLoginView> {
  String? _sessionId;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  bool _isAuthorizing = false;
  String _statusMessage = "Logging in...";
  DateTime? _tokenWaitStartTime;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final sessionId = const Uuid().v4();
    setState(() => _sessionId = sessionId);

    // Create session in Firestore
    await FirebaseFirestore.instance.collection('login_sessions').doc(sessionId).set({
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'device_info': 'Desktop Client', // Could add more info
    });

    // Listen for updates
    _sessionSubscription = FirebaseFirestore.instance
        .collection('login_sessions')
        .doc(sessionId)
        .snapshots()
        .listen(_handleSessionUpdate);
  }

  Future<void> _handleSessionUpdate(DocumentSnapshot snapshot) async {
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final status = data['status'] as String?;
    final uid = data['uid'] as String?;
    final token = data['token'] as String?;

    // Check for 'authorized' status (Mobile app set this) OR 'ready_to_login' (Cloud Function set this)
    if (status == 'authorized' || status == 'ready_to_login') {
      if (!_isAuthorizing) {
        setState(() {
          _isAuthorizing = true;
          _statusMessage = "Authorized! Secureizing connection...";
        });
      }

      if (token != null) {
        // ✅ 1. Token Received! Sign in securely.
        try {
          setState(() => _statusMessage = "Authenticating...");
          await FirebaseAuth.instance.signInWithCustomToken(token);
          debugPrint("✅ Secure QR Login Successful!");
          // AuthState listener in LoginPage will handle routing
        } catch (e) {
          debugPrint("❌ Secure Login Failed: $e");
          if (mounted) {
            setState(() {
              _statusMessage = "Login Failed. Retrying...";
              _isAuthorizing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Login Failed: $e")),
            );
          }
        }
      } else if (uid != null) {
        // ⏳ 2. Authorized but no token yet. Wait for Cloud Function.
        if (_tokenWaitStartTime == null) {
          _tokenWaitStartTime = DateTime.now();
          debugPrint("⏳ Waiting for Security Token...");
          
          // Start a failsafe timer (10 seconds)
          Timer(const Duration(seconds: 10), () {
            if (mounted && _isAuthorizing && FirebaseAuth.instance.currentUser == null) {
              debugPrint("⚠️ Token timeout. Falling back to Prototype Mode.");
              _triggerPrototypeFallback(uid);
            }
          });
        }
      }
    }
  }

  void _triggerPrototypeFallback(String uid) {
    if (!mounted) return;
    
    setState(() => _statusMessage = "Entering Prototype Mode...");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ Secure Token Timeout. Using Prototype Mode."),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );

    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MerchantDashboardDesktop(prototypeUid: uid),
        ),
      );
    } catch (e) {
      debugPrint("❌ Bypass Failed: $e");
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Scan to Login",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1D192B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Use your mobile app to scan this code",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF49454F),
              ),
            ),
            const SizedBox(height: 32),
            
            if (_sessionId == null)
              const CircularProgressIndicator()
            else if (_isAuthorizing)
              Column(
                children: [
                   const CircularProgressIndicator(),
                   const SizedBox(height: 16),
                   Text(_statusMessage, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                ],
              )
            else
              QrImageView(
                data: "auth://login?session=$_sessionId",
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF6750A4),
                ),
              ).animate().fadeIn().scale(),

            const SizedBox(height: 32),
            TextButton(
              onPressed: widget.onCancel,
              child: const Text("Cancel"),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
