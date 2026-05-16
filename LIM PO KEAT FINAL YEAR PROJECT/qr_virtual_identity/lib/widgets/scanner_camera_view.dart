// lib/widgets/scanner_camera_view.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// 🎥 Scanner Camera View
/// Displays the camera scanner with QR detection, overlay, and processing indicator
class ScannerCameraView extends StatefulWidget {
  final MobileScannerController controller;
  final bool isProcessing;
  final Widget? strategyOverlay;
  final void Function(String) onQrDetected;
  final String scanFrameType; // 'qr' for square, 'barcode' for rectangular

  const ScannerCameraView({
    super.key,
    required this.controller,
    required this.isProcessing,
    required this.onQrDetected,
    this.strategyOverlay,
    this.scanFrameType = 'qr', // Default to QR square frame
  });

  @override
  State<ScannerCameraView> createState() => _ScannerCameraViewState();
}

class _ScannerCameraViewState extends State<ScannerCameraView> with WidgetsBindingObserver {
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Note: We do NOT auto-start the camera here.
    // The Strategy (parent) is responsible for calling ScannerLifecycleController.startScanning()
    // This prevents race conditions where both the View and the Strategy try to start the camera.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Note: We rely on the MobileScanner's internal lifecycle handling or the Strategy to manage this.
    // Manual restarting here often causes "controllerAlreadyInitialized" errors.
  }

  // _restartCamera removed as it is no longer used internally

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // 🌑 FIX: Black background to prevent white flash
      child: Stack(
      children: [
        // Camera preview
        SizedBox.expand(
          child: MobileScanner(
            controller: widget.controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              final raw = barcode.rawValue;
              if (raw != null) {
                widget.onQrDetected(raw);
              }
            },
            errorBuilder: (context, error, child) {
              print('📱 [Scanner Camera View] Camera status: $error');
              // Keep preview visible; ignore transient errors like "already started"
              return child ?? const SizedBox.shrink();
            },
            placeholderBuilder: (context, child) {
              // Show actual camera preview once ready; fallback to loader while initializing
              return child ??
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
            },
          ),
        ),

        // Scan frame overlay - dynamic shape based on scan type
        Center(
          child: Container(
            width: widget.scanFrameType == 'barcode' ? 340 : 260, // Wider for barcode
            height: widget.scanFrameType == 'barcode'
                ? 140
                : 260, // Shorter for barcode
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.scanFrameType == 'barcode'
                ? Center(
                    child: Text(
                      'Align barcode here',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
          ),
        ),

        // Strategy UI overlay (library mode, commerce mode, etc.)
        if (widget.strategyOverlay != null) widget.strategyOverlay!,

        // 🔦 Flashlight Toggle (Jelly Style)
        Positioned(
          bottom: 40,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                try {
                  await widget.controller.toggleTorch();
                  setState(() {
                    _isTorchOn = !_isTorchOn;
                  });
                } catch (e) {
                  debugPrint('Error toggling torch: $e');
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack, // Jelly bounce
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _isTorchOn 
                      ? const Color(0xFFFFD700).withOpacity(0.9) // Bright Yellow
                      : Colors.black.withOpacity(0.4), // Semi-transparent black
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isTorchOn 
                          ? const Color(0xFFFFD700).withOpacity(0.5) 
                          : Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: _isTorchOn ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isTorchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                  color: _isTorchOn ? Colors.black : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}
