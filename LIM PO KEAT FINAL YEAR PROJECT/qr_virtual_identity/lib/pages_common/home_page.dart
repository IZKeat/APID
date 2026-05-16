import 'package:flutter/material.dart';

import '../pages_user/functions_view.dart';
// import '../pages_user/user_transactions_page.dart';
// import '../pages_user/user_activities_page.dart';
import '../pages_user/user_events_page.dart';
import '../pages_user/user_profile_page.dart';
import '../services/user_notification_service.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../services/guide_service.dart'; // Import GuideService
import '../widgets/jelly_guide_overlay.dart'; // Import JellyGuideOverlay
import '../services/fcm_service.dart'; // 🔔 Import FCMService
import '../services/deep_link_service.dart'; // 🔗 Import DeepLinkService
import '../widgets/level_completion_overlay.dart'; // 🎮 Import LevelCompletionOverlay
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'; // Import ContentAlign
import '../routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  // 🗝️ Key to access UserProfilePage state
  final GlobalKey<UserProfilePageState> _profileKey = GlobalKey<UserProfilePageState>();
  
  // 🗝️ Key to access FunctionsView state (for Level 2 trigger)
  final GlobalKey<FunctionsViewState> _functionsKey = GlobalKey<FunctionsViewState>();
  
  // 🗝️ Navigation Keys (Level 1)
  final GlobalKey _keyNavFunctions = GlobalKey();
  final GlobalKey _keyNavEvents = GlobalKey();
  final GlobalKey _keyNavProfile = GlobalKey();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Start listening for real-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UserNotificationService.startListening(context);
        // print('📢 [HomePage] User notification service started');
        
        // 🎮 Check Level 1 Guide
        checkLevel1Guide();

        // 🔔 Initialize FCM (Real Push Notifications)
        FCMService().init(context);

        // 🔗 Initialize Deep Links (Email Marketing)
        DeepLinkService().init(context);
      }
    });

    // Initialize pages here to access _profileKey
    _pages = [
      FunctionsView(key: _functionsKey), // 🗝️ Pass Key
      const UserEventsPage(),
      UserProfilePage(key: _profileKey),
    ];
  }

  @override
  void dispose() {
    // Stop listening when leaving HomePage
    UserNotificationService.stopListening();
    super.dispose();
  }

  /// 🧭 Check and show Level 1 Guide (Navigation)
  void checkLevel1Guide() {
    debugPrint('🧭 Checking Level 1 Guide...');
    if (GuideService().shouldStartLevel(1)) {
      debugPrint('🎮 Starting Level 1: Navigation Mastery');
      
      final targets = [
        JellyGuideOverlay.createTarget(
          key: _keyNavFunctions,
          title: "Functions Tab",
          description: "Access your Digital ID, Inbox, and Quick Utilities here.",
          align: ContentAlign.top,
        ),
        JellyGuideOverlay.createTarget(
          key: _keyNavEvents,
          title: "Events Tab",
          description: "Discover and join campus events to earn points.",
          align: ContentAlign.top,
        ),
        JellyGuideOverlay.createTarget(
          key: _keyNavProfile,
          title: "Profile Tab",
          description: "Manage your account, view stats, and settings.",
          align: ContentAlign.top,
        ),
      ];

      JellyGuideOverlay.show(
        context: context,
        targets: targets,
        onFinish: () => _completeLevel1(),
        onSkip: () => _completeLevel1(),
      );
    }
  }

  void _completeLevel1() {
    GuideService().completeLevel(1);
    LevelCompletionOverlay.show(
      context: context,
      level: 1,
      points: 10,
      onNext: () {
        // 🚀 Trigger Level 2 (Functions) immediately if we are on Functions tab
        if (_currentIndex == 0) {
          debugPrint('🚀 Triggering Level 2 check from HomePage');
          _functionsKey.currentState?.checkLevel2Guide();
        }
      },
    );
  }



  final List<String> _titles = [
    'Functions',
    // 'Transactions',
    // 'Activities',
    'Events',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFD49FB8), // Even Deeper Pink (Level 3)
                  Color(0xFFA9CBE6), // Even Deeper Blue (Level 3)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent, // Transparent to show gradient
          title: Text(_titles[_currentIndex]),
          // M3: AppBar elevation is handled by surface color, explicit elevation 0 is fine
          elevation: 0,
        ),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
        // M3: NavigationBar handles safe area automatically, but extendBody is usually false for M3
        extendBody: false,
        /* floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, Routes.scanner);
          },
          backgroundColor: const Color(0xFF6750A4),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
        ), */
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _currentIndex,
          onTap: (idx) {
            setState(() => _currentIndex = idx);
            // 🧭 Trigger Guide if switching to Profile (Index 2)
            if (idx == 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _profileKey.currentState?.checkSecurityGuide();
              });
            }
          },
          items: [
            CustomBottomNavigationItem(
              key: _keyNavFunctions,
              icon: Icons.grid_view_outlined,
              selectedIcon: Icons.grid_view_rounded,
              label: 'Functions',
            ),
            CustomBottomNavigationItem(
              key: _keyNavEvents,
              icon: Icons.event_outlined,
              selectedIcon: Icons.event_rounded,
              label: 'Events',
            ),
            CustomBottomNavigationItem(
              key: _keyNavProfile,
              icon: Icons.person_outline,
              selectedIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple wrapper to keep state alive for children inside the Stack.
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({required this.child, super.key});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
