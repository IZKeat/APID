// lib/scanner_modules/library/library_scanner_controller.dart

/// 📚 Library Scanner Controller
/// Manages state for library scanning workflow
/// Supports two modes:
/// - Borrow: two-step (student → book)
/// - Return: one-step (book only)
class LibraryScannerController {
  /// Library mode: 'borrow' or 'return'
  String _mode = 'borrow';

  /// Whether we're currently in library mode
  bool _isActive = false;

  /// Student UID after successful first scan (borrow mode only)
  String? _currentStudentId;

  /// Student email (borrow mode only)
  String? _currentStudentEmail;

  /// Student name (optional, for UI display)
  String? _currentStudentName;

  /// Book title (optional, for UI display after book scan)
  String? _currentBookTitle;

  /// Last operation type ('borrow' or 'return')
  String? _lastOperationType;

  /// Get current mode
  String get mode => _mode;

  /// Get whether in borrow mode
  bool get isBorrowMode => _mode == 'borrow';

  /// Get whether in return mode  
  bool get isReturnMode => _mode == 'return';

  /// Get whether library mode is active
  bool get isActive => _isActive;

  /// Get whether waiting for student scan (step 1 of borrow mode)
  bool get isAwaitingStudent => _isActive && isBorrowMode && _currentStudentId == null;

  /// Get whether waiting for book scan
  bool get isAwaitingBook {
    if (!_isActive) return false;
    if (isReturnMode) return true; // Always awaiting book in return mode
    return _currentStudentId != null; // Step 2 in borrow mode
  }

  /// Get current student ID
  String? get currentStudentId => _currentStudentId;

  /// Get current student email
  String? get currentStudentEmail => _currentStudentEmail;

  /// Get current student name
  String? get currentStudentName => _currentStudentName;

  /// Get current book title
  String? get currentBookTitle => _currentBookTitle;

  /// Get last operation type
  String? get lastOperationType => _lastOperationType;

  /// Activate library mode with specified mode
  void activate({String mode = 'borrow'}) {
    print('📚 [LibraryController] Activating library mode: $mode');
    _mode = mode;
    _isActive = true;
    _currentStudentId = null;
    _currentStudentEmail = null;
    _currentStudentName = null;
    _currentBookTitle = null;
    _lastOperationType = null;
  }

  /// Set student after successful first scan (borrow mode only)
  void setStudent(String studentId, {String? studentEmail, String? studentName}) {
    print('📚 [LibraryController] Student set: $studentId');
    _currentStudentId = studentId;
    _currentStudentEmail = studentEmail;
    _currentStudentName = studentName;
  }

  /// Clear current student (return to step 1)
  void clearStudent() {
    print('📚 [LibraryController] Clearing student');
    _currentStudentId = null;
    _currentStudentName = null;
  }

  /// Set book title after successful book scan
  void setBook(String bookTitle) {
    print('📚 [LibraryController] Book set: $bookTitle');
    _currentBookTitle = bookTitle;
  }

  /// Set operation type ('borrow' or 'return')
  void setOperationType(String operationType) {
    print('📚 [LibraryController] Operation type: $operationType');
    _lastOperationType = operationType;
  }

  /// Reset all state and deactivate library mode
  void reset() {
    print('📚 [LibraryController] Resetting library mode');
    _isActive = false;
    _mode = 'borrow';
    _currentStudentId = null;
    _currentStudentEmail = null;
    _currentStudentName = null;
    _currentBookTitle = null;
    _lastOperationType = null;
  }

  /// Get current step number (1 = student, 2 = book for borrow; 1 = book for return)
  int get currentStep {
    if (isReturnMode) return 1;
    return isAwaitingStudent ? 1 : 2;
  }

  /// Get total steps
  int get totalSteps => isBorrowMode ? 2 : 1;

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (isReturnMode) return 0.0; // Waiting for book scan
    return isAwaitingStudent ? 0.5 : 1.0;
  }

  /// Get user-friendly status message
  String get statusMessage {
    if (isReturnMode) {
      return 'Return Mode';
    }
    if (isAwaitingStudent) {
      return 'Step 1: Student Verification';
    }
    return 'Step 2: Book Processing';
  }

  /// Get instruction message
  String get instructionMessage {
    if (isReturnMode) {
      return 'Scan the book barcode to return';
    }
    if (isAwaitingStudent) {
      return 'Scan the student QR code first';
    }
    return 'Now scan the book barcode';
  }
}
