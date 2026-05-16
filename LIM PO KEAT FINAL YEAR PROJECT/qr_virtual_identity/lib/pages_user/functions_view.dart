import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'; // Import TutorialCoachMark
import '../services/user_notification_service.dart';
import '../services/guide_service.dart'; // Import GuideService
import '../widgets/jelly_card.dart';
import '../widgets/jelly_guide_overlay.dart'; // Import JellyGuideOverlay
import '../widgets/level_completion_overlay.dart'; // 🎮 Import LevelCompletionOverlay
import '../components/transactions/topup_modal.dart'; // 💰 Import TopupModal
import '../services/user_event_service.dart'; // 📅 Import UserEventService
import '../models/event_model.dart'; // 📅 Import EventModel
import 'event_details_page.dart'; // 📅 Import EventDetailsPage
import '../routes.dart';
import '../widgets/ai_analysis_button.dart';

class FunctionsView extends StatefulWidget {
  const FunctionsView({super.key});

  @override
  State<FunctionsView> createState() => FunctionsViewState();
}

class FunctionsViewState extends State<FunctionsView> {
  // 🗝️ Guide Keys
  final GlobalKey _keyDigitalId = GlobalKey();
  final GlobalKey _keyProfile = GlobalKey();
  final GlobalKey _keyInbox = GlobalKey(); // 🆕 Inbox
  final GlobalKey _keyUtilities = GlobalKey(); // 🆕 Utilities
  final GlobalKey _keyCouncil = GlobalKey(); // 🆕 Council
  final GlobalKey _keySupport = GlobalKey();
  
  // 📜 Scroll Controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 🕒 Check for guide after frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLevel2Guide();
    });
  }

  /// 🧭 Check and show Level 2 Guide (Functions)
  void checkLevel2Guide() {
    debugPrint('🧭 Checking Level 2 Guide...');
    if (GuideService().shouldStartLevel(2)) {
      debugPrint('🎮 Starting Level 2: Functions Mastery');
      // Define Targets
      // Define Targets Part 1
      final targetsPart1 = [
        JellyGuideOverlay.createTarget(
          key: _keyDigitalId,
          title: "Your Digital ID",
          description: "This is your campus passport. Tap here to access your dynamic QR code for payments and entry.",
          align: ContentAlign.bottom,
        ),
        JellyGuideOverlay.createTarget(
          key: _keyProfile,
          title: "Student Profile",
          description: "View your stats, points, and manage your account settings here.",
          align: ContentAlign.bottom,
        ),
        JellyGuideOverlay.createTarget(
          key: _keyInbox,
          title: "Inbox",
          description: "Stay updated! Check your messages, notifications, and announcements here.",
          align: ContentAlign.bottom,
        ),
        JellyGuideOverlay.createTarget(
          key: _keyUtilities,
          title: "Quick Utilities",
          description: "Your campus toolkit. Access the Shuttle, Library, Support, and Top Up services all in one place.",
          align: ContentAlign.top,
        ),
      ];

      // Show Part 1
      JellyGuideOverlay.show(
        context: context,
        targets: targetsPart1,
        onFinish: () {
          // 📜 Scroll and Show Part 2
          _showCouncilGuide();
        },
        onSkip: () {
          _completeLevel2();
        },
      );
    }
  }

  /// 📜 Scroll and Show Part 2 (Student Council)
  void _showCouncilGuide() {
    debugPrint('📜 Scrolling to Student Council...');
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
          key: _keyCouncil,
          title: "Student Council",
          description: "Make your voice heard! Participate in voting and stay informed about council activities.",
          align: ContentAlign.top,
        ),
      ];

      JellyGuideOverlay.show(
        context: context,
        targets: targetsPart2,
        onFinish: () {
          _completeLevel2();
        },
        onSkip: () {
          _completeLevel2();
        },
      );
    });
  }

  void _completeLevel2() {
    GuideService().completeLevel(2);
    LevelCompletionOverlay.show(
      context: context,
      level: 2,
      points: 10,
      onNext: () {
        // Navigate to Profile to trigger Level 3? 
        // Or just let user explore.
        // For now, just close.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FF), // Matches React bg
      body: CustomScrollView(
        controller: _scrollController, // 📜 Attach Controller
        slivers: [
          // Sticky Glass Header
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: const Color(0xFFFDF7FF).withValues(alpha: 0.8),
            elevation: 0,
            toolbarHeight: 80, // Taller to fit Date + Title
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Hero(
                tag: 'app_logo',
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6750A4),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6750A4).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFF6750A4),
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 4),
                  const Text(
                    'APID',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D192B),
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 600.ms),
                ],
              ),
            ),
            actions: [
              /*
              Padding(
                padding: const EdgeInsets.only(right: 20, top: 10),
                child: Center(
                  child: Stack(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6750A4), Color(0xFFD0BCFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6750A4).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const CircleAvatar(
                            backgroundColor: Colors.transparent,
                            backgroundImage: NetworkImage('https://api.dicebear.com/9.x/micah/png?seed=Felix'),
                          ),
                        ),
                      ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
                      
                      // Online Status Indicator
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80), // Green-400
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ).animate(delay: 500.ms).scale(curve: Curves.elasticOut),
                      ),
                    ],
                  ),
                ),
              ),
              */
            ],
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority Access Section
                  const Text(
                    'Priority Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D192B),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  
                  const SizedBox(height: 16),

                  // Bento Grid
                  StaggeredGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      // Digital ID (Left Column, Tall)
                      StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: 2,
                        child: JellyCard(
                          key: _keyDigitalId, // 🗝️ Bind Key
                          title: 'Digital ID',
                          subtitle: 'Tap to Scan',
                          icon: Icons.qr_code_2,
                          backgroundColor: const Color(0xFFE8DEF8), // Light Purple
                          contentColor: const Color(0xFF1D192B),
                          delay: 0.1,
                          onTap: () {
                             Navigator.pushNamed(context, Routes.qrShow);
                          },
                          content: Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: '1234567890', // Placeholder
                                version: QrVersions.auto,
                                size: 100,
                                gapless: false,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF6750A4),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.circle,
                                  color: Color(0xFF6750A4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Profile (Right Column, Top)
                      StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: 1,
                        child: JellyCard(
                          key: _keyProfile, // 🗝️ Bind Key
                          title: 'Profile',
                          subtitle: 'Identity Hub',
                          icon: Icons.person_outline,
                          backgroundColor: const Color(0xFFFFD8E4), // Light Pink
                          contentColor: const Color(0xFF31111D),
                          delay: 0.2,
                          onTap: () {
                            Navigator.pushNamed(context, Routes.userProfile);
                          },
                        ),
                      ),

                      // Inbox (Right Column, Bottom)
                      StaggeredGridTile.count(
                        crossAxisCellCount: 1,
                        mainAxisCellCount: 1,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: UserNotificationService.getInboxStream(),
                          builder: (context, snapshot) {
                            final hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                            final latestDoc = hasData ? snapshot.data!.docs.first.data() as Map<String, dynamic> : null;
                            final unreadCount = hasData ? snapshot.data!.docs.length : 0; // Simple count for now

                            return JellyCard(
                              key: _keyInbox, // 🗝️ Bind Key
                              title: 'Inbox',
                              icon: Icons.notifications_outlined,
                              backgroundColor: const Color(0xFFF2F0F4), // Off White
                              contentColor: const Color(0xFF1D192B),
                              delay: 0.3,
                              padding: const EdgeInsets.all(16),
                              contentSpacing: 12.0,
                              onTap: () {
                                Navigator.pushNamed(context, Routes.notificationInbox);
                              },
                              content: Container(
                                margin: EdgeInsets.zero,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasData)
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(top: 5, right: 6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFB3261E),
                                          shape: BoxShape.circle,
                                        ),
                                      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FittedBox( // Ensure title fits
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              hasData ? (latestDoc?['scan_point_name'] ?? 'Notification') : 'No Messages',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1D192B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hasData ? (latestDoc?['type'] ?? 'New activity') : 'You are all caught up',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF49454F),
                                              height: 1.1,
                                              letterSpacing: 0,
                                            ),
                                            maxLines: 1, // Limit to 1 line to prevent vertical overflow
                                            overflow: TextOverflow.ellipsis, // Truncate with ellipsis
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Quick Utilities
                  Container(
                    key: _keyUtilities, // 🗝️ Bind Key to the whole section
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Utilities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D192B),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
      
                        const SizedBox(height: 16),
      
                        // Horizontal Scrollable Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              // Shuttle & Library removed as per request
                              // Only Top Up and Support remain
                              // Shuttle & Library removed as per request
                              // Only Top Up and Support remain
                              const AiAnalysisButton(), // 🧠 AI Smart Advisor
                              const SizedBox(width: 12),
                              _buildUtilityCard(
                                icon: Icons.help_outline,
                                label: 'Support',
                                color: const Color(0xFFCCFBF1), // Teal-100
                                iconColor: const Color(0xFF115E59), // Teal-800
                                onTap: () {
                                  Navigator.pushNamed(context, Routes.helpSupport);
                                },
                                delay: 0.7,
                                key: _keySupport, // 🗝️ Bind Key (Pass to _buildUtilityCard)
                              ),
                              const SizedBox(width: 12),
                              _buildUtilityCard(
                                icon: Icons.account_balance_wallet,
                                label: 'Top Up',
                                color: const Color(0xFFDCFCE7), // Green-100
                                iconColor: const Color(0xFF166534), // Green-800
                                onTap: () => _showTopUpModal(context),
                                delay: 0.8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),



                  const SizedBox(height: 32),

                  // Dynamic Event Banner 📅
                  StreamBuilder<List<EventModel>>(
                    stream: UserEventService().getUpcomingEvents(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final event = snapshot.data!.first;
                        return _buildEventBanner(context, event);
                      }
                      
                      // Fallback "Stay Tuned" Banner if no events
                      return Container(
                        key: _keyCouncil,
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D192B),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -40,
                              right: -40,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6750A4).withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                duration: 2000.ms,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Stay Tuned!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF3EDF7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'More exciting events coming soon.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFCAC4D0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventBanner(BuildContext context, EventModel event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(event: event),
          ),
        );
      },
      child: Container(
        key: _keyCouncil,
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFF1D192B),
          borderRadius: BorderRadius.circular(28),
          image: event.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(event.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.6),
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: [
             BoxShadow(
                color: const Color(0xFF6750A4).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (event.imageUrl == null)
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6750A4).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 2000.ms,
                    ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0BCFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'UPCOMING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF381E72),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3EDF7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFCAC4D0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F378B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Join Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0),
    );
  }

  void _showTopUpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => TopupModal(
          onSuccess: () {
            // Optional: Refresh any data if needed
            setState(() {}); 
          },
        ),
      ),
    );
  }

  Widget _buildUtilityCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    double delay = 0,
    GlobalKey? key, // Add optional key
  }) {
    return Animate(
      key: key, // Apply key to Animate widget or Container
      delay: (delay * 1000).ms,
      effects: [
        FadeEffect(duration: 600.ms),
        ScaleEffect(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 80, // Fixed width for horizontal scroll
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                 BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ]
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF49454F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
