// lib/scanner_modules/commerce/commerce_scanner_controller.dart

/// Controller for managing commerce/payment scanner state
///
/// This controller maintains the payment context during commerce scanning:
/// - Payment amount
/// - Cart items
/// - Active state
///
/// Unlike library scanner (two-step), commerce is single-step:
/// Desktop triggers with payment details → scan customer QR → process payment → complete
class CommerceScannerController {
  // Private state variables
  bool _isActive = false;
  double? _paymentAmount;
  List<Map<String, dynamic>>? _cartItems;
  String? _customerUid;
  String? _customerEmail;

  // ==================== Getters ====================

  /// Whether the controller is currently active
  bool get isActive => _isActive;

  /// Payment amount to be processed
  double? get paymentAmount => _paymentAmount;

  /// Cart items for this transaction
  List<Map<String, dynamic>>? get cartItems => _cartItems;

  /// Number of items in cart
  int get itemCount => _cartItems?.length ?? 0;

  /// Customer UID after scan
  String? get customerUid => _customerUid;

  /// Customer email for display
  String? get customerEmail => _customerEmail;

  /// Payment scanner is always single-step (step 1 of 1)
  int get currentStep => 1;

  /// Payment is complete when customer is scanned (progress = 1.0)
  double get progress => _customerUid != null ? 1.0 : 0.0;

  /// Status message for UI display
  String get statusMessage {
    if (!_isActive) return 'Payment Mode Inactive';
    if (_customerUid != null) {
      return 'Customer Scanned — Processing Payment';
    }
    return 'Payment Mode Active';
  }

  /// Instruction message for scanner UI
  String get instructionMessage {
    if (!_isActive) return '';
    if (_customerUid != null) {
      return 'Processing transaction...';
    }
    if (_paymentAmount != null) {
      return 'Scan customer QR to process RM ${_paymentAmount!.toStringAsFixed(2)}';
    }
    return 'Scan customer QR code';
  }

  /// Payment details for display
  String get paymentSummary {
    if (_paymentAmount == null) return '';
    final amount = _paymentAmount!.toStringAsFixed(2);
    final items = itemCount;
    return 'RM $amount • $items item${items == 1 ? '' : 's'}';
  }

  // ==================== Lifecycle Methods ====================

  /// Activate the controller with payment details
  void activate({
    required double amount,
    List<Map<String, dynamic>>? cartItems,
  }) {
    _isActive = true;
    _paymentAmount = amount;
    _cartItems = cartItems;
    _customerUid = null;
    _customerEmail = null;
  }

  /// Set customer details after successful scan
  void setCustomer({required String uid, String? email}) {
    _customerUid = uid;
    _customerEmail = email;
  }

  /// Reset the controller to initial state
  void reset() {
    _isActive = false;
    _paymentAmount = null;
    _cartItems = null;
    _customerUid = null;
    _customerEmail = null;
  }

  /// Check if controller is awaiting customer scan
  bool get isAwaitingCustomer => _isActive && _customerUid == null;

  /// Check if customer has been scanned
  bool get isCustomerScanned => _customerUid != null;
}
