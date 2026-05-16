import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'; // Import
import '../services/user_event_service.dart';
import '../services/guide_service.dart'; // Import
import '../models/event_model.dart';
import 'event_details_page.dart';
import '../widgets/ticket_card.dart';
import '../widgets/event_card.dart';
import '../widgets/event_skeleton_card.dart';
import '../widgets/jelly_guide_overlay.dart'; // Import

class UserEventsPage extends StatefulWidget {
  const UserEventsPage({super.key});

  @override
  State<UserEventsPage> createState() => _UserEventsPageState();
}

class _UserEventsPageState extends State<UserEventsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserEventService _eventService = UserEventService();
  String _selectedFilter = 'All'; // 'All', 'Active', 'Attended', 'Cancelled'

  // 🗝️ Guide Keys
  final GlobalKey _keyFilters = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 👂 Listen for Tab Changes to trigger guide
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        // Wait for frame to ensure Filter Chips are rendered
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   _checkEventsGuide();
        // });
      }
    });
  }

  /// 🧭 Check and show Events Guide
  void _checkEventsGuide() {
    // if (GuideService().shouldShow(GuideService.guideEvents)) {
    //   final targets = [
    //     JellyGuideOverlay.createTarget(
    //       key: _keyFilters,
    //       title: "Filter Events",
    //       description: "Looking for something specific? Tap these chips to filter events by category.",
    //       align: ContentAlign.bottom,
    //     ),
    //   ];
    //
    //   JellyGuideOverlay.show(
    //     context: context,
    //     targets: targets,
    //     onFinish: () {
    //       GuideService().markComplete(GuideService.guideEvents);
    //     },
    //     onSkip: () {
    //       GuideService().markComplete(GuideService.guideEvents);
    //     },
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // React uses white background mostly
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text(
                    'Events & Tickets',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D192B),
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 24),

                  // Capsule Tab Bar (React Style)
                  Container(
                    height: 56,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFFE8DEF8),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: const Color(0xFF1D192B),
                      unselectedLabelColor: Colors.grey.shade500,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'All Events'),
                        Tab(text: 'My Booking'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms).scale(),
                ],
              ),
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllEventsTab(),
                  _buildMyBookingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      key: _keyFilters, // 🗝️ Bind Key
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, size: 20, color: Color(0xFF49454F)),
          const SizedBox(width: 8),
          const Text(
            'Filter Tickets',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF49454F),
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('Active'),
          const SizedBox(width: 8),
          _buildFilterChip('Attended'),
          const SizedBox(width: 8),
          _buildFilterChip('Cancelled'),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX();
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6750A4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6750A4) : Colors.grey.shade200,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6750A4).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF49454F),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAllEventsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: StreamBuilder<List<EventModel>>(
        stream: _eventService.getAllEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Stack(
              children: [
                ListView(), // Ensure RefreshIndicator works
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No Events Available'),
                    ],
                  ),
                ),
              ],
            );
          }

          final events = snapshot.data!;
          // Dynamic colors for events
          final colors = [
            const Color(0xFFE8DEF8), // Purple
            const Color(0xFFC4EED0), // Green
            const Color(0xFFFFD8E4), // Pink
            const Color(0xFFE0F2FE), // Blue
          ];

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(
                event: event,
                color: colors[index % colors.length],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(event: event),
                    ),
                  );
                },
              )
                  .animate(delay: (index * 50).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            "Failed to load events",
            style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Please check your connection",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMyBookingTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please login to view tickets"));
    }

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: StreamBuilder<List<EventModel>>(
              stream: _eventService.getUserJoinedEvents(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingSkeleton();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                var events = snapshot.data ?? [];

                // Apply Filter
                if (_selectedFilter != 'All') {
                  events = events.where((e) {
                    final status = (e.status ?? 'active').toLowerCase();
                    return status == _selectedFilter.toLowerCase();
                  }).toList();
                }

                if (events.isEmpty) {
                  return Stack(
                    children: [
                      ListView(), // Ensure RefreshIndicator works
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No ${_selectedFilter.toLowerCase()} tickets',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      ).animate().fadeIn(),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return TicketCard(
                      event: event,
                      onOpenQr: () {
                        Navigator.pushNamed(context, '/qr_show');
                      },
                    )
                        .animate(delay: (index * 50).ms)
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => const EventSkeletonCard(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

