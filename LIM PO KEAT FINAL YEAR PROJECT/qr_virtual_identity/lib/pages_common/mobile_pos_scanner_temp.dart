import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MobilePosScannerTemp extends StatefulWidget {
  const MobilePosScannerTemp({super.key});

  @override
  State<MobilePosScannerTemp> createState() => _MobilePosScannerTempState();
}

class _MobilePosScannerTempState extends State<MobilePosScannerTemp> {
  late MobileScannerController _scannerController;
  StreamSubscription<DocumentSnapshot>? _triggerSubscription;

  bool _isScanning = false;
  bool _isProcessing = false;
  double _currentAmount = 0.0;
  List<dynamic> _currentCart = [];
  String? _merchantUid;
  String? _merchantEmail;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    _getCurrentUser();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _merchantUid = user.uid;
      _merchantEmail = user.email;
      _listenForTrigger();
    } else {
      // User not authenticated, navigate back
      _signOutAndPop();
    }
  }

  void _listenForTrigger() {
    if (_merchantUid == null) return;

    _triggerSubscription = FirebaseFirestore.instance
        .collection('scanner_triggers')
        .doc(_merchantUid!)
        .snapshots()
        .listen((doc) {
          if (doc.exists && !_isScanning) {
            final data = doc.data()!;
            final trigger = data['trigger'] as bool? ?? false;

            if (trigger) {
              // Get amount and cart data
              _currentAmount = (data['amount'] ?? 0.0).toDouble();
              _currentCart = data['cart'] ?? [];

              // Start scanning
              _startScanning();
            }
          }
        });
  }

  void _startScanning() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _isProcessing = false;
    });

    try {
      await _scannerController.start();
    } catch (e) {
      print('Error starting scanner: $e');
      await _writeErrorStatus('Failed to start camera: $e');
    }
  }

  void _stopScanning() async {
    if (!_isScanning) return;

    setState(() {
      _isScanning = false;
    });

    try {
      await _scannerController.stop();
    } catch (e) {
      print('Error stopping scanner: $e');
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || !_isScanning) return;

    setState(() {
      _isProcessing = true;
    });

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        final studentUid = code.trim();
        await _processScannedCode(studentUid);
        break;
      }
    }
  }

  Future<void> _processScannedCode(String studentUid) async {
    if (_merchantUid == null) return;

    try {
      // Write success status to Firestore
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(_merchantUid!)
          .set({
            'status': 'success',
            'student_uid': studentUid,
            'amount': _currentAmount,
            'cart': _currentCart,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Reset trigger
      await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .doc(_merchantUid!)
          .set({'trigger': false}, SetOptions(merge: true));

      // Stop scanning and show success message
      _stopScanning();

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student scanned. Processing on desktop...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      await _writeErrorStatus(e.toString());
    }
  }

  Future<void> _writeErrorStatus(String message) async {
    if (_merchantUid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(_merchantUid!)
          .set({
            'status': 'error',
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Reset trigger
      await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .doc(_merchantUid!)
          .set({'trigger': false}, SetOptions(merge: true));

      _stopScanning();

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error writing error status: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _signOutAndPop() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }

    if (mounted) {
      // Navigate back to the first route (usually login/home)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _triggerSubscription?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Mobile Scanner (Temp)'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_merchantEmail != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  _merchantEmail!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOutAndPop,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: _isScanning ? Colors.green[100] : Colors.orange[100],
            child: Row(
              children: [
                Icon(
                  _isScanning ? Icons.camera_alt : Icons.access_time,
                  color: _isScanning ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isScanning
                        ? 'Camera active - Scan student QR code'
                        : 'Waiting for desktop POS to trigger scan...',
                    style: TextStyle(
                      color: _isScanning
                          ? Colors.green[800]
                          : Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: _isScanning ? _buildScannerView() : _buildWaitingView(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera preview
        MobileScanner(controller: _scannerController, onDetect: _onDetect),

        // Overlay with scanning frame
        Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
        ),

        // Centered white square frame
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),

        // Instructions
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Position the student QR code within the white frame',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smartphone, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Waiting for Desktop POS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This device will automatically start the camera when the desktop POS system triggers a scan.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Listening for trigger...',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
