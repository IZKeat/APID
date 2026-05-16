import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:apid/models/cart_item.dart';

enum TransactionStatus {
  idle,
  processing, // Waiting for scan
  scanned,    // QR Scanned, processing payment
  success,    // Payment successful
  error,      // Payment failed
}

class POSController extends ChangeNotifier {
  final String scanPointId;
  final String merchantUid;

  // Data State
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoadingProducts = true;

  // Getters
  List<Map<String, dynamic>> get products => _filteredProducts;
  String get selectedCategory => _selectedCategory;
  bool get isLoadingProducts => _isLoadingProducts;
  
  // Timers & Subscriptions
  StreamSubscription<DocumentSnapshot>? _statusSub;
  StreamSubscription<QuerySnapshot>? _productsSub; // New: Product Subscription
  Timer? _scanTimeoutTimer;
  Timer? _searchDebounce; // New: Search Debounce

  // State
  final Map<String, CartItem> _cart = {};
  TransactionStatus _status = TransactionStatus.idle;
  String? _errorMessage;
  double _lastSuccessAmount = 0.0;

  // Getters
  Map<String, CartItem> get cart => _cart;
  TransactionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  double get lastSuccessAmount => _lastSuccessAmount;
  
  double get total => _cart.values.fold(0.0, (sum, item) => sum + item.total);
  int get itemCount => _cart.values.fold(0, (sum, item) => sum + item.qty); // New: Item Count Getter
  bool get isProcessing => _status == TransactionStatus.processing || _status == TransactionStatus.scanned;

  POSController({
    required this.scanPointId,
    required this.merchantUid,
  });

  // --- Initialization ---
  void init() {
    _fetchProducts();
  }

  void _fetchProducts() {
    _isLoadingProducts = true;
    notifyListeners();

    _productsSub = FirebaseFirestore.instance
        .collection('scan_points')
        .doc(scanPointId)
        .collection('products')
        .snapshots()
        .listen((snapshot) {
      
      _allProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Inject ID
        return data;
      }).toList();

      _applyFilters(); // Initial Filter
      _isLoadingProducts = false;
      notifyListeners();
    }, onError: (e) {
      print("Error fetching products: $e");
      _isLoadingProducts = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _productsSub?.cancel(); // Cancel product sub
    _scanTimeoutTimer?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // --- Filter & Search Logic ---

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void search(String query) {
    if (_searchQuery == query) return;
    
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _applyFilters();
      notifyListeners();
    });
  }

  void _applyFilters() {
    _filteredProducts = _allProducts.where((product) {
      // 1. Category Filter
      // Assuming product has a 'category' field. If not, we might need to add it or ignore for now.
      // For now, if category is 'All', pass. Else check match.
      // Note: User image shows 'Rice', 'Noodles', etc. We assume data has this.
      // If data doesn't have 'category', this might filter everything out if not 'All'.
      // Let's be safe: If 'All', pass. If product has no category, pass only if 'All'.
      
      bool categoryMatch = true;
      if (_selectedCategory != 'All') {
        final prodCat = product['category'] as String?;
        // Case-insensitive comparison
        categoryMatch = prodCat?.toLowerCase() == _selectedCategory.toLowerCase();
      }

      // 2. Search Filter
      bool searchMatch = true;
      if (_searchQuery.isNotEmpty) {
        final name = (product['name'] as String? ?? '').toLowerCase();
        searchMatch = name.contains(_searchQuery.toLowerCase());
      }

      return categoryMatch && searchMatch;
    }).toList();
  }

  // --- Cart Logic ---

  void addToCart(String productId, Map<String, dynamic> productData, {int qty = 1}) {
    if (_cart.containsKey(productId)) {
      _cart[productId]!.qty += qty;
    } else {
      _cart[productId] = CartItem(
        productId: productId,
        name: productData['name'] ?? 'Unknown',
        price: (productData['price'] as num).toDouble(),
        qty: qty,
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int delta) {
    if (!_cart.containsKey(productId)) return;

    _cart[productId]!.qty += delta;
    if (_cart[productId]!.qty <= 0) {
      _cart.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }



  void reset() {
    _status = TransactionStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // --- Transaction Logic ---

  Future<void> startTransaction() async {
    if (_cart.isEmpty) return;

    _setStatus(TransactionStatus.processing);
    _errorMessage = null;

    try {
      // 1. Reset Scanner Status
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(merchantUid)
          .set({
            'status': 'IDLE',
            'state': 'IDLE',
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // 2. Create Trigger
      final cartItems = _cart.values.map((e) => e.toMap()).toList();
      await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .doc(scanPointId)
          .set({
            'active': true,
            'scan_mode': 'commerce',
            'scan_point_id': scanPointId,
            'amount': total,
            'cart': cartItems,
            'triggered_at': FieldValue.serverTimestamp(),
          });

      // 3. Listen for result
      _listenForStatus();

      // 4. Start Timeout (60s)
      _startTimeout();

    } catch (e) {
      _setError('Failed to start transaction: $e');
    }
  }

  void cancelTransaction() async {
    _stopListening();
    clearCart(); // FIX: Clear cart when cancelling
    _setStatus(TransactionStatus.idle);

    try {
      await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .doc(scanPointId)
          .update({'active': false});

      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(merchantUid)
          .update({'status': 'IDLE'});
    } catch (e) {
      print("Error cancelling transaction: $e");
    }
  }

  // --- Private Helpers ---

  void _setStatus(TransactionStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _status = TransactionStatus.error;
    notifyListeners();
  }

  void _startTimeout() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = Timer(const Duration(seconds: 60), () {
      if (_status == TransactionStatus.processing) {
        cancelTransaction();
        _setError('Transaction timed out. Please try again.');
      }
    });
  }

  void _stopListening() {
    _statusSub?.cancel();
    _scanTimeoutTimer?.cancel();
  }

  void _listenForStatus() {
    _statusSub?.cancel();
    _statusSub = FirebaseFirestore.instance
        .collection('scanner_status')
        .doc(merchantUid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final statusStr = data['status'] as String?;

      if (statusStr == 'success') {
        _handleSuccess();
        // Reset remote status
        snapshot.reference.update({'status': 'IDLE'});
      } else if (statusStr == 'error') {
        _handleError(data['message'] as String?);
        snapshot.reference.update({'status': 'IDLE'});
      }
    });
  }

  void _handleSuccess() {
    _stopListening();
    _lastSuccessAmount = total;
    _cart.clear(); // Clear cart on success
    _setStatus(TransactionStatus.success);
    
    // Deactivate trigger
    FirebaseFirestore.instance
        .collection('scanner_triggers')
        .doc(scanPointId)
        .update({'active': false});
  }

  void _handleError(String? message) {
    _stopListening();
    
    String friendlyMessage = message ?? 'Payment failed';
    if (friendlyMessage.contains('insufficient')) {
      friendlyMessage = '❌ Insufficient balance in user wallet.';
    } else if (friendlyMessage.contains('expired')) {
      friendlyMessage = '⚠️ QR Code has expired. Please refresh.';
    } else if (friendlyMessage.contains('network')) {
      friendlyMessage = '🌐 Network error. Please check connection.';
    }

    _setError(friendlyMessage);
  }
}
