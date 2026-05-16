import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/support_service.dart';
import '../widgets/jelly_card.dart'; // Assuming this exists, otherwise I'll use a Container with decoration

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _supportService = SupportService();
  
  String _selectedCategory = 'Bug Report';
  final List<String> _categories = ['Bug Report', 'Account Issue', 'Feature Request', 'Other'];
  
  bool _isSubmitting = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _supportService.createTicket(
        category: _selectedCategory,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      // Show success animation
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });

      // Wait for animation then pop
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If success, show the full screen success view
    if (_isSuccess) {
      return _buildSuccessView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF),
      appBar: AppBar(
        title: const Text('Send Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "We'd love to hear from you!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1D192B)),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 8),
              Text(
                "Your feedback helps us make the APID better.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 32),

              // Category Dropdown
              _buildLabel("Category"),
              const SizedBox(height: 8),
              _buildJellyDropdown().animate().scale(delay: 200.ms),

              const SizedBox(height: 24),

              // Subject Field
              _buildLabel("Subject"),
              const SizedBox(height: 8),
              _buildJellyTextField(
                controller: _subjectController,
                hint: "Brief summary of the issue",
                icon: Icons.title,
              ).animate().scale(delay: 300.ms),

              const SizedBox(height: 24),

              // Message Field
              _buildLabel("Message"),
              const SizedBox(height: 8),
              _buildJellyTextField(
                controller: _messageController,
                hint: "Describe your issue or idea in detail...",
                icon: Icons.message_outlined,
                maxLines: 5,
              ).animate().scale(delay: 400.ms),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Send Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.send_rounded, size: 20),
                          ],
                        ),
                ),
              ).animate().slideY(begin: 1, end: 0, delay: 500.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF49454F),
      ),
    );
  }

  Widget _buildJellyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADDFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6750A4).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6750A4)),
          items: _categories.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Color(0xFF1D192B))),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selectedCategory = newValue!);
          },
        ),
      ),
    );
  }

  Widget _buildJellyTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADDFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6750A4).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 12),
            child: Icon(icon, color: const Color(0xFF6750A4)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: const Color(0xFF6750A4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, size: 64, color: Color(0xFF6750A4))
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
            ).animate().slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
            
            const SizedBox(height: 32),
            
            const Text(
              "Feedback Sent!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, end: 0),
            
            const SizedBox(height: 8),
            
            Text(
              "Thank you for helping us improve.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
