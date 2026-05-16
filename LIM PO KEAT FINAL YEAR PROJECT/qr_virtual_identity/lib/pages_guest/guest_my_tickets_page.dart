// lib/pages_guest/guest_my_tickets_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/guest_service.dart';
import '../services/event_service.dart';
import 'guest_ticket_page.dart';

/// 🎫 Guest My Tickets Page
/// Displays all tickets for joined events
class GuestMyTicketsPage extends StatelessWidget {
  const GuestMyTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = GuestService.getCurrentUser();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Tickets'),
          backgroundColor: const Color(0xFF512DA8),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please login to view your tickets')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: GuestService.getUserTicketsStream(user.uid),
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

          // Show all tickets (active and cancelled/inactive)
          final tickets = snapshot.data?.docs ?? [];

          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tickets yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join an event to get your ticket',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticketData = tickets[index].data() as Map<String, dynamic>;
              return _buildTicketCard(context, tickets[index].id, ticketData);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    String ticketId,
    Map<String, dynamic> ticketData,
  ) {
    final eventId = ticketData['event_id'] as String;
    final eventName = ticketData['event_name'] as String;
    final status = ticketData['status'] as String? ?? 'active';
    final verified = ticketData['verified'] as bool? ?? false;
    final createdAt = ticketData['created_at'] as Timestamp?;

    return FutureBuilder<DocumentSnapshot>(
      future: EventService.getEventById(eventId),
      builder: (context, eventSnapshot) {
        Map<String, dynamic> eventData = {};
        if (eventSnapshot.hasData && eventSnapshot.data!.exists) {
          eventData = eventSnapshot.data!.data() as Map<String, dynamic>;
        }

        final eventDate = eventData['date'] as String? ?? '';
        final eventLocation = eventData['location'] as String? ?? '';
        final category = eventData['category'] as String? ?? 'event';
        final imageUrl = eventData['image_url'] as String?;

        final isActive = status == 'active';

        return Card(
          key: ValueKey(ticketId),
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: GestureDetector(
            onTap: isActive
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GuestTicketPage(ticketId: ticketId),
                      ),
                    );
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This ticket has been cancelled'),
                      ),
                    );
                  },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Image with Status Overlay
                Stack(
                  children: [
                    // Always provide a sized base so Stack has layout
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  color: const Color(0xFF512DA8),
                                  child: const Center(
                                    child: Icon(
                                      Icons.event,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 120,
                              width: double.infinity,
                              color: const Color(0xFF512DA8),
                              child: const Center(
                                child: Icon(
                                  Icons.event,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    // Status Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: verified
                              ? Colors.green
                              : isActive
                              ? const Color(0xFF512DA8)
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              verified
                                  ? Icons.verified
                                  : isActive
                                  ? Icons.confirmation_number
                                  : Icons.cancel,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              verified
                                  ? 'VERIFIED'
                                  : isActive
                                  ? 'ACTIVE'
                                  : 'CANCELLED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // If not active, add a dim overlay
                    if (!isActive)
                      Positioned.fill(
                        child: Container(color: Colors.black.withOpacity(0.25)),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isActive) ...[
                        Row(
                          children: const [
                            Icon(Icons.block, size: 16, color: Colors.grey),
                            SizedBox(width: 6),
                            Text(
                              'This registration was cancelled',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Category
                      Chip(
                        label: Text(
                          category.toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: const Color(0xFFFFA000),
                        labelStyle: const TextStyle(color: Colors.white),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(height: 8),

                      // Event Name
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Date
                      if (eventDate.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(eventDate),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // Location
                      if (eventLocation.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                eventLocation,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // Registered Date
                      if (createdAt != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Registered: ${DateFormat('MMM d, yyyy').format(createdAt.toDate())}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // View Ticket Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: isActive
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            GuestTicketPage(ticketId: ticketId),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.qr_code_2, size: 18),
                            label: const Text('View Ticket'),
                            style: TextButton.styleFrom(
                              foregroundColor: isActive
                                  ? const Color(0xFF512DA8)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
