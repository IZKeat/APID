// lib/components/transactions/transfer_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

/// Transfer modal for sending funds to other users
class TransferModal extends StatefulWidget {
  final VoidCallback? onSuccess;

  const TransferModal({super.key, this.onSuccess});

  @override
  State<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends State<TransferModal> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _isLoading = false;
  bool _isValidatingEmail = false;
  String? _recipientName;
  double _currentBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentBalance();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentBalance() async {
    try {
      final user = _auth.currentUser!;
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentBalance = (userDoc.data()!['walletBalance'] ?? 0.0)
              .toDouble();
        });
      }
    } catch (e) {
      print('Error loading balance: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _validateEmail(String email) async {
    if (email.isEmpty) {
      setState(() {
        _recipientName = null;
        _isValidatingEmail = false;
      });
      return;
    }

    if (!email.contains('@')) return;

    setState(() {
      _isValidatingEmail = true;
      _recipientName = null;
    });

    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userData = query.docs.first.data();
        final firstName = userData['first_name'] ?? '';
        final lastName = userData['last_name'] ?? '';

        setState(() {
          _recipientName = '$firstName $lastName'.trim();
        });
      }
    } catch (e) {
      print('Error validating email: $e');
    } finally {
      setState(() {
        _isValidatingEmail = false;
      });
    }
  }

  Future<void> _processTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (amount > _currentBalance) {
      _showError('Insufficient balance');
      return;
    }

    final recipientEmail = _emailController.text.trim();
    if (_recipientName == null) {
      _showError('User not found');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser!;

      // Get recipient user data
      final recipientQuery = await _db
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .limit(1)
          .get();

      if (recipientQuery.docs.isEmpty) {
        _showError('User not found');
        return;
      }

      final recipientDoc = recipientQuery.docs.first;
      final recipientUid = recipientDoc.id;

      // Perform atomic transaction
      await _db.runTransaction((transaction) async {
        // Get latest balances
        final senderDoc = await transaction.get(
          _db.collection('users').doc(user.uid),
        );
        final receiverDoc = await transaction.get(
          _db.collection('users').doc(recipientUid),
        );

        final senderBalance = (senderDoc.data()!['walletBalance'] ?? 0.0)
            .toDouble();
        final receiverBalance = (receiverDoc.data()!['walletBalance'] ?? 0.0)
            .toDouble();

        if (senderBalance < amount) {
          throw Exception('Insufficient balance');
        }

        // Update balances
        transaction.update(_db.collection('users').doc(user.uid), {
          'walletBalance': senderBalance - amount,
        });

        transaction.update(_db.collection('users').doc(recipientUid), {
          'walletBalance': receiverBalance + amount,
        });

        // Create sender transaction record
        transaction.set(_db.collection('transactions').doc(), {
          'userId': user.uid,
          'type': 'transfer_out',
          'amount': -amount,
          'recipient_email': recipientEmail,
          'recipient_name': _recipientName,
          'remarks': _remarksController.text.trim().isEmpty
              ? 'Sent to $_recipientName'
              : _remarksController.text.trim(),
          'status': 'success',
          'timestamp': FieldValue.serverTimestamp(),
          'sender_uid': user.uid,
          'sender_email': user.email,
          'sender_name':
              '${senderDoc.data()!['first_name'] ?? ''} ${senderDoc.data()!['last_name'] ?? ''}'
                  .trim(),
          'receiver_uid': recipientUid,
          'balanceBefore': senderBalance,
          'balanceAfter': senderBalance - amount,
          'reference': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        });

        // Create receiver transaction record
        transaction.set(_db.collection('transactions').doc(), {
          'userId': recipientUid,
          'type': 'transfer_in',
          'amount': amount,
          'sender_email': user.email,
          'sender_name':
              '${senderDoc.data()!['first_name'] ?? ''} ${senderDoc.data()!['last_name'] ?? ''}'
                  .trim(),
          'remarks': _remarksController.text.trim().isEmpty
              ? 'Received from ${senderDoc.data()!['first_name'] ?? 'Unknown'}'
              : _remarksController.text.trim(),
          'status': 'success',
          'timestamp': FieldValue.serverTimestamp(),
          'sender_uid': user.uid,
          'receiver_uid': recipientUid,
          'balanceBefore': receiverBalance,
          'balanceAfter': receiverBalance + amount,
          'reference': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        });
      });

      if (mounted) {
        HapticFeedback.heavyImpact();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('💸', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sent RM${amount.toStringAsFixed(2)} to $_recipientName',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pop(context);
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('Insufficient balance')) {
          _showError('Insufficient balance');
        } else {
          _showError('Transfer failed: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenHeight * 0.8 - keyboardHeight, // Dynamic height adjustment
      constraints: BoxConstraints(
        maxHeight: screenHeight - 100, // Ensure it doesn't exceed screen
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Transfer Money',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Balance Info
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.accentColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Available Balance: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'RM${_currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipient Email
                    const Text(
                      'Recipient Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _recipientName != null
                              ? AppTheme.successColor
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter recipient email address',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          suffixIcon: _isValidatingEmail
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _recipientName != null
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.successColor,
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          if (value.contains('@') && value.length > 5) {
                            _validateEmail(value);
                          } else {
                            setState(() {
                              _recipientName = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!value!.contains('@')) {
                            return 'Invalid email format';
                          }
                          if (_recipientName == null) return 'User not found';
                          return null;
                        },
                      ),
                    ),

                    // Recipient Info
                    if (_recipientName != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: AppTheme.successColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sending to: $_recipientName',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Amount Input
                    const Text(
                      'Transfer Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: 'RM ',
                          hintText: '0.00',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Amount is required';
                          }
                          final amount = double.tryParse(value!);
                          if (amount == null || amount <= 0) {
                            return 'Invalid amount';
                          }
                          if (amount > _currentBalance) {
                            return 'Insufficient balance';
                          }
                          if (amount > 5000) {
                            return 'Maximum transfer is RM5,000';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Remarks (Optional)
                    const Text(
                      'Remarks (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _remarksController,
                        maxLines: 2,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          hintText: 'Add a note (optional)',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          counterText: '',
                        ),
                      ),
                    ),

                    const SizedBox(height: 20), // Reduce spacing
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Button with proper safe area
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                24,
                16,
                24,
                16,
              ), // Reduce vertical padding
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isLoading ||
                          _recipientName == null ||
                          _currentBalance <= 0)
                      ? null
                      : _processTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send Money',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
