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
  final EventModel event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final UserEventService _eventService = UserEventService();
  final ScrollController _scrollController = ScrollController();

  bool _hasJoined = false;

  bool _isJoining = false;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _checkUserJoinedStatus();
    _scrollController.addListener(_onScroll);
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
        widget.event.eventId,
        currentUser.uid,
      );

      if (mounted) {
        setState(() {
          _hasJoined = hasJoined;
        });
      }
    } catch (e) {

      debugPrint('Error checking join status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        _buildHorizontalInfoWidgets(),
                        const SizedBox(height: 24),
                        _buildEventDescription(),
                        const SizedBox(height: 24),
                        _buildEventTags(),
                        const SizedBox(height: 120), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          ),

          // Sticky Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  /// 📸 Sliver App Bar with Hero Image
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: const Color(0xFF1D192B),
      elevation: 0,
      leading: const SizedBox(), // Custom back button used
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedOpacity(
          opacity: _showTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.event.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Event Image
            widget.event.imageUrl != null
                ? Image.network(
                    widget.event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultEventImage(),
                  )
                : _buildDefaultEventImage(),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1D192B).withValues(alpha: 0.3),
                    const Color(0xFF1D192B).withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Hero Content (Title & Tag)
            Positioned(
              bottom: 60,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          widget.event.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      if (_hasJoined) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00639B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(),
                              const SizedBox(width: 6),
                              const Text(
                                'JOINED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    widget.event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Organized by ${widget.event.organizer}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ],
        ),
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
    final remainingSlots = widget.event.capacity - widget.event.currentAttendees;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildInfoWidget(
            icon: Icons.calendar_today,
            label: 'Date & Time',
            title: widget.event.formattedDate,
            subtitle: '${widget.event.startTime} - ${widget.event.endTime}',
            color: const Color(0xFFE8DEF8),
            textColor: const Color(0xFF1D192B),
            delay: 0.1,
          ),
          const SizedBox(width: 16),
          _buildInfoWidget(
            icon: Icons.location_on_outlined,
            label: 'Location',
            title: 'APU Campus',
            subtitle: widget.event.location,
            color: const Color(0xFFFFD8E4),
            textColor: const Color(0xFF31111D),
            delay: 0.2,
          ),
          const SizedBox(width: 16),
          _buildInfoWidget(
            icon: Icons.people_outline,
            label: 'Capacity',
            title: '${widget.event.currentAttendees}/${widget.event.capacity} attendees',
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
            widget.event.description ?? "Hands-on workshop! Suitable for beginners. Bring your laptop and let's code!",
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
    final tags = ['workshop', 'mobile', 'coding', widget.event.category.toLowerCase()];
    
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
    final isExpired = widget.event.isPast;

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
        widget.event.eventId,
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
        builder: (context) => MyTicketDetailsPage(eventId: widget.event.eventId),
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
