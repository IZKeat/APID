// lib/utils/ticket_parser.dart

/// 🎫 Ticket Parser Class
/// Parses and validates QR ticket format: "TICKET:event_id:user_id:timestamp"
class TicketParser {
  final String eventId;
  final String userId;
  final DateTime timestamp;

  const TicketParser._({
    required this.eventId,
    required this.userId,
    required this.timestamp,
  });

  /// Parse QR code data into TicketParser
  /// Format: "TICKET:event_id:user_id:timestamp"
  static TicketParser? fromQrData(String qrData) {
    try {
      final parts = qrData.trim().split(':');

      // Validate format
      if (parts.length != 4 || parts[0] != 'TICKET') {
        return null;
      }

      final eventId = parts[1].trim();
      final userId = parts[2].trim();
      final timestampStr = parts[3].trim();

      // Validate non-empty fields
      if (eventId.isEmpty || userId.isEmpty || timestampStr.isEmpty) {
        return null;
      }

      // Parse timestamp (could be milliseconds since epoch or ISO string)
      DateTime timestamp;
      try {
        // Try parsing as milliseconds first
        final milliseconds = int.tryParse(timestampStr);
        if (milliseconds != null) {
          timestamp = DateTime.fromMillisecondsSinceEpoch(milliseconds);
        } else {
          // Try parsing as ISO string
          timestamp = DateTime.parse(timestampStr);
        }
      } catch (e) {
        return null;
      }

      return TicketParser._(
        eventId: eventId,
        userId: userId,
        timestamp: timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if ticket is expired (max 30 minutes old)
  bool get isExpired {
    final now = DateTime.now();
    final timeDifference = now.difference(timestamp);
    return timeDifference.inMinutes > 30;
  }

  /// Get age of ticket in minutes
  int get ageInMinutes {
    final now = DateTime.now();
    return now.difference(timestamp).inMinutes;
  }

  /// Validate ticket format and structure
  bool get isValid {
    return eventId.isNotEmpty &&
        userId.isNotEmpty &&
        timestamp.isBefore(
          DateTime.now().add(const Duration(minutes: 1)),
        ); // Allow small clock drift
  }

  /// Generate a unique identifier for this ticket scan
  String get scanId {
    return '${eventId}_${userId}_${timestamp.millisecondsSinceEpoch}';
  }

  @override
  String toString() {
    return 'TicketParser(eventId: $eventId, userId: $userId, timestamp: $timestamp, isExpired: $isExpired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TicketParser &&
        other.eventId == eventId &&
        other.userId == userId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(eventId, userId, timestamp);
  }
}
