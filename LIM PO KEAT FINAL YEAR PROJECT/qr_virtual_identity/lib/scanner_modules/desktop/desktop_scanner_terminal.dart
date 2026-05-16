import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:apid/scanner_modules/scanner_mode_strategy.dart';
import 'package:apid/services/scan_point_service.dart';
import 'package:apid/scanner_modules/access/access_scanner_strategy.dart';
import 'package:apid/scanner_modules/commerce/commerce_scanner_strategy.dart';
import 'package:apid/scanner_modules/library/library_scanner_strategy.dart';
import 'package:apid/scanner_modules/event/event_scanner_strategy.dart';
import 'package:apid/widgets/desktop/demo_mode_panel.dart';

/// 🖥️ **Desktop Scanner Terminal (Demo Mode)**
///
/// A dedicated scanner terminal for desktop/webcam use, primarily for
/// demonstrations and debugging. It mimics the mobile scanner's behavior
/// but runs on the desktop platform.
///
/// **Features:**
/// - Uses `mobile_scanner` for webcam access.
/// - Supports all scanner strategies (Access, Commerce, Library, Event).
/// - Displays a "Demo Mode" badge.
/// - Emits debug info via `onDebugInfo` callback.
class DesktopScannerTerminal extends StatefulWidget {
  final String scanPointId;
  final String scanMode;
  final VoidCallback onClose;

  const DesktopScannerTerminal({
    super.key,
    required this.scanPointId,
    required this.scanMode,
    required this.onClose,
  });

  @override
  State<DesktopScannerTerminal> createState() => _DesktopScannerTerminalState();
}

class _DesktopScannerTerminalState extends State<DesktopScannerTerminal> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.front, // Webcam usually treated as front
  );

  ScannerModeStrategy? _strategy;
  ScanPoint? _scanPoint;
  bool _isLoading = true;
  String? _error;

  // Debug Panel State
  final List<Map<String, dynamic>> _debugLogs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
  }

  Future<void> _initializeTerminal() async {
    try {
      // 1. Load Scan Point
      final scanPoint = await ScanPointService.getScanPointById(widget.scanPointId);
      if (scanPoint == null) throw Exception('Scan Point not found');

      // 2. Initialize Strategy
      ScannerModeStrategy strategy;
      switch (widget.scanMode) {
        case 'access':
          strategy = AccessScannerStrategy();
          break;
        case 'commerce':
          strategy = CommerceScannerStrategy();
          break;
        case 'library':
        case 'library_borrow':
        case 'library_return':
          strategy = LibraryScannerStrategy();
          break;
        case 'event':
          strategy = EventScannerStrategy();
          break;
        default:
          throw Exception('Unknown scan mode: ${widget.scanMode}');
      }

      // 3. Setup Debug Callback
      strategy.onDebugInfo = (info) {
        if (mounted) {
          setState(() {
            _debugLogs.add(info);
          });
          // Auto-scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_logScrollController.hasClients) {
              _logScrollController.animateTo(
                _logScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      };

      // 4. Trigger Strategy
      await strategy.onTriggerReceived(scanPoint);

      if (mounted) {
        setState(() {
          _scanPoint = scanPoint;
          _strategy = strategy;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_strategy == null || _scanPoint == null) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _strategy!.onQrScanned(barcode.rawValue!, _scanPoint!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onClose,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Left: Scanner View (2/3 width)
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                // Overlay UI from Strategy
                if (_strategy != null)
                  _strategy!.buildUI(context) ?? const SizedBox.shrink(),
                
                // Demo Mode Badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.science, size: 16, color: Colors.black87),
                        SizedBox(width: 4),
                        Text(
                          'DEMO MODE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Debug Panel
          Expanded(
            flex: 1,
            child: DemoModePanel(
              logs: _debugLogs,
              scrollController: _logScrollController,
              onClearLogs: () {
                setState(() {
                  _debugLogs.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
