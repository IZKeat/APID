// lib/pages_user/my_tickets_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/user_event_service.dart';
import '../models/event_model.dart';
import 'my_ticket_details_page.dart';
import '../widgets/event_skeleton_card.dart';

/// 🎫 My Tickets Page - User's Event Registrations
/// Features: Ticket status badges, empty states, smooth navigation
class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage>
    with SingleTickerProviderStateMixin {
  final UserEventService _eventService = UserEventService();
  late AnimationController _animationController;

  String _selectedStatus = 'all';
  final List<String> _statusFilters = [
    'all',
    'active',
    'attended',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(child: _buildTicketsList(currentUser.uid)),
        ],
      ),
    );
  }

  /// 🔐 Login Prompt
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Please Log In',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to view your event tickets',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  /// 🎛️ Filter Section
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Tickets',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _statusFilters.map((status) {
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    }
                  },
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  elevation: isSelected ? 4 : 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 📋 Tickets List
  Widget _buildTicketsList(String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: StreamBuilder<List<EventModel>>(
        stream: _eventService.getUserJoinedEvents(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return Stack(
              children: [
                ListView(), // Allow pull-to-refresh on error
                _buildErrorState(snapshot.error.toString()),
              ],
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Stack(
              children: [
                ListView(), // Allow pull-to-refresh on empty
                _buildEmptyState(
                  'No Tickets Found',
                  'Join events to see your tickets here',
                  Icons.confirmation_number_outlined,
                ),
              ],
            );
          }

          final events = snapshot.data!;

          // Filter events by ticket status
          final filteredEvents = _selectedStatus == 'all'
              ? events
              : events
                    .where(
                      (event) => (event.status ?? 'active') == _selectedStatus,
                    )
                    .toList();

          if (filteredEvents.isEmpty) {
            return Stack(
              children: [
                ListView(), // Allow pull-to-refresh on empty filter
                _buildEmptyState(
                  'No ${_getStatusLabel(_selectedStatus)} Tickets',
                  'Try changing the filter',
                  Icons.filter_list_off,
                ),
              ],
            );
          }

          return AnimatedList(
            padding: const EdgeInsets.all(16),
            initialItemCount: filteredEvents.length,
            itemBuilder: (context, index, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: _buildTicketCard(filteredEvents[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🎫 Ticket Card
  Widget _buildTicketCard(EventModel event) {
    final bool isCancelled = (event.status ?? 'active') == 'cancelled';
    final bool isAttended = (event.status ?? 'active') == 'attended';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Opacity(
        opacity: isCancelled ? 0.6 : 1.0, // Dim cancelled tickets
        child: Card(
          elevation: isCancelled ? 2 : 6, // Reduce elevation for cancelled
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isCancelled
                ? null
                : () => Navigator.pushNamed(context, '/qr_show'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: isCancelled
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[100],
                    )
                  : isAttended
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.green[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isCancelled
                                    ? Colors.grey
                                    : AppTheme.primaryColor,
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                      _buildStatusBadge(event.status ?? 'active'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Attended success banner
                  if (isAttended) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CHECK-IN COMPLETED',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Cancelled overlay text
                  if (isCancelled) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, color: Colors.red[600], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'TICKET CANCELLED',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Event Details
                  _buildTicketDetailRow(
                    Icons.calendar_today,
                    _formatEventDate(event.date, event.startTime),
                    isCancelled ? Colors.grey : AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  _buildTicketDetailRow(
                    Icons.location_on,
                    event.location,
                    isCancelled ? Colors.grey : Colors.red[400]!,
                  ),
                  const SizedBox(height: 8),
                  _buildTicketDetailRow(
                    Icons.category,
                    event.category.toUpperCase(),
                    isCancelled
                        ? Colors.grey
                        : _getCategoryColor(event.category),
                  ),

                  if (!isCancelled && !isAttended) ...[
                    const SizedBox(height: 16),
                    // Action Row - Only show for active tickets
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 16,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap to sign attendance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🏷️ Status Badge
  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status.toLowerCase()) {
      case 'active':
        badgeColor = Colors.green[600]!;
        badgeText = 'ACTIVE';
        badgeIcon = Icons.check_circle;
        break;
      case 'attended':
        badgeColor = Colors.blue[600]!;
        badgeText = 'ATTENDED';
        badgeIcon = Icons.verified;
        break;
      case 'cancelled':
        badgeColor = Colors.red[600]!;
        badgeText = 'CANCELLED';
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.grey[600]!;
        badgeText = 'UNKNOWN';
        badgeIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Ticket Detail Row
  Widget _buildTicketDetailRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  /// 🔄 Loading State
  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => const EventSkeletonCard(),
    );
  }

  /// ❌ Error State
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Tickets',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚫 Empty State
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_animationController.value * 0.2),
                child: Icon(icon, size: 80, color: Colors.grey[400]),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate back to All Events tab if TabController exists,
              // otherwise navigate to events page
              if (mounted) {
                try {
                  final tabController = DefaultTabController.of(context);
                  tabController.animateTo(0);
                } catch (e) {
                  // If no TabController found, navigate to events page
                  Navigator.of(context).pushReplacementNamed('/user_events');
                }
              }
            },
            icon: const Icon(Icons.event_available),
            label: const Text('Browse Events'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Category Color
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'seminar':
        return Colors.blue[600]!;
      case 'workshop':
        return Colors.orange[600]!;
      case 'competition':
        return Colors.red[600]!;
      case 'networking':
        return Colors.purple[600]!;
      case 'career_fair':
        return Colors.green[600]!;
      default:
        return AppTheme.primaryColor;
    }
  }

  /// 📅 Format Event Date
  String _formatEventDate(String date, String time) {
    try {
      final dateTime = DateTime.parse(date);
      final formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
      return '$formattedDate • $time';
    } catch (e) {
      return '$date • $time';
    }
  }

  /// 🏷️ Status Label
  String _getStatusLabel(String status) {
    switch (status) {
      case 'all':
        return 'All';
      case 'active':
        return 'Active';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  /// 🧭 Navigate to Ticket Details
  void _navigateToTicketDetails(String eventId) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MyTicketDetailsPage(eventId: eventId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
