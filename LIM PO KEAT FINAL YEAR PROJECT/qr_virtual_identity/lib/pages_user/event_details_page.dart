// lib/pages_user/event_details_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../services/user_event_service.dart';
import '../models/event_model.dart';
import 'my_ticket_details_page.dart';

/// 🎯 Event Details Page with Join/View Ticket Logic
/// Features: Detailed event info, dynamic button states, smooth transitions
class EventDetailsPage extends StatefulWidget {
  final EventModel? event;
  final String? eventId;

  const EventDetailsPage({
    super.key, 
    this.event, 
    this.eventId,
  }) : assert(event != null || eventId != null, 'Either event or eventId must be provided');

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final UserEventService _eventService = UserEventService();
  final ScrollController _scrollController = ScrollController();

  late EventModel _event;
  bool _isLoading = true;
  bool _hasError = false;

  bool _hasJoined = false;
  bool _isJoining = false;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _initEventData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initEventData() async {
    if (widget.event != null) {
      _event = widget.event!;
      _isLoading = false;
      _checkUserJoinedStatus();
    } else if (widget.eventId != null) {
      await _fetchEventDetails(widget.eventId!);
    }
  }

  Future<void> _fetchEventDetails(String id) async {
    try {
      final event = await _eventService.getEventDetails(id);
      if (event != null) {
        if (mounted) {
          setState(() {
            _event = event;
            _isLoading = false;
          });
          _checkUserJoinedStatus();
        }
      } else {
        _handleLoadError();
      }
    } catch (e) {
      debugPrint('Error fetching event details: $e');
      _handleLoadError();
    }
  }

  void _handleLoadError() {
    if (mounted) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      bool show = _scrollController.offset > 200;
      if (show != _showTitle) {
        setState(() {
          _showTitle = show;
        });
      }
    }
  }

  /// 🔍 Check if user has already joined this event
  Future<void> _checkUserJoinedStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final hasJoined = await _eventService.hasUserJoined(
        _event.eventId,
        currentUser.uid,
      );

      if (mounted) {
        setState(() {
          _hasJoined = hasJoined;
        });
      }
    } catch (e) {
      print('Error checking joined status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load event details'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _initEventData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sliver App Bar with Image
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: _showTitle
                      ? Text(
                          _event.name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _event.imageUrl != null
                          ? Image.network(
                              _event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDefaultEventImage(),
                            )
                          : _buildDefaultEventImage(),
                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _event.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Organized by ${_event.organizer}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 32),

                      // Info Widgets
                      _buildHorizontalInfoWidgets(),

                      const SizedBox(height: 32),

                      // Event Description
                      _buildEventDescription(),

                      const SizedBox(height: 24),

                      // Tags
                      _buildEventTags(),
                      
                      // Extra padding for bottom bar
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  /// 🖼️ Default Event Image
  Widget _buildDefaultEventImage() {
    return Container(
      color: const Color(0xFF1D192B),
      child: Center(
        child: Icon(
          Icons.event,
          size: 80,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  /// 📊 Horizontal Info Widgets
  Widget _buildHorizontalInfoWidgets() {
    final remainingSlots = _event.capacity - _event.currentAttendees;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildInfoWidget(
            icon: Icons.calendar_today,
            label: 'Date & Time',
            title: _event.formattedDate,
            subtitle: '${_event.startTime} - ${_event.endTime}',
            color: const Color(0xFFE8DEF8),
            textColor: const Color(0xFF1D192B),
            delay: 0.1,
          ),
          const SizedBox(width: 16),
          _buildInfoWidget(
            icon: Icons.location_on_outlined,
            label: 'Location',
            title: 'APU Campus',
            subtitle: _event.location,
            color: const Color(0xFFFFD8E4),
            textColor: const Color(0xFF31111D),
            delay: 0.2,
          ),
          const SizedBox(width: 16),
          _buildInfoWidget(
            icon: Icons.people_outline,
            label: 'Capacity',
            title: '${_event.currentAttendees}/${_event.capacity} attendees',
            subtitle: '$remainingSlots slots remaining',
            color: const Color(0xFFC3EED0),
            textColor: const Color(0xFF053916),
            delay: 0.3,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoWidget({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    double delay = 0,
  }) {
    return Container(
      width: 200,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: textColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (delay * 1000).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  /// 📖 Event Description
  Widget _buildEventDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Event',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6750A4),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _event.description ?? "Hands-on workshop! Suitable for beginners. Bring your laptop and let's code!",
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF49454F),
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  /// 🏷️ Event Tags
  Widget _buildEventTags() {
    final tags = ['workshop', 'mobile', 'coding', _event.category.toLowerCase()];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF49454F),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  /// 🔘 Bottom Action Bar
  Widget _buildBottomBar() {
    final isExpired = _event.isPast;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              // Share Button
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EDF7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined, color: Color(0xFF1D192B)),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 16),
              
              // Action Button
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isJoining 
                        ? null 
                        : (isExpired && !_hasJoined) // If expired and NOT joined, show error
                            ? () => _showSnackBar('This event is expired. Please try another event.', isError: true)
                            : (_hasJoined ? _navigateToTicketDetails : _joinEvent),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isExpired && !_hasJoined)
                          ? Colors.grey // Grey for expired
                          : (_hasJoined ? const Color(0xFF00639B) : const Color(0xFF16A34A)),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      shadowColor: (isExpired && !_hasJoined)
                          ? Colors.transparent
                          : (_hasJoined 
                              ? const Color(0xFF00639B).withValues(alpha: 0.2) 
                              : const Color(0xFF16A34A).withValues(alpha: 0.2)),
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                (isExpired && !_hasJoined) 
                                    ? Icons.event_busy 
                                    : (_hasJoined ? Icons.confirmation_number_outlined : Icons.check_circle_outline)
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (isExpired && !_hasJoined) 
                                    ? 'Event Expired' 
                                    : (_hasJoined ? 'View Ticket' : 'Book Slot'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutBack);
  }

  /// ✅ Join Event Action
  Future<void> _joinEvent() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Please login to join events', isError: true);
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final result = await _eventService.joinEvent(
        _event.eventId,
        currentUser.uid,
      );

      if (result['success']) {
        setState(() {
          _hasJoined = true;
          _isJoining = false;
        });

        _showSnackBar(
          'Registration Successful! Ticket added to My Booking.',
          isError: false,
        );
      } else {
        setState(() {
          _isJoining = false;
        });
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      setState(() {
        _isJoining = false;
      });
      _showSnackBar('Failed to join event: $e', isError: true);
    }
  }

  /// 🎫 Navigate to Ticket Details
  void _navigateToTicketDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyTicketDetailsPage(eventId: _event.eventId),
      ),
    );
  }

  /// 📢 Show Snack Bar
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
