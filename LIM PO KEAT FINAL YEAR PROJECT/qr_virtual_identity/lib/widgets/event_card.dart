import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import 'jelly_card.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final Color color;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Parse date
    DateTime? date;
    try {
      date = DateFormat('yyyy-MM-dd').parse(event.date);
    } catch (e) {
      date = DateTime.now();
    }

    final month = DateFormat('MMM').format(date).toUpperCase();
    final day = DateFormat('dd').format(date);

    return JellyCard(
      title: '',
      backgroundColor: color,
      contentColor: const Color(0xFF1D192B),
      padding: EdgeInsets.zero,
      onTap: onTap,
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Block
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    month,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF49454F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D192B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D192B),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFF49454F)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF49454F),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time & Tag
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Color(0xFF49454F)),
                      const SizedBox(width: 4),
                      Text(
                        '${event.startTime} - ${event.endTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF49454F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF1D192B).withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D192B),
                          ),
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
  }
}
