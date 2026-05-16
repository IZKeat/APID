import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/wallet_service.dart';

class TopupModal extends StatefulWidget {
  final Function(double)? onTopUpSuccess;
  final VoidCallback? onSuccess;

  const TopupModal({super.key, this.onTopUpSuccess, this.onSuccess});

  @override
  State<TopupModal> createState() => _TopupModalState();
}

class _TopupModalState extends State<TopupModal> {
  final _amountController = TextEditingController();
  String _selectedPaymentMethod = 'Credit/Debit Card';
  bool _isLoading = false;
  
  // �️ Validation State
  String? _errorText;
  
  void _validateAmount(String value) {
    if (value.isEmpty) {
      setState(() => _errorText = null);
      return;
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      setState(() => _errorText = "Invalid format");
      return;
    }

    if (amount < 5.0) {
      setState(() => _errorText = "Minimum top-up is RM 5.00");
    } else if (amount > 1000.0) {
      setState(() => _errorText = "Maximum top-up is RM 1000.00");
    } else {
      setState(() => _errorText = null);
    }
  }
  
  // �💰 Quick Amount Presets
  final List<double> _quickAmounts = [10.0, 20.0, 50.0, 100.0, 200.0];

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'Credit/Debit Card', 'icon': Icons.credit_card},
    {'name': 'Online Banking', 'icon': Icons.account_balance},
    {'name': 'E-Wallet', 'icon': Icons.account_balance_wallet},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(0);
      _errorText = null; // Clear errors on quick select
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _processTopUp() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty) return;
    
    // Final Validation Check
    _validateAmount(amountText);
    if (_errorText != null) {
       HapticFeedback.heavyImpact(); // 📳 Error Feedback
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorText!),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final success = await WalletService.topUpWallet(amount, _selectedPaymentMethod);

      if (success && mounted) {
        // 🎉 Success Feedback
        widget.onSuccess?.call();
        Navigator.pop(context);
        
        // Show Success Dialog or SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Successfully topped up RM${amount.toStringAsFixed(2)}'),
              ],
            ),
            backgroundColor: const Color(0xFF4ADE80), // Green-400
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (mounted) {
        throw Exception('Transaction failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🤏 Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 🏷️ Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7), // Green-100
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add_card_rounded,
                    color: Color(0xFF166534), // Green-800
                    size: 28,
                  ),
                ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Up Wallet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D192B),
                      ),
                    ),
                    Text(
                      'Secure & Instant',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideX(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 💰 Amount Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENTER AMOUNT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6), // Grey-100
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'RM',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1D192B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            // 🛡️ Input Sanitization: Allow only numbers and dots
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            onChanged: _validateAmount,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _errorText != null ? theme.colorScheme.error : const Color(0xFF1D192B),
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              border: InputBorder.none,
                              isDense: true,
                              errorText: _errorText, // 🚨 Show real-time error
                              errorStyle: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ),
                    ],
                  ),
                ).animate().shimmer(delay: 400.ms, duration: 1000.ms),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ⚡ Quick Amounts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: _quickAmounts.map((amount) {
                final isSelected = _amountController.text == amount.toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _setQuickAmount(amount),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF166534) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF166534).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        '${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),

          const SizedBox(height: 32),

          // 💳 Payment Method
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAYMENT METHOD',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                ..._paymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethod == method['name'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPaymentMethod = method['name']);
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white, // Green-50
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF166534) : Colors.grey[200]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              method['icon'],
                              color: isSelected ? const Color(0xFF166534) : Colors.grey[400],
                            ),
                            const SizedBox(width: 16),
                            Text(
                              method['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? const Color(0xFF166534) : Colors.grey[700],
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF166534))
                                  .animate()
                                  .scale(),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 24),

          // 🚀 Action Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || _errorText != null || _amountController.text.isEmpty) 
                      ? null // 🚫 Disable if error or empty
                      : () {
                          _processTopUp();
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166534), // Green-800
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm Top Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ).animate().scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  delay: 600.ms,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
