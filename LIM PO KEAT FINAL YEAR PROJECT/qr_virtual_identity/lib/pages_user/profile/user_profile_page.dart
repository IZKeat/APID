import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'; // Import
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../services/guide_service.dart'; // Import
import '../routes.dart';
import '../widgets/jelly_card.dart';
import '../widgets/jelly_guide_overlay.dart'; // Import
import '../widgets/level_completion_overlay.dart'; // 🎮 Import LevelCompletionOverlay
import 'settings_page.dart';
import 'help_support_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  bool _guideRequested = false; // 🚩 Flag to track if guide was requested
  String? _errorMessage;

  // 🗝️ Guide Keys
  // 🗝️ Guide Keys
  final GlobalKey _keyIdentity = GlobalKey(); // 🆕 Identity Card
  final GlobalKey _keyPoints = GlobalKey();
  final GlobalKey _keyBadges = GlobalKey(); // 🆕 Badges
  final GlobalKey _keySettings = GlobalKey();
  final GlobalKey _keyHelp = GlobalKey(); // 🆕 Help & Support
  final GlobalKey _keySignOut = GlobalKey(); // 🆕 Sign Out

  // 📜 Scroll Controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  /// 🧭 Check and show Level 3 Guide (Profile)
  void checkSecurityGuide() {
    debugPrint('🧭 checkLevel3Guide called');
    _guideRequested = true; // 🚩 Mark as requested

    if (_isLoading) {
      debugPrint('⏳ Profile is loading, guide will show after load.');
      return;
    }

    if (GuideService().shouldStartLevel(3)) {
      debugPrint('🎮 Starting Level 3: Profile & Security');
      
      // Define Targets Part 1
      final targetsPart1 = [
        JellyGuideOverlay.createTarget(
          key: _keyIdentity,
          title: "Your Identity",
          description: "This is your digital student card. It proves your identity on campus.",
          align: ContentAlign.bottom,
        ),
        JellyGuideOverlay.createTarget(
          key: _keyPoints,
          title: "Points",
          description: "Earn points by attending events and completing tasks!",
          align: ContentAlign.bottom,
        ),
        JellyGuideOverlay.createTarget(
          key: _keyBadges,
          title: "Badges",
          description: "Show off your achievements! Collect badges for various milestones.",
          align: ContentAlign.bottom,
        ),
        JellyGuideOverlay.createTarget(
          key: _keySettings,
          title: "Account Settings",
          description: "Tap here to manage your security, change password, and enable biometric login.",
          align: ContentAlign.bottom,
        ),
        JellyGuideOverlay.createTarget(
          key: _keyHelp,
          title: "Help & Support",
          description: "Need assistance? Contact support or view FAQs here.",
          align: ContentAlign.top,
        ),
      ];

      debugPrint('🧭 Showing JellyGuideOverlay Part 1');
      JellyGuideOverlay.show(
        context: context,
        targets: targetsPart1,
        onFinish: () {
          // 📜 Scroll and Show Part 2
          _showSignOutGuide();
        },
        onSkip: () => _completeLevel3(),
      );
    } else {
      debugPrint('🧭 GuideService says DO NOT SHOW (Level 3)');
    }
  }

  /// 📜 Scroll and Show Part 2 (Sign Out)
  void _showSignOutGuide() {
    debugPrint('📜 Scrolling to Sign Out...');
    // 1. Scroll to bottom
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: 800.ms,
      curve: Curves.easeInOutCubic,
    );

    // 2. Wait for scroll + pause
    Future.delayed(1000.ms, () {
      if (!mounted) return;
      
      // 3. Show Part 2
      final targetsPart2 = [
        JellyGuideOverlay.createTarget(
          key: _keySignOut,
          title: "Sign Out",
          description: "Securely log out of your account here.",
          align: ContentAlign.top,
        ),
      ];

      JellyGuideOverlay.show(
        context: context,
        targets: targetsPart2,
        onFinish: () => _completeLevel3(),
        onSkip: () => _completeLevel3(),
      );
    });
  }

  void _completeLevel3() {
    GuideService().completeLevel(3);
    LevelCompletionOverlay.show(
      context: context,
      level: 3,
      points: 10,
      onNext: () {
        // 🎉 All Levels Complete!
        // Maybe show a "Master" badge or just close.
      },
    );
  }

  Future<void> _loadUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final stats = await UserService.getUserStats(user.uid);
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile data';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadUserStats,
            ),
          ),
        );
      }
    } finally {
       // 🕒 Check for Security Guide AFTER loading is done and UI is rendered
       if (mounted && !_isLoading && _guideRequested) {
         debugPrint('🧭 Data loaded & Guide Requested, scheduling guide check...');
         // Add a small delay to ensure layout is complete
         Future.delayed(const Duration(milliseconds: 500), () {
           if (mounted) {
             checkSecurityGuide();
           }
         });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    final rankColor = Color(_userStats?['rank_color'] ?? 0xFF9E9E9E);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadUserStats,
        child: SingleChildScrollView(
          controller: _scrollController, // 📜 Attach Controller
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 100),
          child: Column(
            children: [
              // Identity Hub - Hero Card
              Container(
                key: _keyIdentity, // 🗝️ Identity Key
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: rankColor.withValues(alpha: 0.3), width: 2), // 🎨 Rank Border
                  boxShadow: [
                    BoxShadow(
                      color: rankColor.withValues(alpha: 0.1), // 🎨 Rank Shadow
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Decorative Blob (Top Center)
                    Positioned(
                      top: -80,
                      child: Container(
                        width: 200,
                        height: 140,
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.15), // 🎨 Rank Blob
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(100)),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 3000.ms,
                      ),
                    ),

                    Column(
                      children: [
                        const SizedBox(height: 16),
                        // Avatar
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: rankColor.withValues(alpha: 0.2), width: 2), // 🎨 Avatar Border
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: rankColor.withValues(alpha: 0.1), // 🎨 Avatar Bg
                            backgroundImage: NetworkImage(
                              user.photoURL ?? 'https://api.dicebear.com/9.x/micah/png?seed=${user.email}',
                            ),
                          ),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          user.displayName ?? 'Student',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D192B),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        
                        Text(
                          user.email ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF49454F),
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8DEF8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'STUDENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D192B),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              // Stats Row (3 Separate Cards)
              _isLoading
                  ? _buildStatsSkeleton()
                  : Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            key: _keyPoints, // 🗝️ Bind Key
                            icon: Icons.confirmation_number_outlined,
                            label: 'Tickets',
                            value: _userStats?['tickets_count']?.toString() ?? '0',
                            color: Colors.blue,
                            delay: 200,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.bolt,
                            label: 'Points',
                            value: _userStats?['points']?.toString() ?? '0',
                            color: Colors.orange,
                            delay: 300,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                                // Show Badge Wall / Rank Details
                                _showBadgeWall(context);
                            },
                            child: _buildStatCard(
                              icon: Icons.emoji_events_outlined,
                              label: _userStats?['rank_title']?.toString().toUpperCase() ?? 'NOVICE',
                              value: 'RANK', // Display 'RANK' as label or value? Let's swap.
                              // Actually, let's keep the layout: Value (Big) -> Label (Small)
                              // Value: 'GOLD', Label: 'RANK'
                              // But _buildStatCard takes value as String.
                              // Let's pass rank title as value.
                              color: Color(_userStats?['rank_color'] ?? 0xFF9E9E9E),
                              delay: 400,
                              key: _keyBadges, // 🗝️ Bind Key
                              isRank: true, // Special styling for Rank
                            ),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 16),

              // 📊 Rank Progress Bar
              if (!_isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Next: ${_userStats?['next_rank_title'] ?? 'Max'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${_userStats?['points']} / ${_userStats?['next_rank_threshold']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_userStats?['progress'] as double?) ?? 0.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(_userStats?['rank_color'] ?? 0xFF9E9E9E),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),

              // Preferences Section
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'PREFERENCES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              JellyCard(
                key: _keySettings, // 🗝️ Bind Key
                title: 'Settings',
                subtitle: 'App preferences & notifications',
                icon: Icons.settings_outlined,
                backgroundColor: Colors.white,
                contentColor: const Color(0xFF1D192B),
                delay: 0.5,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                ),
              ),

              const SizedBox(height: 16),

              JellyCard(
                key: _keyHelp, // 🗝️ Bind Key
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                icon: Icons.help_outline,
                backgroundColor: Colors.white,
                contentColor: const Color(0xFF1D192B),
                delay: 0.6,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpSupportPage()),
                ),
              ),

              const SizedBox(height: 32),

              // Danger Zone - Sign Out
              GestureDetector(
                key: _keySignOut, // 🗝️ Sign Out Key
                onTap: () async {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, Routes.login);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4), // Outer padding for border effect
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9DEDC), // Light Red
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.logout, color: Color(0xFF410E0B), size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF410E0B),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF410E0B), size: 24),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 32),
              
              const Text(
                'Version 2.4.0 • Campus Jelly Hub',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSkeleton() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 60,
                    height: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 40,
                    height: 10,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _formatNumber(String value) {
    try {
      double num = double.parse(value);
      if (num >= 1000000) {
        return '${(num / 1000000).toStringAsFixed(1)}M';
      } else if (num >= 1000) {
        return '${(num / 1000).toStringAsFixed(1)}k';
      }
      return value;
    } catch (e) {
      return value;
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
    GlobalKey? key, // Add optional key
    bool isRank = false, // Special flag for Rank card
  }) {
    return Container(
      key: key, // Apply key
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8), // Reduced horizontal padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox( // Prevent overflow for large numbers
            fit: BoxFit.scaleDown,
            child: Text(
              isRank ? value : _formatNumber(value), // Use raw value for Rank (String)
              style: TextStyle(
                fontSize: isRank ? 16 : 20, // Smaller font for Rank text (e.g. DIAMOND)
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1D192B),
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox( // Prevent overflow for label
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  /// 🏆 Show Badge Wall / Rank Details Modal
  void _showBadgeWall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BadgeWallModal(userStats: _userStats),
    );
  }
}

class _BadgeWallModal extends StatelessWidget {
  final Map<String, dynamic>? userStats;

  const _BadgeWallModal({required this.userStats});

  @override
  Widget build(BuildContext context) {
    final currentRank = userStats?['rank_title'] as String? ?? 'Novice';
    final points = userStats?['points'] as int? ?? 0;
    
    final ranks = [
      {'name': 'Novice', 'threshold': 0, 'color': 0xFF9E9E9E, 'icon': Icons.person_outline},
      {'name': 'Bronze', 'threshold': 500, 'color': 0xFFCD7F32, 'icon': Icons.star_outline},
      {'name': 'Silver', 'threshold': 1000, 'color': 0xFFC0C0C0, 'icon': Icons.star_half},
      {'name': 'Gold', 'threshold': 2000, 'color': 0xFFFFD700, 'icon': Icons.star},
      {'name': 'Diamond', 'threshold': 5000, 'color': 0xFF00BCD4, 'icon': Icons.diamond},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rank Milestones',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Earn points to unlock higher ranks and exclusive rewards!',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: ranks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final rank = ranks[index];
                final threshold = rank['threshold'] as int;
                final isUnlocked = points >= threshold;
                final isCurrent = currentRank == rank['name'];
                final color = Color(rank['color'] as int);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnlocked ? color.withValues(alpha: 0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrent ? color : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked ? color : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          rank['icon'] as IconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rank['name'] as String,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            Text(
                              '$threshold Points',
                              style: TextStyle(
                                color: isUnlocked ? Colors.black54 : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        )
                      else if (!isUnlocked)
                        const Icon(Icons.lock_outline, color: Colors.grey),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
