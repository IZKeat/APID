import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/jelly_card.dart';
import '../pages/chat_page.dart';
import 'feedback_page.dart';
import '../pages_common/guide_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../widgets/jelly_notification.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int? _openFaqIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredFaqs = [];

  @override
  void initState() {
    super.initState();
    _filteredFaqs = _faqs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _faqs;
      } else {
        _filteredFaqs = _faqs.where((faq) {
          final q = faq['q']!.toLowerCase();
          final a = faq['a']!.toLowerCase();
          final input = query.toLowerCase();
          return q.contains(input) || a.contains(input);
        }).toList();
      }
      _openFaqIndex = null; // Close expanded items when searching
    });
  }

  final List<Map<String, String>> _faqs = [
    {
      'q': "How do I access my digital ID?",
      'a': "Go to the Functions tab and tap on the large 'Digital ID' card. You can refresh the code every 60 seconds."
    },
    {
      'q': "How do I register for events?",
      'a': "Navigate to the Events tab, select an event you like, and tap 'View Registration'. Confirm your spot instantly."
    },
    {
      'q': "Can I cancel a booking?",
      'a': "Yes, go to 'My Booking' in the Events tab, select the ticket, and tap 'Cancel Ticket'. Please do this 24h in advance."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF),
      body: Column(
        children: [
          // Sticky Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            color: const Color(0xFFFDF7FF),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D192B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search for help...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
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
                  // Contact Options
                  Row(
                    children: [
                      Expanded(
                        child: JellyCard(
                          title: '',
                          backgroundColor: const Color(0xFFEADDFF),
                          contentColor: const Color(0xFF21005D),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChatPage()),
                            );
                          },
                          content: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline, size: 24),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Live Chat',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Wait time: ~2m',
                                style: TextStyle(fontSize: 10, color: const Color(0xFF21005D).withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: JellyCard(
                          title: '',
                          backgroundColor: const Color(0xFFFFD8E4),
                          contentColor: const Color(0xFF31111D),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FeedbackPage()),
                            );
                          },
                          content: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mail_outline, size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Email Us',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Reply in 24h',
                                style: TextStyle(fontSize: 10, color: const Color(0xFF31111D).withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms),

                  const SizedBox(height: 32),

                  // User Guides Section
                  const Text(
                    'User Guides',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D192B),
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 16),

                  _buildGuideCard(
                    context,
                    title: 'Mastering Digital ID',
                    subtitle: 'Secure Mode, Refresh & Wallet',
                    icon: Icons.qr_code_scanner,
                    color: const Color(0xFF6750A4),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuideDetailPage(
                          title: 'Mastering Digital ID',
                          subtitle: 'Learn how to use your secure identity',
                          themeColor: const Color(0xFF6750A4),
                          steps: [
                            GuideStep(
                              title: 'Tap to Reveal',
                              description: 'Your QR code is blurred by default for security. Tap the blurred area and authenticate with FaceID/Fingerprint to reveal it for 60 seconds.',
                              icon: Icons.visibility,
                            ),
                            GuideStep(
                              title: 'Refresh QR Code',
                              description: 'For security, QR codes expire. Tap the refresh button below the card to generate a new code with a fresh secure signature.',
                              icon: Icons.refresh,
                            ),
                            GuideStep(
                              title: 'Check Wallet Balance',
                              description: 'Your current balance is shown directly on the Digital ID card. It updates in real-time when you make a purchase.',
                              icon: Icons.account_balance_wallet,
                            ),
                            GuideStep(
                              title: 'Where to Use',
                              description: 'Use this ID for campus entry, classroom attendance, and cashless payments at the cafeteria.',
                              icon: Icons.place,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildGuideCard(
                    context,
                    title: 'Security & Profile',
                    subtitle: 'Password & Biometrics',
                    icon: Icons.security,
                    color: const Color(0xFFB3261E),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuideDetailPage(
                          title: 'Security & Profile',
                          subtitle: 'Manage your account security',
                          themeColor: const Color(0xFFB3261E),
                          steps: [
                            GuideStep(
                              title: 'Change Password',
                              description: 'Go to Settings > Change Password. You will need to enter your current password first, then create a strong new password.',
                              icon: Icons.password,
                            ),
                            GuideStep(
                              title: 'Enable Biometrics',
                              description: 'In Settings, toggle "Biometric Login". You must verify your password one last time to enable this feature securely.',
                              icon: Icons.fingerprint,
                            ),
                            GuideStep(
                              title: 'Forgot Password?',
                              description: 'If you cannot login, use the "Forgot Password" link on the login screen to receive a reset email.',
                              icon: Icons.lock_reset,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildGuideCard(
                    context,
                    title: 'Live Chat Support',
                    subtitle: 'AI Assistant & Quick Help',
                    icon: Icons.chat_bubble,
                    color: const Color(0xFF006C4C), // Green-ish
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuideDetailPage(
                          title: 'Live Chat Support',
                          subtitle: 'Get instant answers from our AI',
                          themeColor: const Color(0xFF006C4C),
                          steps: [
                            GuideStep(
                              title: 'Access Live Chat',
                              description: 'Tap the "Live Chat" card at the top of the Help page. This connects you to our intelligent support assistant.',
                              icon: Icons.touch_app,
                            ),
                            GuideStep(
                              title: 'Ask Questions',
                              description: 'Type your question in the text field or select one of the quick suggestion chips like "How does Digital ID work?".',
                              icon: Icons.question_answer,
                            ),
                            GuideStep(
                              title: 'Instant Response',
                              description: 'The AI will analyze your query and provide an immediate answer based on the campus database.',
                              icon: Icons.bolt,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildGuideCard(
                    context,
                    title: 'Email Feedback',
                    subtitle: 'Report Bugs & Requests',
                    icon: Icons.mail,
                    color: const Color(0xFF9C4146), // Red-ish/Brown
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuideDetailPage(
                          title: 'Email Feedback',
                          subtitle: 'Submit detailed reports to us',
                          themeColor: const Color(0xFF9C4146),
                          steps: [
                            GuideStep(
                              title: 'Select Category',
                              description: 'Choose the type of feedback: Bug Report, Account Issue, or Feature Request from the dropdown menu.',
                              icon: Icons.category,
                            ),
                            GuideStep(
                              title: 'Describe the Issue',
                              description: 'Enter a subject and a detailed message. The more details you provide, the faster we can help.',
                              icon: Icons.description,
                            ),
                            GuideStep(
                              title: 'Submit & Wait',
                              description: 'Tap "Send Feedback". Our support team will review your ticket and reply via email within 24 hours.',
                              icon: Icons.send,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildGuideCard(
                    context,
                    title: 'Inbox & Notifications',
                    subtitle: 'Filter, Search & Receipts',
                    icon: Icons.notifications_active,
                    color: const Color(0xFFE8DEF8), // Purple-ish
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuideDetailPage(
                          title: 'Inbox & Notifications',
                          subtitle: 'Manage your alerts and history',
                          themeColor: const Color(0xFF6750A4),
                          steps: [
                            GuideStep(
                              title: 'Filtering Categories',
                              description: 'Tap the chips at the top (e.g., "Commerce", "Library") to filter notifications. Select "All" to see everything.',
                              icon: Icons.filter_list,
                            ),
                            GuideStep(
                              title: 'Smart Search',
                              description: 'Use the search bar to find specific records. You can search by location (e.g., "Cafeteria") or type (e.g., "Payment").',
                              icon: Icons.search,
                            ),
                            GuideStep(
                              title: 'View Receipts',
                              description: 'Tap on any payment or transaction notification to open a detailed digital receipt.',
                              icon: Icons.receipt,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🛠️ Debug Section
                  // Center(
                  //   child: TextButton.icon(
                  //     onPressed: () async {
                  //       final user = FirebaseAuth.instance.currentUser;
                  //       final token = await FirebaseMessaging.instance.getToken();
                  //       print('👤 User UID: ${user?.uid}');
                  //       print('🔔 FCM Token: $token');
                  //       
                  //       if (context.mounted) {
                  //         showDialog(
                  //           context: context,
                  //           builder: (context) => AlertDialog(
                  //             title: const Text('Debug Info'),
                  //             content: Column(
                  //               mainAxisSize: MainAxisSize.min,
                  //               crossAxisAlignment: CrossAxisAlignment.start,
                  //               children: [
                  //                 Text('UID: ${user?.uid ?? "Not Logged In"}', style: const TextStyle(fontSize: 12)),
                  //                 const SizedBox(height: 8),
                  //                 Text('Token: ${token?.substring(0, 10)}...', style: const TextStyle(fontSize: 12)),
                  //                 const SizedBox(height: 16),
                  //                 const Text('Check console for full token.'),
                  //               ],
                  //             ),
                  //             actions: [
                  //               TextButton(
                  //                 onPressed: () => Navigator.pop(context),
                  //                 child: const Text('Close'),
                  //               ),
                  //             ],
                  //           ),
                  //         );
                  //       }
                  //     },
                  //     icon: const Icon(Icons.bug_report, size: 16, color: Colors.grey),
                  //     label: const Text('Show Debug Info (UID & Token)', style: TextStyle(color: Colors.grey)),
                  //   ),
                  // ),

                  const SizedBox(height: 32),

                  const Text(
                    'Frequently Asked',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D192B),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  ..._filteredFaqs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final faq = entry.value;
                    final isOpen = _openFaqIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _openFaqIndex = isOpen ? null : index;
                        }),
                        child: AnimatedContainer(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq['q']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1D192B),
                                      ),
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: isOpen ? 0.5 : 0,
                                    duration: 300.ms,
                                    child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6750A4)),
                                  ),
                                ],
                              ),
                              AnimatedCrossFade(
                                firstChild: Container(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    faq['a']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                duration: 300.ms,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate(delay: (300 + index * 100).ms).slideY(begin: 0.2, end: 0).fadeIn();
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1D192B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    ).animate().slideX(begin: 0.1, end: 0).fadeIn();
  }

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@campusjellyhub.com',
      query: 'subject=Support Request',
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open email app. Please email support@campusjellyhub.com'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }
}
