import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import custom components
import '../components/activities/activity_filter_bar.dart';
import '../components/activities/daily_stats_card.dart';
import '../components/activities/activity_timeline.dart';
import '../components/activities/activity_charts.dart';
import '../components/activities/empty_state.dart';

class UserActivitiesPage extends StatefulWidget {
  const UserActivitiesPage({super.key});

  @override
  State<UserActivitiesPage> createState() => _UserActivitiesPageState();
}

class _UserActivitiesPageState extends State<UserActivitiesPage>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  DateTimeRange? _selectedDateRange;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  bool _hasActivities = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initDateRange();
    _checkForActivities();
  }

  void _initAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    );
    _headerAnimationController.forward();
  }

  void _initDateRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _selectedDateRange = DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  Future<void> _checkForActivities() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('interactions')
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'success')
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _hasActivities = snapshot.docs.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF6A1B9A), // Stronger purple
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Custom App Bar
              _buildSliverAppBar(),

              // Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ActivityFilterBar(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: _onFilterChanged,
                  ),
                ),
              ),

              // Main Content
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6A1B9A)),
                        SizedBox(height: 16),
                        Text(
                          'Loading activity data...',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!_hasActivities)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ActivitiesEmptyState(
                    selectedFilter: _selectedFilter,
                    onRefresh: _onRefresh,
                  ),
                )
              else ...[
                // Daily Stats Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DailyStatsCard(selectedFilter: _selectedFilter),
                  ),
                ),

                // Activities Timeline Header
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timeline,
                          color: const Color(0xFF6A1B9A), // Stronger purple
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Activity Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A1B9A), // Stronger purple
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Activities Timeline Content
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    constraints: const BoxConstraints(
                      minHeight: 100,
                      maxHeight: 350, // Reduced height to prevent overflow
                    ),
                    child: ActivityTimeline(
                      selectedFilter: _selectedFilter,
                      dateRange: _selectedDateRange,
                    ),
                  ),
                ),

                // Charts Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ActivityCharts(selectedFilter: _selectedFilter),
                  ),
                ),

                // Bottom safe padding
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF6A1B9A), // Stronger purple
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _headerAnimation.value)),
              child: Opacity(
                opacity: _headerAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        const Color(
                          0xFF6A1B9A,
                        ).withOpacity(0.05), // Stronger purple
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6A1B9A), // Stronger purple
                                  const Color(
                                    0xFF8E24AA,
                                  ), // Stronger purple variant
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.insights,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📊 Daily Activity Overview',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6A1B9A), // Stronger purple
                                  ),
                                ),
                                Text(
                                  'Track your daily behavior trends and usage statistics',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _showDatePicker,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6A1B9A,
                                ).withOpacity(0.12), // Better contrast
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF6A1B9A), // Stronger purple
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatDateRange(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDateRange() {
    if (_selectedDateRange == null) return '';

    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return DateFormat('yyyy-MM-dd').format(start);
    } else {
      return '${DateFormat('MM-dd').format(start)} - ${DateFormat('MM-dd').format(end)}';
    }
  }

  void _onFilterChanged(String filter) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await _checkForActivities();

    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _showDatePicker() async {
    HapticFeedback.lightImpact();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF6A1B9A), // Stronger purple
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }
}
