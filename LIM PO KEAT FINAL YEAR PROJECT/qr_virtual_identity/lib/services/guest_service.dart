// lib/services/guest_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_service.dart';
import 'auth_service.dart';

/// 👤 Guest Service for Event Ticket System
/// Manages guest users, event registration, and ticket generation
class GuestService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create or update guest user profile
  static Future<void> createOrUpdateGuestUser({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final userDoc = _db.collection('guest_users').doc(uid);
    final exists = (await userDoc.get()).exists;

    if (exists) {
      // Update existing user
      await userDoc.update({
        'name': name,
        'email': email,
        'photo_url': photoUrl,
        'last_login': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new user
      await userDoc.set({
        'uid': uid,
        'name': name,
        'email': email,
        'photo_url': photoUrl,
        'role': 'guest',
        'joined_events': [],
        'points': 0,
        'tier': 'Bronze',
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get guest user profile
  static Future<DocumentSnapshot> getGuestUser(String uid) {
    return _db.collection('guest_users').doc(uid).get();
  }

  /// Check if user has already joined an event
  static Future<bool> hasJoinedEvent(String uid, String eventId) async {
    final ticketQuery = await _db
        .collection('guest_tickets')
        .where('user_id', isEqualTo: uid)
        .where('event_id', isEqualTo: eventId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    return ticketQuery.docs.isNotEmpty;
  }

  /// Join an event and create a ticket
  static Future<Map<String, dynamic>> joinEvent({
    required String eventId,
    required String uid,
  }) async {
    try {
      // Check if already joined
      if (await hasJoinedEvent(uid, eventId)) {
        return {
          'success': false,
          'error': 'You have already joined this event',
        };
      }

      // Check if event is full
      if (await EventService.isEventFull(eventId)) {
        return {
          'success': false,
          'error': 'Event is full. No more slots available.',
        };
      }

      // Get event and user data
      final eventDoc = await EventService.getEventById(eventId);
      final userDoc = await getGuestUser(uid);

      if (!eventDoc.exists) {
        return {'success': false, 'error': 'Event not found'};
      }

      if (!userDoc.exists) {
        return {'success': false, 'error': 'User profile not found'};
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final userData = userDoc.data() as Map<String, dynamic>;

      // Generate QR code data
      final qrCode = 'qrvi://event/$eventId?uid=$uid';

      // Create ticket
      final ticketRef = _db.collection('guest_tickets').doc();
      final ticketId = ticketRef.id;

      await ticketRef.set({
        'ticket_id': ticketId,
        'event_id': eventId,
        'event_name': eventData['name'],
        'user_id': uid,
        'user_name': userData['name'],
        'user_email': userData['email'],
        'qr_code': qrCode,
        'status': 'active',
        'verified': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update user's joined events
      await _db.collection('guest_users').doc(uid).update({
        'joined_events': FieldValue.arrayUnion([eventId]),
      });

      // Update points and tier
      await updateGuestPoints(uid);

      // Increment event attendee count
      await EventService.incrementAttendeeCount(eventId);

      // Create log entry
      await _db.collection('logs').add({
        'action': 'guest_join_event',
        'detail':
            'Guest user ${userData['email']} joined event $eventId (${eventData['name']})',
        'timestamp': FieldValue.serverTimestamp(),
        'by': 'system',
      });

      return {'success': true, 'ticket_id': ticketId, 'qr_code': qrCode};
    } catch (e) {
      print('❌ Error joining event: $e');
      return {'success': false, 'error': 'Failed to join event: $e'};
    }
  }

  /// Cancel event registration
  static Future<Map<String, dynamic>> cancelRegistration({
    required String ticketId,
  }) async {
    try {
      final ticketDoc = await _db
          .collection('guest_tickets')
          .doc(ticketId)
          .get();

      if (!ticketDoc.exists) {
        return {'success': false, 'error': 'Ticket not found'};
      }

      final ticketData = ticketDoc.data() as Map<String, dynamic>;
      final eventId = ticketData['event_id'];
      final uid = ticketData['user_id'];

      // Update ticket status (soft cancel)
      await _db.collection('guest_tickets').doc(ticketId).update({
        'status': 'inactive',
        'cancelled': true,
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Remove from user's joined events
      await _db.collection('guest_users').doc(uid).update({
        'joined_events': FieldValue.arrayRemove([eventId]),
      });

      // Update points and tier after cancellation
      await updateGuestPoints(uid);

      // Decrement event attendee count
      await EventService.decrementAttendeeCount(eventId);

      // Create log entry
      await _db.collection('logs').add({
        'action': 'guest_cancel_event',
        'detail':
            'Guest user ${ticketData['user_email']} cancelled registration for event $eventId',
        'timestamp': FieldValue.serverTimestamp(),
        'by': 'system',
      });

      return {
        'success': true,
        'message': 'Registration cancelled successfully',
      };
    } catch (e) {
      print('❌ Error cancelling registration: $e');
      return {'success': false, 'error': 'Failed to cancel registration: $e'};
    }
  }

  /// Get user's tickets (Stream for real-time updates)
  static Stream<QuerySnapshot> getUserTicketsStream(String uid) {
    return _db
        .collection('guest_tickets')
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /// Get user's tickets (Future for one-time fetch)
  static Future<QuerySnapshot> getUserTickets(String uid) {
    return _db
        .collection('guest_tickets')
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .get();
  }

  /// Get ticket by ID
  static Future<DocumentSnapshot> getTicketById(String ticketId) {
    return _db.collection('guest_tickets').doc(ticketId).get();
  }

  /// Get ticket by ID (Stream)
  static Stream<DocumentSnapshot> getTicketByIdStream(String ticketId) {
    return _db.collection('guest_tickets').doc(ticketId).snapshots();
  }

  /// Verify ticket (for scanner)
  static Future<Map<String, dynamic>> verifyTicket(String ticketId) async {
    try {
      final ticketDoc = await _db
          .collection('guest_tickets')
          .doc(ticketId)
          .get();

      if (!ticketDoc.exists) {
        return {'success': false, 'error': 'Ticket not found'};
      }

      final ticketData = ticketDoc.data() as Map<String, dynamic>;

      if (ticketData['status'] != 'active') {
        return {'success': false, 'error': 'Ticket is not active'};
      }

      if (ticketData['verified'] == true) {
        return {'success': false, 'error': 'Ticket already verified'};
      }

      // Mark as verified
      await _db.collection('guest_tickets').doc(ticketId).update({
        'verified': true,
        'verified_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'ticket': ticketData};
    } catch (e) {
      print('❌ Error verifying ticket: $e');
      return {'success': false, 'error': 'Failed to verify ticket: $e'};
    }
  }

  /// Get current authenticated guest user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out guest user (from both Firebase and Google)
  static Future<void> signOut() async {
    await AuthService.signOut();
  }

  /// Update guest user points based on joined events
  /// Awards 10 points per event and calculates tier
  static Future<void> updateGuestPoints(String uid) async {
    try {
      final userRef = _db.collection('guest_users').doc(uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final joinedEvents = (userData['joined_events'] ?? []) as List;
      final eventCount = joinedEvents.length;

      // Calculate points (10 per event)
      final newPoints = eventCount * 10;

      // Determine tier
      String tier = 'Bronze';
      if (newPoints >= 70) {
        tier = 'Gold'; // 7+ events
      } else if (newPoints >= 40) {
        tier = 'Silver'; // 4-6 events
      }

      // Update Firestore
      await userRef.update({
        'points': newPoints,
        'tier': tier,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Updated points for $uid: $newPoints pts ($tier tier)');
    } catch (e) {
      print('❌ Error updating guest points: $e');
    }
  }

  /// Get guest achievements based on points
  static Future<Map<String, dynamic>> getGuestAchievements(String uid) async {
    try {
      final userDoc = await getGuestUser(uid);

      if (!userDoc.exists) {
        return {
          'points': 0,
          'tier': 'Bronze',
          'events_count': 0,
          'next_tier': 'Silver',
          'points_to_next': 40,
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final points = (userData['points'] ?? 0) as int;
      final tier = userData['tier'] ?? 'Bronze';
      final joinedEvents = (userData['joined_events'] ?? []) as List;
      final eventsCount = joinedEvents.length;

      // Calculate next tier info
      String nextTier = 'Silver';
      int pointsToNext = 40;

      if (tier == 'Bronze') {
        nextTier = 'Silver';
        pointsToNext = 40 - points;
      } else if (tier == 'Silver') {
        nextTier = 'Gold';
        pointsToNext = 70 - points;
      } else {
        nextTier = 'Max';
        pointsToNext = 0;
      }

      return {
        'points': points,
        'tier': tier,
        'events_count': eventsCount,
        'next_tier': nextTier,
        'points_to_next': pointsToNext > 0 ? pointsToNext : 0,
        'progress': tier == 'Gold'
            ? 1.0
            : (points / (tier == 'Bronze' ? 40 : 70)),
      };
    } catch (e) {
      print('❌ Error getting guest achievements: $e');
      return {
        'points': 0,
        'tier': 'Bronze',
        'events_count': 0,
        'next_tier': 'Silver',
        'points_to_next': 40,
      };
    }
  }

  /// Get recent joined events for a user (for profile display)
  static Future<List<Map<String, dynamic>>> getRecentJoinedEvents(
    String uid, {
    int limit = 2,
  }) async {
    try {
      final userDoc = await getGuestUser(uid);

      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;
      final joinedEventIds = (userData['joined_events'] ?? []) as List;

      if (joinedEventIds.isEmpty) return [];

      // Get event details for the most recent ones
      final recentEvents = <Map<String, dynamic>>[];
      final eventIdsToFetch = joinedEventIds.take(limit).toList();

      for (final eventId in eventIdsToFetch) {
        final eventDoc = await EventService.getEventById(eventId);
        if (eventDoc.exists) {
          recentEvents.add({
            ...eventDoc.data() as Map<String, dynamic>,
            'event_id': eventId,
          });
        }
      }

      return recentEvents;
    } catch (e) {
      print('❌ Error getting recent events: $e');
      return [];
    }
  }
}
