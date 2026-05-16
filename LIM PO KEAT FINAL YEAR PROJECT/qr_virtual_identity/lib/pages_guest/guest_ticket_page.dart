// lib/pages_guest/guest_ticket_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../services/guest_service.dart';
import '../services/event_service.dart';

/// 🎫 Guest Ticket Page
/// Displays QR code ticket for event entry
class GuestTicketPage extends StatelessWidget {
  final String ticketId;

  const GuestTicketPage({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ticket'),
        backgroundColor: const Color(0xFF512DA8),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: GuestService.getTicketByIdStream(ticketId),
        builder: (context, ticketSnapshot) {
          if (ticketSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${ticketSnapshot.error}'),
                ],
              ),
            );
          }

          if (ticketSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!ticketSnapshot.hasData || !ticketSnapshot.data!.exists) {
            return const Center(child: Text('Ticket not found'));
          }

          final ticketData =
              ticketSnapshot.data!.data() as Map<String, dynamic>;
          final eventId = ticketData['event_id'] as String;

          return StreamBuilder<DocumentSnapshot>(
            stream: EventService.getEventByIdStream(eventId),
            builder: (context, eventSnapshot) {
              if (!eventSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final eventData =
                  eventSnapshot.data!.data() as Map<String, dynamic>? ?? {};

              return _buildTicketContent(context, ticketData, eventData);
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketContent(
    BuildContext context,
    Map<String, dynamic> ticketData,
    Map<String, dynamic> eventData,
  ) {
    final ticketId = ticketData['ticket_id'] as String;
    final eventName = ticketData['event_name'] as String;
    final userName = ticketData['user_name'] as String;
    final userEmail = ticketData['user_email'] as String;
    final qrCode = ticketData['qr_code'] as String;
    final status = ticketData['status'] as String;
    final verified = ticketData['verified'] as bool? ?? false;
    final createdAt = ticketData['created_at'] as Timestamp?;

    final eventDate = eventData['date'] as String? ?? '';
    final eventTime =
        '${eventData['start_time'] ?? ''} - ${eventData['end_time'] ?? ''}';
    final eventLocation = eventData['location'] as String? ?? '';

    final isActive = status == 'active';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      ? Icons.check_circle
                      : isActive
                      ? Icons.confirmation_number
                      : Icons.cancel,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  verified
                      ? 'VERIFIED'
                      : isActive
                      ? 'ACTIVE'
                      : 'CANCELLED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ticket Card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF512DA8),
                        width: 3,
                      ),
                    ),
                    child: QrImageView(
                      data: qrCode,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF512DA8),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF512DA8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Event Details
                  _buildDetailRow(Icons.event, 'Event', eventName),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Date',
                    _formatDate(eventDate),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.access_time, 'Time', eventTime),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on, 'Location', eventLocation),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // User Details
                  _buildDetailRow(Icons.person, 'Name', userName),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.email, 'Email', userEmail),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Ticket ID
                  Text(
                    'Ticket ID',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticketId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                  ),

                  if (createdAt != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Registered: ${DateFormat('MMM d, yyyy • h:mm a').format(createdAt.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Present this QR code at the event entrance for verification',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Cancel Button (only if not verified)
          if (isActive && !verified)
            OutlinedButton.icon(
              onPressed: () => _showCancelDialog(context),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Registration'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF512DA8)),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Registration'),
        content: const Text(
          'Are you sure you want to cancel your registration for this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await GuestService.cancelRegistration(ticketId: ticketId);

      if (context.mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to cancel'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
