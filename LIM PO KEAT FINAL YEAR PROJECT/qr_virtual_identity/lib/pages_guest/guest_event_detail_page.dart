// lib/pages_guest/guest_event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import '../services/guest_service.dart';
import 'guest_ticket_page.dart';

/// 🎫 Guest Event Detail Page
/// Displays detailed event information with Join button
class GuestEventDetailPage extends StatefulWidget {
  final String eventId;

  const GuestEventDetailPage({super.key, required this.eventId});

  @override
  State<GuestEventDetailPage> createState() => _GuestEventDetailPageState();
}

class _GuestEventDetailPageState extends State<GuestEventDetailPage> {
  bool _isJoining = false;
  bool _hasJoined = false;
  String? _ticketId;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    final user = GuestService.getCurrentUser();
    if (user == null) return;

    final hasJoined = await GuestService.hasJoinedEvent(
      user.uid,
      widget.eventId,
    );
    if (hasJoined) {
      // Get ticket ID
      final tickets = await GuestService.getUserTickets(user.uid);
      for (final ticket in tickets.docs) {
        final ticketData = ticket.data() as Map<String, dynamic>;
        if (ticketData['event_id'] == widget.eventId) {
          setState(() {
            _hasJoined = true;
            _ticketId = ticket.id;
          });
          break;
        }
      }
    }
  }

  Future<void> _joinEvent() async {
    final user = GuestService.getCurrentUser();
    if (user == null) {
      _showErrorSnackBar('Please login first');
      return;
    }

    setState(() => _isJoining = true);

    final result = await GuestService.joinEvent(
      eventId: widget.eventId,
      uid: user.uid,
    );

    setState(() => _isJoining = false);

    if (result['success'] == true) {
      final ticketId = result['ticket_id'] as String;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GuestTicketPage(ticketId: ticketId),
          ),
        );
      }
    } else {
      _showErrorSnackBar(result['error'] ?? 'Failed to join event');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: EventService.getEventByIdStream(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Event not found'));
          }

          final eventData = snapshot.data!.data() as Map<String, dynamic>;
          return _buildEventDetail(eventData);
        },
      ),
    );
  }

  Widget _buildEventDetail(Map<String, dynamic> eventData) {
    final name = eventData['name'] as String;
    final description = eventData['description'] as String;
    final date = eventData['date'] as String;
    final startTime = eventData['start_time'] as String? ?? '';
    final endTime = eventData['end_time'] as String? ?? '';
    final location = eventData['location'] as String;
    final category = eventData['category'] as String? ?? 'event';
    final imageUrl = eventData['image_url'] as String?;
    final organizer = eventData['organizer'] as String? ?? 'APU';
    final tags = List<String>.from(eventData['tags'] ?? []);
    final capacity = eventData['capacity'] as int? ?? 0;
    final currentAttendees = eventData['current_attendees'] as int? ?? 0;
    final availableSlots = capacity - currentAttendees;
    final isFull = currentAttendees >= capacity;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (imageUrl != null)
            Image.network(
              imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: const Color(0xFF512DA8),
                  child: const Center(
                    child: Icon(Icons.event, size: 80, color: Colors.white),
                  ),
                );
              },
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Badge
                Chip(
                  label: Text(
                    category.toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFFFFA000),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),

                // Event Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Info Cards
                _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(date)),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.access_time,
                  'Time',
                  '$startTime - $endTime',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, 'Location', location),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.business, 'Organizer', organizer),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.people,
                  'Capacity',
                  isFull
                      ? 'Event Full ($currentAttendees/$capacity)'
                      : '$availableSlots slots available ($currentAttendees/$capacity)',
                  color: isFull ? Colors.red : Colors.green,
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'About This Event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),

                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Tags',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 32),

                // Join Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _hasJoined
                        ? () {
                            if (_ticketId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GuestTicketPage(ticketId: _ticketId!),
                                ),
                              );
                            }
                          }
                        : (isFull || _isJoining ? null : _joinEvent),
                    icon: Icon(
                      _hasJoined
                          ? Icons.confirmation_number
                          : _isJoining
                          ? Icons.hourglass_empty
                          : Icons.add_circle,
                    ),
                    label: Text(
                      _hasJoined
                          ? 'View My Ticket'
                          : _isJoining
                          ? 'Joining...'
                          : isFull
                          ? 'Event Full'
                          : 'Join Event',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasJoined
                          ? Colors.green
                          : const Color(0xFF512DA8),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
