// lib/widgets/event_card_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// 🃏 Reusable Event Card Widget
/// Used across different pages for consistent event display
class EventCardWidget extends StatelessWidget {
  final Map<String, dynamic> eventData;
  final VoidCallback onJoinPressed;
  final bool showJoinButton;
  final VoidCallback? onTap;

  const EventCardWidget({
    super.key,
    required this.eventData,
    required this.onJoinPressed,
    this.showJoinButton = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = eventData['name'] as String;
    final date = eventData['date'] as String;
    final location = eventData['location'] as String;
    final category = eventData['category'] as String? ?? 'event';
    final capacity = eventData['capacity'] as int? ?? 0;
    final currentAttendees = eventData['current_attendees'] as int? ?? 0;
    final availableSlots = capacity - currentAttendees;
    final isFull = currentAttendees >= capacity;
    final organizer = eventData['organizer'] as String? ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header Image/Gradient
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: Icon(Icons.event, size: 50, color: Colors.white54),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildCategoryChip(category),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildCapacityChip(availableSlots, isFull),
                  ),
                ],
              ),
            ),

            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(
                    name,
                    style: AppTheme.heading3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Date & Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(date),
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Organizer
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        organizer,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  if (showJoinButton) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isFull ? null : onJoinPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          isFull ? 'Event Full' : 'Join Event',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCapacityChip(int availableSlots, bool isFull) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFull ? AppTheme.errorColor : AppTheme.successColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isFull ? 'FULL' : '$availableSlots left',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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

/// 🎫 Ticket Card Widget for My Tickets section
class TicketCardWidget extends StatelessWidget {
  final Map<String, dynamic> ticketData;
  final VoidCallback onViewTicket;
  final VoidCallback? onTap;

  const TicketCardWidget({
    super.key,
    required this.ticketData,
    required this.onViewTicket,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventName = ticketData['event_name'] as String? ?? 'Unknown Event';
    final eventDate = ticketData['event_date'] as String? ?? '';
    final eventLocation = ticketData['event_location'] as String? ?? '';
    final category = ticketData['category'] as String? ?? 'event';
    final status = ticketData['status'] as String? ?? 'active';

    final isActive = status.toLowerCase() == 'active';
    final isPast = _isEventPast(eventDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ]
                  : [
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.05),
                    ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCategoryChip(category, isActive),
                    _buildStatusChip(isPast, isActive),
                  ],
                ),
                const SizedBox(height: 12),

                // Event Name
                Text(
                  eventName,
                  style: AppTheme.heading3.copyWith(
                    color: isActive
                        ? AppTheme.textPrimary
                        : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isActive ? AppTheme.textSecondary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(eventDate),
                      style: AppTheme.bodyMedium.copyWith(
                        color: isActive ? AppTheme.textSecondary : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isActive ? AppTheme.textSecondary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        eventLocation,
                        style: AppTheme.bodyMedium.copyWith(
                          color: isActive
                              ? AppTheme.textSecondary
                              : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // View Ticket Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isActive ? onViewTicket : null,
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('View Ticket'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      side: BorderSide(
                        color: isActive ? AppTheme.primaryColor : Colors.grey,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.accentColor.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          color: isActive ? AppTheme.accentColor : Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isPast, bool isActive) {
    String text;
    Color color;

    if (isPast) {
      text = 'PAST';
      color = Colors.grey;
    } else if (isActive) {
      text = 'ACTIVE';
      color = AppTheme.successColor;
    } else {
      text = 'CANCELLED';
      color = AppTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  bool _isEventPast(String dateStr) {
    try {
      final eventDate = DateTime.parse(dateStr);
      return eventDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
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
