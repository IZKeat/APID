// lib/pages_common/mobile_scanner_terminal.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import '../widgets/jelly_status_views.dart'; // 🍬 Jelly Views
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ✨ Animation
import 'package:apid/pages_admin/theme/jelly_theme.dart'; // 🎨 Jelly Theme
import '../routes.dart';
import '../services/scan_point_service.dart';
import '../services/trigger_communication_service.dart';
import '../services/generic_qr_processing_service.dart';
import '../services/scanner_notification_service.dart';
import '../services/storage_service.dart'; // 💾 Storage
import '../utils/scanner_lifecycle_controller.dart';
// import '../utils/scanner_debug_helper.dart';
import '../scanner_modules/scanner_mode_strategy.dart';
import '../scanner_modules/library/library_scanner_strategy.dart';
import '../scanner_modules/commerce/commerce_scanner_strategy.dart';
import '../scanner_modules/access/access_scanner_strategy.dart';
import '../scanner_modules/event/event_scanner_strategy.dart';
import '../widgets/scanner_status_header.dart';
import '../widgets/scanner_camera_view.dart';
import '../widgets/scanner_waiting_view.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // 🔌 Network Awareness

/// 🚦 Scanner UI State Machine
enum ScannerUiState {
  loading,    // Initial loading
  idle,       // Waiting for trigger
  scanning,   // Camera active
  processing, // Full-screen processing animation
  success,    // Full-screen success animation
  error,      // Full-screen error display
}

/// 🎯 Mobile Scanner Terminal
/// Mobile scanner terminal for Merchant use
/// Functions: Await Desktop trigger -> Auto-open camera -> Scan QR -> Process Result
class MobileScannerTerminal extends StatefulWidget {
  const MobileScannerTerminal({super.key});

  @override
  State<MobileScannerTerminal> createState() => _MobileScannerTerminalState();
}

class _MobileScannerTerminalState extends State<MobileScannerTerminal> with SingleTickerProviderStateMixin {
  // Use shared scanner lifecycle controller
  MobileScannerController get _controller =>
      ScannerLifecycleController.controller;

  StreamSubscription<DocumentSnapshot>? _merchantTriggerSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription; // 🔌 Listener

  // Scanner mode strategy (for modular scanner modes)
  ScannerModeStrategy? _currentStrategy;

  // New state variables for QR processing
  ScanPoint? _currentScanPoint;
  
  // 🏗️ State Machine
  ScannerUiState _uiState = ScannerUiState.loading;
  String? _errorMessage;
  String? _successMessage; // Message to display on success screen
  Map<String, dynamic>? _successData; // Extra data for success screen (e.g. user info)
  
  // 🛡️ Poka-Yoke: Network Awareness
  bool _isOfflineMode = false;
  late AnimationController _shakeController; // For "No" gesture

  @override
  void initState() {
    super.initState();
    print('\n🟢🟢🟢 [Mobile Terminal] initState() CALLED 🟢🟢🟢');

    // Initialize Shake Animation (for rejection)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Initialize scanner lifecycle controller
    ScannerLifecycleController.initialize(
      onStateReset: () {
        if (mounted) setState(() {});
      },
    );

    // 🛡️ Start Network Monitoring
    _initNetworkMonitoring();

    // Load current scan point with caching strategy
    _loadCurrentScanPoint();
  }

  // 🔌 Setup Real-time Network Monitoring
  void _initNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      
      if (_isOfflineMode != isOffline) {
        // State changed
        if (mounted) {
           setState(() {
             _isOfflineMode = isOffline;
           });
           
           if (!isOffline) {
             // 🟢 Network Restored
             print('🟢 [Mobile Terminal] Network Restored');
             ScannerNotificationService.showInfo(
               context: context, 
               message: '🟢 Connection Restored'
             );
             // Verify configuration again just in case
             if (_currentScanPoint == null) _loadCurrentScanPoint();
           } else {
             // 🔴 Network Lost
             print('🔴 [Mobile Terminal] Network Lost');
             // Trigger Haptic to warn user immediately
             HapticFeedback.mediumImpact();
           }
        }
      }
    });
  }

  /// Load the current scan point with retry and cache fallback
  Future<void> _loadCurrentScanPoint() async {
    setState(() {
      _uiState = ScannerUiState.loading;
      _errorMessage = null;
    });

    try {
      print('📍 [Mobile Terminal] Loading scan point...');
      
      // 1. Try Network Load
      final scanPoint = await ScanPointService.getCurrentScanPointForLoggedInUser();

      if (scanPoint != null) {
        // ✅ Success: Cache it
        await StorageService().saveLastScanPoint(
          id: scanPoint.scanPointId,
          name: scanPoint.name,
          type: scanPoint.type,
        );
        
        if (mounted) {
          setState(() {
            _currentScanPoint = scanPoint;
            _uiState = ScannerUiState.idle;
            // _isOfflineMode = false; // Handled by listener now
          });
        }
        _listenForMerchantTriggers();
      } else {
        throw Exception("No scan point found for this user.");
      }

    } catch (e) {
      print('⚠️ [Mobile Terminal] Network load failed: $e');
      
      // 2. Fallback to Cache
      final cached = await StorageService().getLastScanPoint();
      if (cached != null) {
        print('💾 [Mobile Terminal] Using cached scan point');
        if (mounted) {
          setState(() {
            _currentScanPoint = ScanPoint(
              id: 'cached_doc_id', // Dummy ID for cache
              scanPointId: cached['scan_point_id']!,
              name: cached['name']!,
              type: cached['type']!,
              ownerUid: FirebaseAuth.instance.currentUser?.uid ?? '',
              active: true, // ⚠️ Assume active if cached
            );
            _uiState = ScannerUiState.idle;
          });
        }
        
        if (mounted) {
           ScannerNotificationService.showInfo(
             context: context, 
             message: 'Using cached configuration'
           );
        }
        // Even in offline mode, we try to listen (it might reconnect)
        _listenForMerchantTriggers();
      } else {
        // 3. Total Failure
        if (mounted) {
          setState(() {
            _uiState = ScannerUiState.error;
            _errorMessage = "Failed to load configuration. Please check internet.";
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _merchantTriggerSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _shakeController.dispose();
    ScannerLifecycleController.dispose();
    super.dispose();
  }

  /// 🎯 NEW: Listen for unified triggers (scan_point_id based)
  void _listenForMerchantTriggers() {
    if (_currentScanPoint == null) return;

    final scanPointId = _currentScanPoint!.scanPointId;
    print('📱 [Mobile Terminal] Listening to path: scanner_triggers/$scanPointId');

    _merchantTriggerSubscription = TriggerCommunicationService.listen(
      scanPointId: scanPointId,
      onTrigger: (scanMode, scanPointId, data) async {
        if (!mounted) return;
        
        // 🔔 Toast Feedback for better UX
        ScannerNotificationService.showInfo(
          context: context, 
          message: '📡 Signal Received: Starting $scanMode scanner...'
        );
        
        _handleUnifiedTrigger(scanMode, scanPointId, data);
      },
      onStop: _handleStopTrigger,
      onError: (error) {
        print('❌ [Mobile Terminal] Trigger listener error: $error');
      },
    );
  }

  /// Handle the unified trigger format
  void _handleUnifiedTrigger(
    String scanMode,
    String scanPointId,
    Map<String, dynamic> data,
  ) async {
    if (_currentStrategy != null) {
      print('⚠️ [Mobile Terminal] Already in a mode, ignoring trigger');
      return;
    }
    
    // 🛡️ Block remote triggers if offline (though unlikely to receive one if offline)
    if (_isOfflineMode) {
      print('🛡️ [Network] Ignoring trigger due to offline mode');
      return;
    }

    try {
      print('🎯 [Mobile Terminal] Processing scan_mode: $scanMode');

      // Route based on scan_mode
      switch (scanMode) {
        case 'library':
        case 'library_borrow':
          _activateStrategy(LibraryScannerStrategy()..setMode('borrow'), data);
          break;
        case 'library_return':
          _activateStrategy(LibraryScannerStrategy()..setMode('return'), data);
          break;
        case 'commerce':
          _activateStrategy(CommerceScannerStrategy(), data);
          break;
        case 'booking':
           _startScanning(); // Simple mode
          break;
        case 'access':
          _activateStrategy(AccessScannerStrategy(), data);
          break;
        case 'event':
          _activateStrategy(EventScannerStrategy(), data);
          break;
        default:
          print('⚠️ [Mobile Terminal] Unknown scan_mode: $scanMode');
      }
    } catch (e) {
      print('❌ [Mobile Terminal] Error handling trigger: $e');
    }
  }

  // 🛠 Helper to reduce boilerplate
  void _activateStrategy(ScannerModeStrategy strategy, Map<String, dynamic> data) async {
    _currentStrategy = strategy;
    
    // UI Rebuild Callback
    strategy.onStateChanged = () { if (mounted) setState(() {}); };

    // Finished Callback
    strategy.onStrategyFinished = () {
      print('🔄 [Mobile Terminal] Strategy finished');
      if (mounted) {
        setState(() {
          _currentStrategy = null;
          ScannerLifecycleController.setProcessing(false);
          _uiState = ScannerUiState.idle; // Return to idle
        });
      }
      ScannerLifecycleController.stopScanning();
    };

    if (_currentScanPoint != null) {
      await strategy.onTriggerReceived(_currentScanPoint!, data: data);
    }

    if (mounted) await _startScanning();
  }

  /// 🛑 Handle stop trigger from desktop
  void _handleStopTrigger() {
    print('🛑 [Mobile Terminal] Stop trigger received from desktop');
    
    if (_currentStrategy != null) {
      // Check if strategy wants to block the stop (e.g., to show success animation)
      if (!_currentStrategy!.shouldHandleStopTrigger) {
        print('🛡️ [Mobile Terminal] Strategy blocked stop trigger');
        return;
      }

      if (mounted) {
        ScannerNotificationService.showInfo(
          context: context, 
          message: 'Scanner stopped by desktop'
        );
        setState(() {
          _currentStrategy = null;
          ScannerLifecycleController.setProcessing(false);
          _uiState = ScannerUiState.idle;
        });
      }
      ScannerLifecycleController.stopScanning();
    }
  }

  /// 🎥 Start Scanner (Robust Start)
  Future<void> _startScanning() async {
    if (!mounted) return;
    
    // 🛡️ Block start if offline
    if (_isOfflineMode) {
      _rejectAction("Cannot scan while offline");
      return;
    }

    await ScannerLifecycleController.startScanning(
      context: context,
      onRetry: (attempt) {
        // 🔄 Show non-intrusive feedback during auto-retry
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('⚠️ Camera glitch. Retrying (Attempt $attempt/3)...'),
               backgroundColor: JellyTheme.warning,
               duration: const Duration(milliseconds: 1500),
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      },
      onScannerReady: () {
        print('📸 [Mobile Terminal] Camera ready, switching UI to scanning');
        if (mounted) {
          setState(() {
            _uiState = ScannerUiState.scanning;
          });
        }
      },
      onScannerFailed: (error) {
        if (mounted) {
          // Only show full error screen if ALL retries fail
          setState(() {
            _uiState = ScannerUiState.error;
            _errorMessage = "Camera failed after retries: $error";
          });
        }
      },
    );
  }

  /// 🚨 Emergency Manual Start
  void _startManualScanning() {
    // 🛡️ Poka-Yoke: Block if offline with aggressive feedback
    if (_isOfflineMode) {
      _rejectAction("Offline: Cannot start scanner");
      return;
    }

    if (_currentScanPoint == null) return;
    
    print('🚨 [Mobile Terminal] Manual Start Triggered');
    _startScanning();
  }
  
  /// 🛡️ Reject Action with "Shake Head" Logic
  void _rejectAction(String reason) {
    HapticFeedback.heavyImpact(); // 📳 Tactile Rejection
    _shakeController.forward(from: 0.0); // ↔️ Visual Rejection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
           const Icon(Icons.cloud_off, color: Colors.white),
           const SizedBox(width: 8),
           Text(reason),
        ]),
        backgroundColor: JellyTheme.error.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 📱 Process QR Scan Result
  Future<void> _processQrCode(String rawValue) async {
    // 🛡️ Poka-Yoke: Final Gatekeeper
    if (_isOfflineMode) {
      print('🛡️ [Network] Blocking scan due to offline mode');
      // No haptic here to avoid spamming if camera is somehow running
      return; 
    }
  
    if (!ScannerLifecycleController.shouldProcessQr(rawValue)) return;

    // Set processing state
    ScannerLifecycleController.setProcessing(
      true,
      onUpdate: () { if (mounted) setState(() {}); },
    );
    ScannerLifecycleController.setLastScanResult(
      rawValue,
      onUpdate: () { if (mounted) setState(() {}); },
    );

    final user = FirebaseAuth.instance.currentUser;

    try {
      // Update Firestore status
      if (user != null && !_isOfflineMode) {
        await FirebaseFirestore.instance
            .collection('scanner_status')
            .doc(user.uid)
            .set({
              'state': 'PROCESSING',
              'status': 'processing',
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      // 1. 🖥️ Desktop Login (Priority 1)
      if (rawValue.startsWith('auth://login')) {
        await _processDesktopLogin(rawValue, user!);
        return;
      }

      // Delegate to Strategy or Generic
      if (_currentStrategy != null && _currentScanPoint != null) {
        await _currentStrategy!.onQrScanned(rawValue, _currentScanPoint!);
      } else if (_currentScanPoint != null) {
        await GenericQrProcessingService.handle(
          rawValue: rawValue,
          scanPoint: _currentScanPoint!,
          context: context,
          activeStrategy: _currentStrategy,
        );
      }
    } catch (e) {
      print('❌ [Mobile Terminal] Error in QR processing: $e');
      if (mounted) {
        setState(() {
          _uiState = ScannerUiState.error;
          _errorMessage = "Processing failed: $e";
        });
      }
    } finally {
      // If not desktop login (which handles its own state), reset processing
      if (!rawValue.startsWith('auth://login') && _currentStrategy == null) {
        ScannerLifecycleController.setProcessing(
          false,
          onUpdate: () { if (mounted) setState(() {}); },
        );

        if (user != null && mounted && ScannerLifecycleController.isScanning && !_isOfflineMode) {
           await FirebaseFirestore.instance
            .collection('scanner_status')
            .doc(user.uid)
            .set({
              'state': 'ACTIVE',
              'status': 'active',
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        }
      }
    }
  }

  /// 🖥️ Process Desktop Login Authorization
  /// Refactored to use full-screen state flow instead of Dialog
  Future<void> _processDesktopLogin(String rawValue, User user) async {
    try {
      final uri = Uri.parse(rawValue);
      final sessionId = uri.queryParameters['session'];

      if (sessionId == null) throw Exception("Invalid Login QR");

      // 1. Stop Scanning & Show Processing Screen
      await ScannerLifecycleController.stopScanning();
      
      // FIX: Ensure processing flag is cleared so overlay doesn't stick
      ScannerLifecycleController.setProcessing(false);

      if (!mounted) return;
      
      setState(() {
        _uiState = ScannerUiState.processing;
      });

      // Simulate a small delay for "Processing" feel (and to let animation play)
      await Future.delayed(const Duration(seconds: 2));

      // 2. Authorize in Firestore
      await FirebaseFirestore.instance.collection('login_sessions').doc(sessionId).update({
        'status': 'authorized',
        'uid': user.uid,
        'email': user.email,
        'authorized_at': FieldValue.serverTimestamp(),
      });

      // 3. Show Success Screen
      if (mounted) {
        setState(() {
          _uiState = ScannerUiState.success;
          _successMessage = "Desktop Login Authorized";
          _successData = {
            'email': user.email,
            'name': user.displayName ?? 'Merchant',
            'timestamp': DateTime.now(),
          };
        });
      }

    } catch (e) {
      print("Login Error: $e");
      if (mounted) {
        setState(() {
          _uiState = ScannerUiState.error;
          _errorMessage = "Authorization Failed: $e";
        });
      }
    }
  }

  /// Reset to Idle state (called from Success/Error screens)
  void _resetToIdle() {
    setState(() {
      _uiState = ScannerUiState.idle;
      _errorMessage = null;
      _successMessage = null;
      _successData = null;
    });
    // Don't restart scanner automatically, wait for user or trigger
  }

  @override
  Widget build(BuildContext context) {
    // 🏗️ Wrap with Shake Animation for "No" feedback
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final sineValue = 5.0 * 2 * (0.5 - (0.5 - _shakeController.value).abs()); // Simple shake
        return Transform.translate(
          offset: Offset(sineValue * 5, 0),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Main Content
          _buildMainContent(context),
          
          // 🛑 Offline Banner (Jelly Style)
          if (_isOfflineMode)
             Positioned(
               top: MediaQuery.of(context).padding.top + 8,
               left: 16,
               right: 16,
               child: _buildOfflineBanner(),
             ).animate().scale(curve: Curves.elasticOut, duration: 600.ms).fadeIn(),
        ],
      ),
    );
  }
  
  // 🍬 Build Jelly Offline Banner
  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: JellyTheme.error.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20), // Pill shape
        boxShadow: [
          BoxShadow(
            color: JellyTheme.error.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Hug content
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            "Offline Mode - Scanning Paused",
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    // 1. Loading State
    if (_uiState == ScannerUiState.loading) {
      return Scaffold(
        backgroundColor: JellyTheme.background,
        body: const Center(
          child: JellyProcessingView(), // Reuse processing view for loading
        ),
      );
    }

    // 2. Error State (Full Screen)
    if (_uiState == ScannerUiState.error) {
      return JellyErrorView(
        errorMessage: _errorMessage ?? "Unknown Error",
        onRetry: _loadCurrentScanPoint,
        onBack: _currentScanPoint != null ? _resetToIdle : null,
      );
    }

    // 3. Processing State (Full Screen)
    if (_uiState == ScannerUiState.processing) {
      return const Scaffold(
        backgroundColor: Colors.transparent, // Let blur show through if needed, or opaque
        body: JellyProcessingView(),
      );
    }

    // 4. Success State (Full Screen)
    if (_uiState == ScannerUiState.success) {
      return JellySuccessView(
        message: _successMessage ?? "Success!",
        data: _successData,
        onDone: _resetToIdle,
      );
    }

    // 5. Main Terminal UI (Idle & Scanning)
    return Scaffold(
      backgroundColor: JellyTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mobile Scanner Terminal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            // Replaced icon with full banner, but keep minimal icon here too just in case
            if (_isOfflineMode) ...[
              const SizedBox(width: 8),
              // const Icon(Icons.wifi_off, size: 16, color: Colors.white70),
            ]
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: JellyTheme.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: JellyTheme.error),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (route) => false);
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          ScannerStatusHeader(
            isScanning: _uiState == ScannerUiState.scanning,
            isProcessing: ScannerLifecycleController.isProcessing,
            scanPoint: _currentScanPoint,
          ),

          Expanded(
            child: _uiState == ScannerUiState.scanning
                ? Stack( // 🏗️ Wrap Camera with Color Filter for Offline
                    children: [
                      ScannerCameraView(
                        controller: _controller,
                        isProcessing: ScannerLifecycleController.isProcessing,
                        strategyOverlay: _currentStrategy?.buildUI(context),
                        scanFrameType: _currentStrategy?.getScanFrameType() ?? 'qr',
                        onQrDetected: _processQrCode,
                      ),
                      // 👽 Offline Overlay (If camera somehow stays open)
                      if (_isOfflineMode)
                        Container(
                           color: Colors.black.withOpacity(0.7),
                           child: const Center(
                             child: Icon(Icons.videocam_off_rounded, size: 64, color: Colors.white54),
                           ),
                        ),
                    ],
                  )
                : Stack(
                    children: [
                      // ✨ Enhanced Waiting View with Manual Trigger
                      ScannerWaitingView(
                        scanPoint: _currentScanPoint,
                        onManualStart: _startManualScanning, // 🚨 Emergency Mode
                      ),
                      // If processing happens while in Idle/Waiting state (rare, but possible)
                      if (ScannerLifecycleController.isProcessing)
                         const Positioned.fill(child: JellyProcessingView()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Kept for reference but unused if we use JellyProcessingView everywhere
  // Or we can use it as a non-blocking overlay
  Widget _buildProcessingOverlay() {
    return const Positioned.fill(child: JellyProcessingView());
  }
}


