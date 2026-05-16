// lib/pages_guest/guest_events_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/event_service.dart';
import '../services/guest_service.dart';
import 'guest_event_detail_page.dart';
import 'guest_my_tickets_page.dart';

/// 🎫 Guest Events Page - Event List View
/// Displays all public events with real-time Firestore updates
class GuestEventsPage extends StatefulWidget {
  const GuestEventsPage({super.key});

  @override
  State<GuestEventsPage> createState() => _GuestEventsPageState();
}

class _GuestEventsPageState extends State<GuestEventsPage> {
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'All Events'},
    {'id': 'seminar', 'name': 'Seminars'},
    {'id': 'workshop', 'name': 'Workshops'},
    {'id': 'competition', 'name': 'Competitions'},
    {'id': 'career_fair', 'name': 'Career Fair'},
    {'id': 'networking', 'name': 'Networking'},
    {'id': 'open_house', 'name': 'Open House'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = GuestService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text('APU Events'),
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GuestMyTicketsPage(),
                ),
              );
            },
            tooltip: 'My Tickets',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await GuestService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category['id']!;
                      });
                    },
                    selectedColor: const Color(0xFF512DA8),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Events List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedCategory == 'all'
                  ? EventService.getPublicEventsStream()
                  : EventService.getEventsByCategory(_selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data?.docs ?? [];

                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final eventData =
                        events[index].data() as Map<String, dynamic>;
                    return _buildEventCard(context, eventData, user?.uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    Map<String, dynamic> eventData,
    String? uid,
  ) {
    final eventId = eventData['event_id'] as String;
    final name = eventData['name'] as String;
    final date = eventData['date'] as String;
    final location = eventData['location'] as String;
    final category = eventData['category'] as String? ?? 'event';
    final imageUrl = eventData['image_url'] as String?;
    final capacity = eventData['capacity'] as int? ?? 0;
    final currentAttendees = eventData['current_attendees'] as int? ?? 0;
    final availableSlots = capacity - currentAttendees;
    final isFull = currentAttendees >= capacity;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuestEventDetailPage(eventId: eventId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: const Color(0xFF512DA8),
                      child: const Center(
                        child: Icon(Icons.event, size: 60, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
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
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(date),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Capacity Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: isFull ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isFull
                                ? 'Event Full'
                                : '$availableSlots/$capacity slots available',
                            style: TextStyle(
                              color: isFull ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
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
