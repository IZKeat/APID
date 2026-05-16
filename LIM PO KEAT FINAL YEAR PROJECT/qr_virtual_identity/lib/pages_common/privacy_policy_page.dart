import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/jelly_card.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF),
      body: Column(
        children: [
          // Sticky Glass Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D192B),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Updated: December 2025',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                  
                  const SizedBox(height: 24),

                  _buildSection(
                    index: 0,
                    title: '1. Introduction',
                    icon: Icons.info_outline,
                    content: 'Welcome to QR Virtual Identity. This application is developed as a Final Year Project (FYP) to demonstrate a secure and efficient digital identity system for campus environments.',
                  ),

                  _buildSection(
                    index: 1,
                    title: '2. Data Collection',
                    icon: Icons.data_usage,
                    content: 'We collect the following information to provide our services:\n\n'
                        '• Personal Information: Name, Student ID, Email Address.\n'
                        '• Biometric Data: Fingerprint or Face ID data is processed locally on your device and is NOT stored on our servers.\n'
                        '• Usage Data: Attendance records and event participation logs.',
                  ),

                  _buildSection(
                    index: 2,
                    title: '3. How We Use Your Data',
                    icon: Icons.settings_applications_outlined,
                    content: 'Your data is used strictly for:\n\n'
                        '• Verifying your identity within the campus.\n'
                        '• Recording attendance for classes and events.\n'
                        '• Sending important notifications regarding your account security.',
                  ),

                  _buildSection(
                    index: 3,
                    title: '4. Data Security',
                    icon: Icons.security,
                    content: 'We implement industry-standard security measures:\n\n'
                        '• All data transmission is encrypted using SSL/TLS.\n'
                        '• Sensitive data is stored in a secure Firebase Firestore database.\n'
                        '• Access to personal data is restricted to authorized personnel only.',
                  ),

                  _buildSection(
                    index: 4,
                    title: '5. Your Rights',
                    icon: Icons.gavel_outlined,
                    content: 'You have the right to:\n\n'
                        '• Access the personal data we hold about you.\n'
                        '• Request correction of inaccurate data.\n'
                        '• Request deletion of your account and data (subject to university policies).',
                  ),

                  _buildSection(
                    index: 5,
                    title: '6. Contact Us',
                    icon: Icons.contact_mail_outlined,
                    content: 'If you have any questions about this Privacy Policy, please contact the developer at:\n\n'
                        'limisaac418@gmail.com',
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required int index,
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: JellyCard(
        title: title,
        icon: icon,
        delay: index * 0.1, // Staggered animation
        backgroundColor: Colors.white,
        content: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF49454F),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
