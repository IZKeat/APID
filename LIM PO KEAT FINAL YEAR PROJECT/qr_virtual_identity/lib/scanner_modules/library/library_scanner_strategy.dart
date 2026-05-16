// lib/scanner_modules/library/library_scanner_strategy.dart

import 'package:flutter/material.dart';
import '../scanner_mode_strategy.dart';
import '../../services/scan_point_service.dart';
import '../../utils/qr_parser.dart';
import '../../utils/scanner_lifecycle_controller.dart';
import 'library_scanner_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/library_service.dart'; // Import local service
import '../../utils/error_mapper.dart';
import '../../widgets/scan_success_overlay.dart';
import '../../utils/audio_helper.dart'; // 🔊 Audio
import 'dart:async'; // ⏱️ Timer
import '../../widgets/jelly_status_views.dart'; // 🍬 Jelly Views
import '../../widgets/jelly_card.dart'; // 🃏 Jelly Card
import '../../pages_admin/theme/jelly_theme.dart'; // 🎨 Jelly Theme
import 'package:google_fonts/google_fonts.dart'; // 🔤 Fonts
import 'package:flutter_animate/flutter_animate.dart'; // ✨ Animation
import 'dart:ui'; // 🌫️ ImageFilter

/// 📚 Library Scanner Strategy
/// Implements library workflows:
/// - Borrow Mode: two-step (student scan → book scan)
/// - Return Mode: one-step (book scan only)
///
/// **Borrow Workflow**:
/// 1. Desktop triggers 'library_borrow' mode
/// 2. Mobile scans student QR (user verification)
/// 3. Student verified → prompt for book scan
/// 4. Mobile scans book QR (borrow processing)
/// 5. Loan created → complete
///
/// **Return Workflow**:
/// 1. Desktop triggers 'library_return' mode
/// 2. Mobile scans book QR only (return processing)
/// 3. Loan closed → complete
/// 🚦 Library UI State Machine
enum LibraryUiState {
  idle,           // Waiting for scan
  processing,     // API call in progress
  success_step1,  // Student verified (Green check)
  success_step2,  // Book processed (Green check)
  error,          // Error occurred (Red X)
}

class LibraryScannerStrategy implements ScannerModeStrategy {
  @override
  bool get shouldHandleStopTrigger {
    // FIX: Block stop trigger if we are showing success feedback OR processing
    // This prevents race conditions where desktop stops before mobile gets success response
    return _uiState != LibraryUiState.success_step1 && 
           _uiState != LibraryUiState.success_step2 &&
           _uiState != LibraryUiState.processing;
  }
  @override
  String get scanMode =>
      controller.mode == 'return' ? 'library_return' : 'library_borrow';

  @override
  Function(Map<String, dynamic> info)? onDebugInfo;

  /// Library-specific state controller
  final LibraryScannerController controller = LibraryScannerController();

  /// Callback to notify when strategy is finished (for cleanup)
  @override
  VoidCallback? onStrategyFinished;

  /// Callback to trigger UI rebuild in parent widget
  @override
  VoidCallback? onStateChanged;

  /// 🏗️ UI State Machine
  LibraryUiState _uiState = LibraryUiState.idle;
  LibraryUiState get uiState => _uiState;

  /// Error message state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Timer for auto-advancing steps
  Timer? _autoAdvanceTimer;

  /// BuildContext for showing snackbars and dialogs
  BuildContext? _context;

  /// Current scan point
  ScanPoint? _scanPoint;

  /// Set library mode (borrow/return)
  void setMode(String mode) {
    controller.activate(mode: mode);
  }

  @override
  Future<void> onTriggerReceived(
    ScanPoint scanPoint, {
    Map<String, dynamic>? data,
  }) async {
    _scanPoint = scanPoint;
    
    // FIX: Ensure mode is set from trigger data (Failsafe)
    if (data != null && data['scan_mode'] != null) {
      final scanMode = data['scan_mode'] as String;
      if (scanMode == 'library_return') {
        setMode('return');
      } else if (scanMode == 'library_borrow' || scanMode == 'library') {
        setMode('borrow');
      }
    }

    print(
      '📚 [LibraryStrategy] Trigger received for scan point: ${scanPoint.name}, Mode: ${controller.mode}',
    );
  }

  @override
  Future<void> onQrScanned(String rawValue, ScanPoint scanPoint) async {
    _scanPoint = scanPoint;

    // Prevent scanning if we are already processing or showing a result
    if (_uiState != LibraryUiState.idle) {
      print('⚠️ [LibraryStrategy] Ignoring scan, UI state is $_uiState');
      return;
    }

    // Return mode: only scan book
    if (controller.isReturnMode) {
      await _handleBookScan(rawValue);
      return;
    }

    // Borrow mode: two-step workflow
    // Step 1: Student scan
    if (controller.isAwaitingStudent) {
      await _handleStudentScan(rawValue);
    }
    // Step 2: Book scan
    else if (controller.isAwaitingBook) {
      await _handleBookScan(rawValue);
    }
  }

  /// Handle student QR scan (step 1)
  Future<void> _handleStudentScan(String rawValue) async {
    final startTime = DateTime.now();
    
    // 1. Set Processing State
    _setUiState(LibraryUiState.processing);
    ScannerLifecycleController.setProcessing(true);

    try {
      print('📚 [LibraryStrategy] Processing student scan: $rawValue');

      // Parse QR code
      final result = QRParser.parse(rawValue);

      if (!result.isValid || result.type != QrType.user) {
        throw Exception('Invalid student code. Please scan a student QR code.');
      }

      if (result.isExpired) {
        throw Exception('QR Code Expired. Please refresh.');
      }

      final studentUid = result.userId;
      if (studentUid == null || studentUid.isEmpty) {
        throw Exception('Invalid student ID in QR code');
      }

      // Check scan point
      if (_scanPoint == null) {
        _scanPoint = await ScanPointService.getCurrentScanPointForLoggedInUser();
      }

      if (_scanPoint == null) {
        throw Exception('No scan point assigned to this device');
      }

      final scanPointId = _scanPoint!.scanPointId;
      if (scanPointId.isEmpty) {
        throw Exception('Invalid Scan Point Configuration (Empty ID)');
      }

      final payload = {
        'scanType': 'user',
        'uid': result.userId,
        'scanPointId': scanPointId.trim(),
        'timestamp': result.timestamp,
        'ts': result.timestamp,
        'nonce': result.nonce,
        'sig': result.sig,
      };

      // Process via Local Service (Fast)
      final response = await LibraryService.processUser(
        userId: result.userId!,
        scanPoint: _scanPoint!,
        // Security parameters from QR
        timestamp: result.timestamp,
        nonce: result.nonce,
        signature: result.sig,
      );

      ScannerLifecycleController.setProcessing(false); // Resume UI updates

      if (response.success) {
        // Extract student name
        final data = response.data ?? {};
        // Note: LibraryService might not return student_name in data immediately, 
        // unlike Cloud Function which did a lookup.
        // We can use the name from the QR code as a fallback or assume the service verified the ID.
        // If the service doesn't return the name, we use the QR name.
        final studentName = data['student_name'] as String? ?? result.name ?? 'Student';

        // Update Controller
        controller.setStudent(studentUid, studentName: studentName);
        
        _emitDebugInfo(rawValue, 'success', 'Student Verified: $studentName', startTime, backendResponse: data);

        // 2. Show Success State (Step 1)
        _setUiState(LibraryUiState.success_step1);
        await AudioHelper.playSuccess();

        // 3. Auto-Advance Timer (2 seconds)
        _autoAdvanceTimer?.cancel();
        _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
          print('⏱️ [LibraryStrategy] Auto-advancing to Step 2');
          _setUiState(LibraryUiState.idle); // Ready for next scan
          ScannerLifecycleController.setProcessing(false); // Resume camera
          
          // Restart scanner explicitly to ensure it's active
          if (_context != null) {
             ScannerLifecycleController.startScanning(
               context: _context!,
               onScannerReady: () => print('📸 [LibraryStrategy] Scanner ready for book'),
             );
          }
        });

      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      print('❌ [LibraryStrategy] Error in student scan: $e');
      final friendlyError = mapBackendError(e);
      _emitDebugInfo(rawValue, 'error', 'Exception: $e', startTime);
      await AudioHelper.playError();
      
      // Show Error State
      _errorMessage = friendlyError;
      _setUiState(LibraryUiState.error);
      ScannerLifecycleController.setProcessing(false);
    }
  }

  /// Handle book QR scan (step 2)
  Future<void> _handleBookScan(String rawValue) async {
    final startTime = DateTime.now();
    
    // 1. Set Processing State
    _setUiState(LibraryUiState.processing);
    ScannerLifecycleController.setProcessing(true);

    try {
      print('📚 [LibraryStrategy] Processing book scan: $rawValue');

      // Parse QR code
      final result = QRParser.parse(rawValue);

      if (!result.isValid || result.type != QrType.item) {
        throw Exception('Invalid book code. Please scan a book barcode or QR code.');
      }

      final itemId = result.itemId;
      if (itemId == null || itemId.isEmpty) {
        throw Exception('Invalid book ID in QR code');
      }

      if (_scanPoint == null) {
        throw Exception('No scan point assigned to this device');
      }

      // Execute borrow or return via Local Service
      final response = await LibraryService.processItem(
        itemId: itemId,
        scanPoint: _scanPoint!,
        mode: controller.mode ?? 'borrow', // Explicitly pass mode
      );

      ScannerLifecycleController.setProcessing(false); // Resume UI updates

      if (!response.success) {
        throw Exception(response.message);
      }

      // Success!
      final data = response.data ?? {};
      final loanType = data['loan_type'] ?? 'processed';
      final bookTitle = data['book_title'] ?? 'Book';

      // Update controller
      controller.setBook(bookTitle);
      controller.setOperationType(loanType);
      
      _emitDebugInfo(rawValue, 'success', 'Book Processed: $bookTitle', startTime, backendResponse: data);

      // 2. Show Success State (Step 2 - Final)
      _setUiState(LibraryUiState.success_step2);
      await AudioHelper.playSuccess();

      // 3. Auto-Complete Timer (3 seconds)
      _autoAdvanceTimer?.cancel();
      _autoAdvanceTimer = Timer(const Duration(seconds: 3), () async {
        print('⏱️ [LibraryStrategy] Auto-completing workflow');
        await onScanComplete();
      });

    } catch (e) {
      print('❌ [LibraryStrategy] Error in book scan: $e');
      final friendlyError = mapBackendError(e);
      _emitDebugInfo(rawValue, 'error', 'Exception: $e', startTime);
      await AudioHelper.playError();
      
      // Show Error State
      _errorMessage = friendlyError;
      _setUiState(LibraryUiState.error);
      ScannerLifecycleController.setProcessing(false);
    }
  }

  /// Helper to update UI state and notify listeners
  void _setUiState(LibraryUiState state) {
    _uiState = state;
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  /// Retry action for Error State
  void retry() {
    _setUiState(LibraryUiState.idle);
    ScannerLifecycleController.setProcessing(false);
    // Resume scanner
    if (_context != null) {
       ScannerLifecycleController.startScanning(
         context: _context!,
         onScannerReady: () {},
       );
    }
  }

  void _emitDebugInfo(String rawQr, String result, String message, DateTime startTime, {Map<String, dynamic>? backendResponse}) {
    if (onDebugInfo != null) {
      onDebugInfo!({
        'mode': 'library',
        'scanPoint': _scanPoint?.name ?? 'Unknown',
        'timestamp': DateTime.now().toIso8601String(),
        'rawQr': _maskQr(rawQr),
        'result': result,
        'latencyMs': DateTime.now().difference(startTime).inMilliseconds,
        'message': message,
        'backendResponse': backendResponse,
      });
    }
  }

  String _maskQr(String qr) {
    if (qr.length <= 10) return '***';
    return '${qr.substring(0, 5)}...${qr.substring(qr.length - 5)}';
  }

  @override
  Future<void> onScanComplete() async {
    print('📚 [LibraryStrategy] Scan complete, cleaning up...');
    
    _autoAdvanceTimer?.cancel();

    // Notify desktop scanner stopped
    await _notifyDesktopScannerStopped();

    // Reset library state
    controller.reset();
    _setUiState(LibraryUiState.idle);

    // Stop scanner
    await ScannerLifecycleController.stopScanning();

    print('📚 [LibraryStrategy] Library mode exited');

    // Notify MobileScannerTerminal to clear strategy
    if (onStrategyFinished != null) {
      onStrategyFinished!();
    }
  }

  @override
  Future<void> onScanError(String error) async {
    _errorMessage = error;
    _setUiState(LibraryUiState.error);
  }

  @override
  Widget? buildUI(BuildContext context) {
    _context = context;

    if (!controller.isActive) return null;

    // 1. Processing State (Full Screen Overlay)
    if (_uiState == LibraryUiState.processing) {
      return const Positioned.fill(
        child: JellyProcessingView(), // Fixed: No message param
      );
    }

    // 2. Success State - Step 1 (Student Verified)
    if (_uiState == LibraryUiState.success_step1) {
      return Positioned.fill(
        child: JellySuccessView(
          message: "Student Verified",
          data: {
            'name': controller.currentStudentName ?? 'Student',
            'id': controller.currentStudentId ?? '',
          },
          onDone: () {}, // Fixed: Added required onDone (timer handles advance)
        ),
      );
    }

    // 3. Success State - Step 2 (Book Processed)
    if (_uiState == LibraryUiState.success_step2) {
      return Positioned.fill(
        child: JellySuccessView(
          message: controller.lastOperationType == 'borrow' 
              ? "Book Borrowed" 
              : "Book Returned",
          data: {
            'title': controller.currentBookTitle ?? 'Book',
            'type': controller.lastOperationType ?? 'Transaction',
          },
          onDone: () {}, // Fixed: Added required onDone (timer handles completion)
        ),
      );
    }

    // 4. Error State (Full Screen with Retry)
    if (_uiState == LibraryUiState.error) {
      return Positioned.fill(
        child: JellyErrorView(
          errorMessage: _errorMessage ?? "Unknown Error",
          onRetry: retry,
          onBack: () {
            // If backing out from error, reset to idle
            _setUiState(LibraryUiState.idle);
            ScannerLifecycleController.setProcessing(false);
          },
        ),
      );
    }

    // 5. Idle/Scanning State (Instruction Overlay)
    return Stack(
      children: [
        // Bottom Card with Instructions
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: _buildInstructionCard(context),
        ),
        
        // Manual Entry Button (Top Right)
        if (controller.isAwaitingBook)
          Positioned(
            top: 60,
            right: 20,
            child: _buildManualEntryButton(context),
          ),
      ],
    );
  }

  /// 🃏 Build the Glassmorphism Instruction Card
  Widget _buildInstructionCard(BuildContext context) {
    return JellyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: JellyTheme.primary.withOpacity(0.1), // Lighter background for icon
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  controller.isBorrowMode ? Icons.library_books : Icons.assignment_return,
                  color: JellyTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.isBorrowMode ? 'Library Borrow' : 'Library Return',
                      style: GoogleFonts.outfit(
                        color: Colors.black87, // Dark text
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      controller.statusMessage,
                      style: GoogleFonts.outfit(
                        color: Colors.black54, // Darker secondary text
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Step Indicator
              if (controller.isBorrowMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: JellyTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: JellyTheme.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    '${controller.currentStep}/${controller.totalSteps}',
                    style: GoogleFonts.outfit(
                      color: JellyTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Instruction Text with Animation
          Text(
            controller.instructionMessage,
            style: GoogleFonts.outfit(
              color: Colors.black87, // Dark text
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ).animate(key: ValueKey(controller.instructionMessage)) // Animate on change
           .fadeIn(duration: 300.ms)
           .slideX(begin: 0.1, end: 0, curve: Curves.easeOutBack),

          // Student Info (if verified)
          if (controller.isAwaitingBook && controller.currentStudentName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JellyTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JellyTheme.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: JellyTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Verified: ${controller.currentStudentName}',
                    style: GoogleFonts.outfit(
                      color: JellyTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().scale(curve: Curves.elasticOut, duration: 400.ms),
          ],
        ],
      ),
    ).animate()
     .slideY(begin: 1.0, end: 0, curve: Curves.elasticOut, duration: 600.ms)
     .fadeIn();
  }

  /// ⌨️ Manual Entry Button (Floating)
  Widget _buildManualEntryButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showManualIsbnEntry(context),
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.keyboard, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Manual ISBN',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 1.0, end: 0);
  }

  @override
  String getScanFrameType() {
    if (controller.isAwaitingBook) {
      return 'barcode';
    }
    return 'qr';
  }

  /// Show dialog for manual ISBN entry
  Future<void> _showManualIsbnEntry(BuildContext context) async {
    final TextEditingController isbnController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Enter ISBN Number'),
          content: TextField(
            controller: isbnController,
            keyboardType: TextInputType.number,
            maxLength: 13,
            decoration: const InputDecoration(hintText: 'e.g., 9780000000002'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final isbn = isbnController.text.trim();
                Navigator.pop(dialogContext, isbn);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _handleBookScan(result);
    }
  }

  /// Notify desktop that mobile scanner has stopped
  Future<void> _notifyDesktopScannerStopped() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(user.uid)
          .set({
            'state': 'IDLE',
            'status': 'idle',
            'updated_at': FieldValue.serverTimestamp(),
          });
      print('📡 [LibraryStrategy] Notified desktop: scanner stopped');
    } catch (e) {
      print('⚠️ [LibraryStrategy] Failed to notify desktop: $e');
    }
  }
}
