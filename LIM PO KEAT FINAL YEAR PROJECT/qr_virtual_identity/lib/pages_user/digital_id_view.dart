import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../services/wallet_service.dart';
import '../services/biometric_service.dart';
import '../widgets/jelly_notification.dart'; // Import JellyNotification
import '../widgets/jelly_card.dart'; // Reuse JellyCard for receipt

class DigitalIdView extends StatefulWidget {
  const DigitalIdView({super.key});

  @override
  State<DigitalIdView> createState() => _DigitalIdViewState();
}

class _DigitalIdViewState extends State<DigitalIdView> {
  // State
  int _timeLeft = 59;
  bool _isRefreshing = false;
  bool _copied = false;
  String _currentQrData = '';
  Timer? _timer;
  Timer? _countdownTimer;
  
  // Notification State
  StreamSubscription? _interactionSubscription;
  bool _showNotification = false;
  Map<String, dynamic>? _notificationData;
  Timer? _notificationTimer;

  // Secure State
  bool _isSecure = true; // Default to locked
  Timer? _secureTimer;
  


  // Constants
  static const String _hmacSecret = "SUPER_SECRET_256_BIT_KEY";
  final Color _primaryColor = const Color(0xFF6750A4);
  final Color _backgroundColor = const Color(0xFF1D192B);
  final Color _surfaceColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _updateQrData();
    _startTimers();
    _listenForInteractions(); // Start listening
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _interactionSubscription?.cancel();
    _notificationTimer?.cancel();
    _secureTimer?.cancel();
    _notificationTimer?.cancel();
    _secureTimer?.cancel();
    super.dispose();
  }

  Future<void> _unlockSecureMode() async {
    // 1. Check if biometrics are available
    final canCheck = await BiometricService().canCheckBiometrics();
    debugPrint("🔍 [DigitalID] canCheckBiometrics: $canCheck");
    
    if (!canCheck) {
      // Fallback if no biometrics (just toggle for now, or show PIN)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debug: Biometrics not detected. Unlocking via fallback.')),
        );
      }
      setState(() => _isSecure = !_isSecure);
      return;
    }

    // 2. Authenticate
    final authenticated = await BiometricService().authenticate();
    if (authenticated) {
      setState(() {
        _isSecure = false;
      });

      // 3. Auto-lock after 60 seconds
      _secureTimer?.cancel();
      _secureTimer = Timer(const Duration(seconds: 60), () {
        if (mounted) {
          setState(() {
            _isSecure = true;
          });
        }
      });
    }
  }

  void _startTimers() {
    // Refresh QR every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _handleRefresh();
    });

    // Countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft <= 1) {
            _timeLeft = 60;
          } else {
            _timeLeft--;
          }
        });
      }
    });
  }

  void _listenForInteractions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Listen for interactions created AFTER this view was opened
    // Using a timestamp slightly in the past to be safe, or just listen to new ones
    // FIX: Relaxed to 24 hours to ensure we catch the event even if clocks are off
    final viewOpenTime = DateTime.now();
    final startTime = Timestamp.fromDate(viewOpenTime.subtract(const Duration(hours: 24)));

    _interactionSubscription = FirebaseFirestore.instance
        .collection('interactions')
        .where('user_id', isEqualTo: user.uid)
        .where('type', isEqualTo: 'purchase')
        .where('timestamp', isGreaterThan: startTime)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
             // FIX: Removed strict timestamp check to ensure notification is shown
             // We rely on 'DocumentChangeType.added' to show new alerts
             print("🔔 [Digital ID] New interaction received: ${data['scan_point_name']}");
             _handleNewPurchase(data);
          }
        }
      }
    });

    // 🔍 DEBUG LISTENER: Catch-all to see if ANY interaction is reaching the device
    // This helps diagnose if the issue is the query filters (timestamp/type)
    FirebaseFirestore.instance
        .collection('interactions')
        .where('user_id', isEqualTo: user.uid)
        .limit(5) // Just check the last few
        .snapshots()
        .listen((snapshot) {
           for (var change in snapshot.docChanges) {
             if (change.type == DocumentChangeType.added) {
               final data = change.doc.data();
               print('🔍 [Digital ID Debug] Found interaction: ${data?['type']} at ${data?['timestamp']}');
             }
           }
        });
  }

  void _handleNewPurchase(Map<String, dynamic> data) {
    if (!mounted) return;

    // Play sound (optional, if AudioHelper is available)
    // AudioHelper.playSuccess(); 

    setState(() {
      _notificationData = data;
      _showNotification = true;
    });

    // Auto-dismiss after 5 seconds
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showNotification = false;
        });
      }
    });
  }

  void _showReceiptDialog() {
    if (_notificationData == null) return;
    
    final amount = (_notificationData!['amount'] as num).toDouble();
    final merchant = _notificationData!['scan_point_name'] ?? 'Merchant';
    final items = _notificationData!['items'] as List<dynamic>? ?? [];
    final date = (_notificationData!['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => Center(
        child: JellyCard(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64)
                    .animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                const SizedBox(height: 16),
                const Text(
                  'Payment Successful',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Paid to $merchant',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Divider(height: 32),
                
                // Items List
                if (items.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        children: items.map((item) {
                          final i = item as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${i['quantity']}x ${i['name']}', style: const TextStyle(fontSize: 14)),
                                Text('RM ${((i['price'] as num) * (i['quantity'] as num)).toStringAsFixed(2)}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                const SizedBox(height: 24),
                Text(
                  date.toString().substring(0, 16),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _showNotification = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Simulate glitch/network delay for effect
    await Future.delayed(const Duration(milliseconds: 1200));

    await _updateQrData();

    if (mounted) {
      setState(() {
        _timeLeft = 60;
        _isRefreshing = false;
      });
    }
  }

  String _generateHmacSignature(String uid, int ts, String nonce) {
    final key = utf8.encode(_hmacSecret);
    final bytes = utf8.encode('$uid|$ts|$nonce');
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _updateQrData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nonce = DateTime.now().microsecondsSinceEpoch.toString().substring(8);
      final signature = _generateHmacSignature(user.uid, timestamp, nonce);

      final qrData = {
        'uid': user.uid,
        'email': user.email,
        'name': userData['name'] ?? 'User',
        'role': userData['role'] ?? 'student',
        'ts': timestamp,
        'nonce': nonce,
        'sig': signature,
        'type': 'user',
      };

      if (mounted) {
        setState(() {
          _currentQrData = jsonEncode(qrData);
        });
      }
    } catch (e) {
      debugPrint('Error generating QR: $e');
    }
  }

  void _handleCopyId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Clipboard.setData(ClipboardData(text: user.uid.substring(0, 8).toUpperCase()));
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Student';
    // Use a shortened UID as a display ID for visual parity with "TP072581"
    final displayId = user != null ? "ID-${user.uid.substring(0, 6).toUpperCase()}" : "LOADING...";

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show gradient
      body: Stack(
        children: [
          // 0. Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFD49FB8), // Even Deeper Pink (Level 3)
                    Color(0xFFA9CBE6), // Even Deeper Blue (Level 3)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 4.seconds, curve: Curves.easeInOut) // "Breathing" motion
            .saturate(begin: 1.0, end: 1.2, duration: 4.seconds, curve: Curves.easeInOut), // "Breathing" intensity
          ),
          
          // 1. Animated Background Blobs (Optimized with RepaintBoundary)
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.2, 1.2),
                          duration: 6.seconds) // Slower, more fluid
                      .move(
                          begin: const Offset(0, 0),
                          end: const Offset(30, 30),
                          duration: 8.seconds), // Floating effect
                ),
                Positioned(
                  bottom: -50,
                  right: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0BCFF).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                          duration: 5.seconds)
                      .move(
                          begin: const Offset(0, 0),
                          end: const Offset(-30, -30),
                          duration: 7.seconds),
                ),
              ],
            ),
          ),

          // Backdrop Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: const SizedBox(),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBackButton(context),
                      Text(
                        'My Digital ID',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                      const SizedBox(width: 48), // Balance spacing
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // 3. The Jelly Card
                          _buildJellyCard(displayName, displayId),
                          
                          const SizedBox(height: 40),

                          // 4. Refresh Button
                          _buildRefreshButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Jelly Notification Banner
          if (_showNotification && _notificationData != null)
            JellyNotification(
              title: 'Payment Successful',
              subtitle: _notificationData!['scan_point_name'] ?? 'Merchant',
              amount: 'RM ${(_notificationData!['amount'] as num).toStringAsFixed(2)}',
              onTap: _showReceiptDialog,
              onDismiss: () => setState(() => _showNotification = false),
            ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }

  Widget _buildJellyCard(String name, String id) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: RepaintBoundary( // Optimization for complex shadows/gradients
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
          children: [
            // Holographic Overlay (Subtle gradient)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Secure Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 16, color: _primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'SECURE IDENTITY',
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 1.seconds),
                            const SizedBox(width: 6),
                            Text(
                              'Live',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFF5F5F5)),

                  // QR Code Container
                  GestureDetector(
                    onTap: _isSecure ? _unlockSecureMode : null,
                    child: Container(
                      width: 240,
                      height: 240,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        boxShadow: const [
                           BoxShadow(
                             color: Color.fromRGBO(0, 0, 0, 0.05) ,
                             offset: Offset(0, 2),
                             blurRadius: 4,
                             spreadRadius: 0,
                           ) // Inner shadow simulation
                        ]
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // The QR Code (Blurred if secure)
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: _isSecure ? 15 : 0,
                              sigmaY: _isSecure ? 15 : 0,
                            ),
                            child: _isRefreshing
                                ? Center(
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: _primaryColor, width: 4),
                                        borderRadius: BorderRadius.circular(24),
                                        color: Colors.transparent,
                                        ),
                                      child: const SizedBox(),
                                    ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1.seconds),
                                  )
                                    : Center(
                                        child: _currentQrData.isNotEmpty
                                            ? QrImageView(
                                                data: _currentQrData,
                                                version: QrVersions.auto,
                                                size: 200.0,
                                                // 🖼️ Embedded Icon
                                                embeddedImage: const AssetImage('assets/icon/icon.png'),
                                                embeddedImageStyle: const QrEmbeddedImageStyle(
                                                  size: Size(40, 40),
                                                ),
                                                eyeStyle: const QrEyeStyle(
                                                  eyeShape: QrEyeShape.square,
                                                  color: Colors.black, // Static Black
                                                ),
                                                dataModuleStyle: const QrDataModuleStyle(
                                                  dataModuleShape: QrDataModuleShape.square,
                                                  color: Colors.black, // Static Black
                                                ),
                                              )
                                            : const SizedBox(),
                                      ),
                                   ),

                          // Lock Overlay
                          if (_isSecure)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: Icon(Icons.lock_outline, size: 32, color: _primaryColor),
                                ).animate(onPlay: (c) => c.repeat(reverse: true))
                                 .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1500.ms),
                                const SizedBox(height: 12),
                                Text(
                                  "Tap to Reveal",
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1D192B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 20)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Copy ID Button
                  GestureDetector(
                    onTap: _handleCopyId,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _copied ? Colors.green.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            id,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _copied ? Icons.check : Icons.copy,
                            size: 14,
                            color: _copied ? Colors.green : Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Wallet Balance
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEADDFF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEADDFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Color(0xFF21005D), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WALLET BALANCE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF49454F),
                                letterSpacing: 0.5,
                              ),
                            ),
                            StreamBuilder<double>(
                              stream: WalletService.getBalanceStream(),
                              initialData: 0.0,
                              builder: (context, snapshot) {
                                return Text(
                                  'RM ${snapshot.data?.toStringAsFixed(2) ?? "0.00"}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1D192B),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Countdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CODE EXPIRES IN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '00:${_timeLeft.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _timeLeft / 60,
                                strokeWidth: 4,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                              ),
                              Text(
                                '${_timeLeft}s',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D192B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    ).animate().scale(
        duration: 600.ms,
        curve: Curves.easeOutBack,
      );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: _handleRefresh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD0BCFF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF31145E).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _isRefreshing 
                  ? AlwaysStoppedAnimation(DateTime.now().millisecond / 1000) // Placeholder for continuous rotation
                  : const AlwaysStoppedAnimation(0),
              child: const Icon(Icons.refresh, color: Color(0xFF381E72))
                  .animate(target: _isRefreshing ? 1 : 0)
                  .rotate(duration: 1.seconds, curve: Curves.linear, begin: 0, end: 1), 
            ),
            const SizedBox(width: 12),
            const Text(
              'Refresh Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF381E72),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 300.ms);
  }
}
