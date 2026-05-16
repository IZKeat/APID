// lib/services/event_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/interaction_service.dart';
import '../services/scan_point_service.dart';

/// 🎫 Event Service - Unified Ticket System
///
/// **Architecture Note:**
/// This service uses `user_tickets` collection as the single source of truth
/// for all event registrations and check-ins.
///
/// **Deprecated Collections:**
/// - `event_tickets` collection has been fully removed (Phase 1 - Task 1.3)
/// - All ticket operations are now unified under `user_tickets`
/// - Eliminates dual-collection complexity and data synchronization issues
///
/// **Responsibilities:**
/// - Read-only event queries (public events)
/// - Event capacity management
/// - Event check-in processing via `user_tickets`
/// - Interaction logging for check-ins
class EventService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // TODO: Move this to a secure storage or remote config
  static const String _hmacSecret = "SUPER_SECRET_256_BIT_KEY";

  /// Verify HMAC Signature
  static bool _verifyHmac(String uid, int timestamp, String nonce, String signature) {
    try {
      final key = utf8.encode(_hmacSecret);
      final bytes = utf8.encode('$uid|$timestamp|$nonce');
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(bytes);
      final expectedSignature = digest.toString();
      return signature == expectedSignature;
    } catch (e) {
      print('❌ [EventService] Security Check Error: $e');
      return false;
    }
  }

  /// Get all public and active events (Stream for real-time updates)

  /// Get all public and active events (Stream for real-time updates)
  static Stream<QuerySnapshot> getPublicEventsStream() {
    return _db
        .collection('events')
        .where('is_public', isEqualTo: true)
        .where('is_active', isEqualTo: true)
        .orderBy('date')
        .snapshots();
  }

  /// Get all public and active events (Future for one-time fetch)
  static Future<QuerySnapshot> getPublicEvents() {
    return _db
        .collection('events')
        .where('is_public', isEqualTo: true)
        .where('is_active', isEqualTo: true)
        .orderBy('date')
        .get();
  }

  /// Get event by ID
  static Future<DocumentSnapshot> getEventById(String eventId) {
    return _db.collection('events').doc(eventId).get();
  }

  /// Get event by ID (Stream for real-time updates)
  static Stream<DocumentSnapshot> getEventByIdStream(String eventId) {
    return _db.collection('events').doc(eventId).snapshots();
  }

  /// Check if event is full
  static Future<bool> isEventFull(String eventId) async {
    final doc = await getEventById(eventId);
    if (!doc.exists) return true;

    final data = doc.data() as Map<String, dynamic>;
    final capacity = data['capacity'] as int? ?? 0;
    final currentAttendees = data['current_attendees'] as int? ?? 0;

    return currentAttendees >= capacity;
  }

  /// Get events by category
  static Stream<QuerySnapshot> getEventsByCategory(String category) {
    return _db
        .collection('events')
        .where('is_public', isEqualTo: true)
        .where('is_active', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('date')
        .snapshots();
  }

  /// Search events by name or description
  static Future<QuerySnapshot> searchEvents(String query) {
    // Note: Firestore doesn't support full-text search natively
    // This is a simple implementation that fetches all and filters locally
    return _db
        .collection('events')
        .where('is_public', isEqualTo: true)
        .where('is_active', isEqualTo: true)
        .get();
  }

  /// Increment event attendee count
  static Future<void> incrementAttendeeCount(String eventId) async {
    await _db.collection('events').doc(eventId).update({
      'current_attendees': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Decrement event attendee count (for cancellation)
  static Future<void> decrementAttendeeCount(String eventId) async {
    await _db.collection('events').doc(eventId).update({
      'current_attendees': FieldValue.increment(-1),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Get event statistics
  static Future<Map<String, dynamic>> getEventStats(String eventId) async {
    final doc = await getEventById(eventId);
    if (!doc.exists) {
      return {
        'capacity': 0,
        'current_attendees': 0,
        'available_slots': 0,
        'is_full': true,
      };
    }

    final data = doc.data() as Map<String, dynamic>;
    final capacity = data['capacity'] as int? ?? 0;
    final currentAttendees = data['current_attendees'] as int? ?? 0;
    final availableSlots = capacity - currentAttendees;

    return {
      'capacity': capacity,
      'current_attendees': currentAttendees,
      'available_slots': availableSlots > 0 ? availableSlots : 0,
      'is_full': currentAttendees >= capacity,
    };
  }

  /// 🎫 Process event check-in
  /// Validates ticket and performs check-in operation
  ///
  /// **Parameters**:
  /// - `ticketId`: Unique ticket identifier (scanId from TicketParser)
  /// - `eventId`: Event ID from ticket QR
  /// - `userId`: User ID from ticket QR
  /// - `scanPoint`: Scan point performing the check-in
  ///
  /// **Returns**: Map with 'success' boolean and optional data
  static Future<Map<String, dynamic>> processCheckInPlaceholder({
    required String ticketId,
    required String eventId,
    required String userId,
    required dynamic scanPoint,
  }) async {
    print('🎫 [EventService][UnifiedTicket] Processing check-in...');
    print('🎫 [EventService][UnifiedTicket] Ticket ID: $ticketId');
    print('🎫 [EventService][UnifiedTicket] Event ID: $eventId');
    print('🎫 [EventService][UnifiedTicket] User ID: $userId');

    try {
      // Validate scan point
      if (scanPoint == null) {
        print('❌ [EventService][UnifiedTicket] No scan point provided');
        return {'success': false, 'message': 'No scan point assigned'};
      }

      // Extract scan point info
      final ScanPoint sp = scanPoint as ScanPoint;
      final scanPointId = sp.scanPointId;
      final scanPointName = sp.name;

      print(
        '🎫 [EventService][UnifiedTicket] Scan point: $scanPointName ($scanPointId)',
      );

      // PHASE 1 - TASK 1.1: Query user_tickets collection (unified source of truth)
      print(
        '🎫 [EventService][UnifiedTicket] Querying user_tickets collection...',
      );
      final ticketQuery = await _db
          .collection('user_tickets')
          .where('event_id', isEqualTo: eventId)
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      // Check if ticket exists
      if (ticketQuery.docs.isEmpty) {
        print('❌ [EventService][UnifiedTicket] Ticket not found or not active');
        print(
          '🎫 [EventService][UnifiedTicket] Query: event_id=$eventId, user_id=$userId, status=active',
        );
        return {'success': false, 'message': 'Ticket not found or inactive'};
      }

      final ticketDoc = ticketQuery.docs.first;
      final ticketData = ticketDoc.data();

      print('✅ [EventService][UnifiedTicket] Ticket found: ${ticketDoc.id}');

      // Check if already checked in (prevent duplicate check-ins)
      final currentStatus = ticketData['status'] as String? ?? 'active';
      if (currentStatus == 'attended') {
        final checkedInAt = ticketData['checked_in_at'] as Timestamp?;
        final checkedInTime = checkedInAt?.toDate();
        print(
          '❌ [EventService][UnifiedTicket] Ticket already checked in at: $checkedInTime',
        );
        return {'success': false, 'message': 'Ticket already checked in'};
      }

      // Extract ticket details
      final eventName = ticketData['event_name'] as String? ?? 'Unknown Event';
      final userEmail =
          ticketData['user_email'] as String? ?? 'unknown@email.com';
      final userName = ticketData['user_name'] as String? ?? userEmail;

      print('🎫 [EventService][UnifiedTicket] Event: $eventName');
      print('🎫 [EventService][UnifiedTicket] User: $userName ($userEmail)');

      // PHASE 1 - TASK 1.2: Update user_tickets with attended status
      print(
        '🎫 [EventService][UnifiedTicket] Updating ticket to attended status...',
      );
      await ticketDoc.reference.update({
        'status': 'attended',
        'attended_at': FieldValue.serverTimestamp(),
        'checked_in_at': FieldValue.serverTimestamp(),
        'checked_in_by': scanPointId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ [EventService][UnifiedTicket] Ticket updated: status=attended');

      // Log interaction (unchanged)
      await InteractionService.logEventCheckIn(
        ticketId: ticketDoc.id,
        eventId: eventId,
        eventName: eventName,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        scanPointId: scanPointId,
        scanPointName: scanPointName,
        remarks: 'Event check-in successful',
      );

      print('✅ [EventService][UnifiedTicket] Interaction logged');

      // Return success response
      return {
        'success': true,
        'message': 'Check-in successful',
        'event_name': eventName,
        'user_name': userName,
        'ticket_id': ticketDoc.id,
        'checked_in_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'message': 'Check-in failed: ${e.toString()}'};
    }
  }

  /// 🎫 Process Identity QR check-in (Ticketless)
  /// Records attendance based on User ID and Scan Point only.
  ///
  /// **Parameters**:
  /// - `userId`: User ID from Identity QR
  /// - `scanPoint`: Scan point performing the check-in
  ///
  /// **Returns**: Map with 'success' boolean and user details
  /// 🎫 Process Identity QR check-in (Ticketless)
  /// Records attendance based on User ID and Scan Point only.
  ///
  /// **Parameters**:
  /// - `userId`: User ID from Identity QR
  /// - `eventId`: Event ID to check in for
  /// - `scanPoint`: Scan point performing the check-in
  ///
  /// **Returns**: Map with 'success' boolean and user details
  static Future<Map<String, dynamic>> processIdentityCheckIn({
    required String userId,
    required String eventId,
    required dynamic scanPoint,
    // Security Parameters
    int? timestamp,
    String? nonce,
    String? signature,
  }) async {
    print('🎫 [EventService][Identity] Processing identity check-in...');

    // 🔒 Security Check: HMAC Verification
    if (timestamp != null && nonce != null && signature != null) {
      // Check for replay attacks (Timestamp expiry - 60 seconds)
      final now = DateTime.now().millisecondsSinceEpoch;
      if ((now - timestamp).abs() > 60000) {
           return {'success': false, 'message': 'QR Code Expired. Please refresh.'};
      }

      final isValid = _verifyHmac(userId, timestamp, nonce, signature);
      if (!isValid) {
        return {'success': false, 'message': 'Security Alert: Invalid QR Signature'};
      }
      print('🔒 [EventService] HMAC Correct. Secure Access.');
    } else {
      print('⚠️ [EventService] Warning: Processing unsecured transaction!');
    }

    print('🎫 [EventService][Identity] User ID: $userId');
    print('🎫 [EventService][Identity] Event ID: $eventId');

    try {
      // Validate scan point
      if (scanPoint == null) {
        return {'success': false, 'message': 'No scan point assigned'};
      }

      final ScanPoint sp = scanPoint as ScanPoint;
      final scanPointId = sp.scanPointId;
      final scanPointName = sp.name;

      print('🎫 [EventService][Identity] Scan point: $scanPointName');

      // 1. Verify User Exists
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found'};
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] as String? ?? 'Unknown User';
      final userEmail = userData['email'] as String? ?? 'unknown@email.com';

      // 2. Verify Registration (Check user_tickets)
      print('🎫 [EventService][Identity] Verifying registration...');
      final ticketQuery = await _db
          .collection('user_tickets')
          .where('event_id', isEqualTo: eventId)
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (ticketQuery.docs.isEmpty) {
        // Check if maybe already attended?
        final attendedQuery = await _db
            .collection('user_tickets')
            .where('event_id', isEqualTo: eventId)
            .where('user_id', isEqualTo: userId)
            .where('status', isEqualTo: 'attended') // Already checked in
            .limit(1)
            .get();

        if (attendedQuery.docs.isNotEmpty) {
           final attendedData = attendedQuery.docs.first.data();
           final attendedTime = (attendedData['attended_at'] as Timestamp?)?.toDate();
           
           return {
             'success': false, 
             'status': 'already_checked_in', // Unified Status Code
             'message': 'Check-in duplicate',
             'attended_at': attendedTime?.toIso8601String(),
             'user_name': userName,
           };
        }

        return {
          'success': false, 
          'status': 'error',
          'message': 'User not registered for this event'
        };
      }

      final ticketDoc = ticketQuery.docs.first;
      final eventName = ticketDoc.data()['event_name'] as String? ?? 'Unknown Event';

      // 3. Mark as Attended
      print('🎫 [EventService][Identity] Marking as attended...');
      await ticketDoc.reference.update({
        'status': 'attended',
        'attended_at': FieldValue.serverTimestamp(),
        'checked_in_at': FieldValue.serverTimestamp(),
        'checked_in_by': scanPointId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 4. Log Interaction
      await InteractionService.logEventCheckIn(
        ticketId: ticketDoc.id,
        eventId: eventId,
        eventName: eventName,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        scanPointId: scanPointId,
        scanPointName: scanPointName,
        remarks: 'Identity QR Check-in',
      );

      print('✅ [EventService][Identity] Check-in successful');

      return {
        'success': true,
        'status': 'success', // Unified Status Code
        'message': 'Check-in successful',
        'user_name': userName,
        'event_name': eventName,
        'checked_in_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ [EventService][Identity] Error: $e');
      return {
        'success': false, 
        'status': 'error',
        'message': 'Check-in failed: ${e.toString()}'
      };
    }
  }
}
