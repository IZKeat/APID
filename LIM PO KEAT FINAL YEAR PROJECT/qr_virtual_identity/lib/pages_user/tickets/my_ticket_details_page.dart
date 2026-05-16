// lib/pages_user/my_ticket_details_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/user_event_service.dart';
import '../models/event_model.dart';

/// 🎫 My Ticket Details Page with QR Code
/// Features: QR generation, cancel functionality, status management
class MyTicketDetailsPage extends StatefulWidget {
  final String eventId;

  const MyTicketDetailsPage({super.key, required this.eventId});

  @override
  State<MyTicketDetailsPage> createState() => _MyTicketDetailsPageState();
}

class _MyTicketDetailsPageState extends State<MyTicketDetailsPage>
    with TickerProviderStateMixin {
  final UserEventService _eventService = UserEventService();

  late AnimationController _qrAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _qrScaleAnimation;
  late Animation<Offset> _slideAnimation;

  EventModel? _event;
  bool _isLoading = true;
  String _ticketStatus = 'active';

  @override
  void initState() {
    super.initState();

    _qrAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _qrScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _qrAnimationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _loadTicketData();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _qrAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  /// 📊 Load Ticket and Event Data
  Future<void> _loadTicketData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Get event details
      final events = await _eventService.getAllEvents().first;
      final event = events.firstWhere(
        (e) => e.eventId == widget.eventId,
        orElse: () => throw Exception('Event not found'),
      );

      // Fetch actual ticket status from user_tickets collection
      final ticketDoc = await FirebaseFirestore.instance
          .collection('user_tickets')
          .doc('${widget.eventId}_${currentUser.uid}')
          .get();

      String status = 'active';
      if (ticketDoc.exists) {
        status = ticketDoc.data()?['status'] ?? 'active';
      }

      setState(() {
        _event = event;
        _ticketStatus = status;
        _isLoading = false;
      });

      // Start QR animation after data loads
      await Future.delayed(const Duration(milliseconds: 300));
      _qrAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading ticket data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Ticket',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildLoadingState() : _buildTicketContent(),
    );
  }

  /// 🔄 Loading State
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading ticket...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎫 Ticket Content
  Widget _buildTicketContent() {
    if (_event == null) {
      return _buildErrorState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTicketCard(),
            const SizedBox(height: 24),
            _buildEventDetails(),
            const SizedBox(height: 24),
            if (_ticketStatus == 'attended') _buildAttendedInfo(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 🎫 Main Ticket Card with QR Code
  Widget _buildTicketCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: _ticketStatus == 'active'
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              )
            : _ticketStatus == 'attended'
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green[600]!, Colors.green[500]!],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[600]!, Colors.grey[500]!],
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _ticketStatus == 'active'
                ? AppTheme.primaryColor.withOpacity(0.3)
                : _ticketStatus == 'attended'
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _ticketStatus == 'active'
                      ? Icons.check_circle
                      : _ticketStatus == 'attended'
                      ? Icons.verified
                      : Icons.cancel,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _ticketStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Show Identity QR Button (Replaces Ticket QR)
          ScaleTransition(
            scale: _qrScaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_2,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Use Identity QR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Show your Identity QR at the entrance to check in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to Identity QR Page
                      Navigator.pushNamed(context, '/qr_show');
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Show Identity QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Event Name
          Text(
            _event!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Registration ID (formerly Ticket ID)
          Text(
            'Reg ID: ${_generateTicketId()}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Event Details Section
  Widget _buildEventDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            _formatEventDate(_event!.date),
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),

          _buildDetailRow(
            Icons.access_time,
            'Time',
            '${_event!.startTime} - ${_event!.endTime}',
            Colors.blue[600]!,
          ),
          const SizedBox(height: 16),

          _buildDetailRow(
            Icons.location_on,
            'Location',
            _event!.location,
            Colors.red[500]!,
          ),
          const SizedBox(height: 16),

          _buildDetailRow(
            Icons.business,
            'Organizer',
            _event!.organizer,
            Colors.green[600]!,
          ),
          const SizedBox(height: 16),

          _buildDetailRow(
            Icons.category,
            'Category',
            _event!.category.toUpperCase(),
            _getCategoryColor(_event!.category),
          ),

          // Registration Info
          if (_ticketStatus == 'active') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[300]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber[800], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Present your Identity QR code at the event entrance for verification',
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_ticketStatus == 'cancelled') ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red[800], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This ticket has been cancelled and is no longer valid',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📝 Detail Row
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ Attended Info Card
  Widget _buildAttendedInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[300]!, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 48),
          const SizedBox(height: 12),
          Text(
            'Check-in Completed',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have successfully attended this event',
            style: TextStyle(color: Colors.green[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ❌ Error State
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Ticket Not Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load ticket details',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
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

  /// 📅 Format Date
  String _formatEventDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('EEEE, MMMM dd, yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  /// 🆔 Generate Ticket ID
  String _generateTicketId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';
    final shortUserId = userId.length > 8 ? userId.substring(0, 8) : userId;
    final shortEventId = widget.eventId.length > 6
        ? widget.eventId.substring(0, 6)
        : widget.eventId;
    return 'TKT-$shortEventId-$shortUserId'.toUpperCase();
  }
}
