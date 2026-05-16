// lib/services/user_event_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

/// 🎫 User Event Service for QR Virtual Identity System
/// Handles all Firestore operations for User Events and Tickets
class UserEventService {
  // Singleton pattern for consistent instance usage
  static final UserEventService _instance = UserEventService._internal();
  factory UserEventService() => _instance;
  UserEventService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _userTicketsCollection =>
      _firestore.collection('user_tickets');

  /// 🎯 1️⃣ Fetch All Events
  /// Retrieve all active events with optional category filtering
  Stream<List<EventModel>> getAllEvents({String? category}) {
      Query query = _eventsCollection
          .where('is_public', isEqualTo: true)
          .where('is_active', isEqualTo: true)
          .orderBy('date');

      // Apply category filter if provided
      if (category != null &&
          category.isNotEmpty &&
          category.toLowerCase() != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return EventModel.fromDoc(doc);
              } catch (e) {
                debugPrint('Error parsing event document ${doc.id}: $e');
                return null;
              }
            })
            .where((event) => event != null)
            .cast<EventModel>()
            .toList();
      });
  }

  /// 🎫 2️⃣ Fetch User's Joined Tickets
  /// Retrieve all events the user has joined (active tickets)
  Stream<List<UserEventTicket>> getUserTickets(String uid) {
      return _userTicketsCollection
          .where('user_id', isEqualTo: uid)
          .orderBy('joined_at', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  try {
                    return UserEventTicket.fromDoc(doc);
                  } catch (e) {
                    debugPrint(
                      'Error parsing user ticket document ${doc.id}: $e',
                    );
                    return null;
                  }
                })
                .where((ticket) => ticket != null)
                .cast<UserEventTicket>()
                .toList();
          });
  }

  /// 🎯 Enhanced getUserTickets with EventModel details
  /// Returns full event details for user's tickets
  Stream<List<EventModel>> getUserJoinedEvents(String uid) {
      return _userTicketsCollection
          .where('user_id', isEqualTo: uid)
          .orderBy('joined_at', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            List<EventModel> events = [];

            for (var ticketDoc in snapshot.docs) {
              try {
                final ticketData = ticketDoc.data() as Map<String, dynamic>;
                final eventId = ticketData['event_id'] as String;

                // Fetch full event details
                final eventDoc = await _eventsCollection.doc(eventId).get();
                if (eventDoc.exists) {
                  final event = EventModel.fromDoc(eventDoc);
                  // Add ticket status to event
                  final eventWithStatus = event.copyWith(
                    status: ticketData['status'],
                  );
                  events.add(eventWithStatus);
                }
              } catch (e) {
                debugPrint('Error processing user ticket ${ticketDoc.id}: $e');
              }
            }

            return events;
          });
  }

  /// 📅 3️⃣ Get Upcoming Events
  /// Returns a stream of active events sorted by date (nearest first)
  Stream<List<EventModel>> getUpcomingEvents() {
    final now = DateTime.now();
    // Format today as YYYY-MM-DD to match string date format in Firestore
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return _eventsCollection
        .where('is_active', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: todayStr)
        .orderBy('date', descending: false) // Nearest date first
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventModel.fromDoc(doc))
              .toList();
        });
  }

  /// ➕ 3️⃣ Join Event
  /// Register user for an event with atomic transaction
  Future<Map<String, dynamic>> joinEvent(String eventId, String uid) async {
    try {
      // Validate inputs
      if (eventId.isEmpty || uid.isEmpty) {
        return {'success': false, 'message': 'Invalid event ID or user ID'};
      }

      // Check if user already joined (Get existing tickets to delete if re-joining)
      final existingTicketsQuery = await _userTicketsCollection
          .where('user_id', isEqualTo: uid)
          .where('event_id', isEqualTo: eventId)
          .get();

      final existingTicketDocs = existingTicketsQuery.docs;
      final bool isRejoining = existingTicketDocs.isNotEmpty;

      // Get user details for ticket creation
      final userDoc = await _usersCollection.doc(uid).get();
      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found'};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userEmail = userData['email'] as String;

      // Perform atomic transaction
      return await _firestore.runTransaction<Map<String, dynamic>>((
        transaction,
      ) async {
        // Get current event data
        final eventRef = _eventsCollection.doc(eventId);
        final eventSnapshot = await transaction.get(eventRef);

        if (!eventSnapshot.exists) {
          return {'success': false, 'message': 'Event not found'};
        }

        final eventData = eventSnapshot.data() as Map<String, dynamic>;
        final capacity = (eventData['capacity'] ?? 0) as int;
        final currentAttendees = (eventData['current_attendees'] ?? 0) as int;

        // Check if event has expired
        try {
          final eventDateStr = eventData['date'] as String;
          final eventDate = DateTime.parse(eventDateStr);
          // Set to end of the day for fair comparison
          final endOfEventDay = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            23,
            59,
            59,
          );
          
          if (DateTime.now().isAfter(endOfEventDay)) {
             return {'success': false, 'message': 'This event is expired. Please try another event.'};
          }
        } catch (e) {
          debugPrint('Error parsing date for expiry check: $e');
        }

        // Check capacity (Only if NOT re-joining)
        if (!isRejoining && currentAttendees >= capacity) {
          return {'success': false, 'message': 'Event is full'};
        }

        // Check if event is still active and public
        if (!(eventData['is_active'] ?? false) ||
            !(eventData['is_public'] ?? false)) {
          return {'success': false, 'message': 'Event is no longer available'};
        }

        // 🗑️ Delete OLD tickets if re-joining
        if (isRejoining) {
          debugPrint('♻️ User re-joining event. Deleting ${existingTicketDocs.length} old tickets.');
          for (var doc in existingTicketDocs) {
            transaction.delete(doc.reference);
          }
        }

        // Create NEW ticket document
        final ticketRef = _userTicketsCollection.doc();
        final ticketData = {
          'ticket_id': ticketRef.id,
          'user_id': uid,
          'user_email': userEmail,
          'event_id': eventId,
          'event_name': eventData['name'],
          'event_date': eventData['date'],
          'event_location': eventData['location'],
          'category': eventData['category'],
          'status': 'active',
          'joined_at': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        };

        // Update event attendee count and add user to attendees array
        final updatedAttendees = List<String>.from(
          eventData['attendees'] ?? [],
        );
        
        // If re-joining, user might already be in list, but we ensure they are there.
        // Count only increments if they weren't in the list (or if we treat re-join as net zero change if they were there)
        // Robust logic: Check if uid is in list.
        
        bool wasInList = updatedAttendees.contains(uid);
        if (!wasInList) {
          updatedAttendees.add(uid);
        }

        transaction.set(ticketRef, ticketData);
        
        // Only increment count if they were NOT in the list previously
        // If they were in the list, we deleted their ticket and added a new one, so count stays same.
        // If they were NOT in list (maybe data inconsistency), we increment.
        if (!wasInList) {
           transaction.update(eventRef, {
            'current_attendees': FieldValue.increment(1),
            'attendees': updatedAttendees,
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
           // Just update timestamp if count doesn't change
           transaction.update(eventRef, {
            'updated_at': FieldValue.serverTimestamp(),
          });
        }

        return {
          'success': true,
          'message': isRejoining ? 'Ticket updated successfully!' : 'Successfully joined event!',
          'ticketId': ticketRef.id,
        };
      });
    } catch (e) {
      debugPrint('Error in joinEvent: $e');
      return {
        'success': false,
        'message': 'Failed to join event: ${e.toString()}',
      };
    }
  }

  /// ❌ 4️⃣ Cancel Event Registration
  /// Soft delete user's event registration
  Future<Map<String, dynamic>> cancelEvent(String eventId, String uid) async {
    try {
      // Validate inputs
      if (eventId.isEmpty || uid.isEmpty) {
        return {'success': false, 'message': 'Invalid event ID or user ID'};
      }

      // Find active ticket
      final ticketQuery = await _userTicketsCollection
          .where('user_id', isEqualTo: uid)
          .where('event_id', isEqualTo: eventId)
          .where('status', isEqualTo: 'active')
          .get();

      if (ticketQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No active ticket found for this event',
        };
      }

      final ticketDoc = ticketQuery.docs.first;

      // Perform atomic transaction
      return await _firestore.runTransaction<Map<String, dynamic>>((
        transaction,
      ) async {
        // Get current event data
        final eventRef = _eventsCollection.doc(eventId);
        final eventSnapshot = await transaction.get(eventRef);

        if (!eventSnapshot.exists) {
          return {'success': false, 'message': 'Event not found'};
        }

        final eventData = eventSnapshot.data() as Map<String, dynamic>;

        // Update ticket status to cancelled
        transaction.update(ticketDoc.reference, {
          'status': 'cancelled',
          'cancelled_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Update event: decrement attendees and remove from attendees array
        final updatedAttendees = List<String>.from(
          eventData['attendees'] ?? [],
        );
        updatedAttendees.remove(uid);

        transaction.update(eventRef, {
          'current_attendees': FieldValue.increment(-1),
          'attendees': updatedAttendees,
          'updated_at': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'message': 'Event registration cancelled successfully',
        };
      });
    } catch (e) {
      debugPrint('Error in cancelEvent: $e');
      return {
        'success': false,
        'message': 'Failed to cancel event: ${e.toString()}',
      };
    }
  }

  /// 🔍 5️⃣ Fetch Event Details
  /// Retrieve specific event details by eventId
  Future<EventModel?> getEventDetails(String eventId) async {
    try {
      if (eventId.isEmpty) {
        debugPrint('Error: Event ID is empty');
        return null;
      }

      final eventDoc = await _eventsCollection.doc(eventId).get();

      if (!eventDoc.exists) {
        debugPrint('Event not found: $eventId');
        return null;
      }

      return EventModel.fromDoc(eventDoc);
    } catch (e) {
      debugPrint('Error in getEventDetails: $e');
      return null;
    }
  }

  /// ✅ 6️⃣ Check If User Joined
  /// Check if user has an active ticket for the event
  Future<bool> hasUserJoined(String eventId, String uid) async {
    try {
      if (eventId.isEmpty || uid.isEmpty) {
        return false;
      }

      final ticketQuery = await _userTicketsCollection
          .where('user_id', isEqualTo: uid)
          .where('event_id', isEqualTo: eventId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      return ticketQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error in hasUserJoined: $e');
      return false;
    }
  }

  /// 📊 7️⃣ Get User Event Statistics
  /// Retrieve user's event participation statistics
  Future<Map<String, int>> getUserEventStats(String uid) async {
    try {
      if (uid.isEmpty) {
        return {
          'totalJoined': 0,
          'activeTickets': 0,
          'cancelledTickets': 0,
          'attendedEvents': 0,
        };
      }

      final ticketsSnapshot = await _userTicketsCollection
          .where('user_id', isEqualTo: uid)
          .get();

      int totalJoined = ticketsSnapshot.docs.length;
      int activeTickets = 0;
      int cancelledTickets = 0;
      int attendedEvents = 0;

      for (var doc in ticketsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String;

        switch (status) {
          case 'active':
            activeTickets++;
            break;
          case 'cancelled':
            cancelledTickets++;
            break;
          case 'attended':
            attendedEvents++;
            break;
        }
      }

      return {
        'totalJoined': totalJoined,
        'activeTickets': activeTickets,
        'cancelledTickets': cancelledTickets,
        'attendedEvents': attendedEvents,
      };
    } catch (e) {
      debugPrint('Error in getUserEventStats: $e');
      return {
        'totalJoined': 0,
        'activeTickets': 0,
        'cancelledTickets': 0,
        'attendedEvents': 0,
      };
    }
  }

  /// 🔄 8️⃣ Refresh User Tickets (Bonus)
  /// Synchronize user tickets and update achievements
  Future<void> refreshUserTickets(String uid) async {
    try {
      if (uid.isEmpty) return;

      debugPrint('Refreshing user tickets for: $uid');

      // Get user stats
      final stats = await getUserEventStats(uid);

      // Update user document with event participation stats
      await _usersCollection.doc(uid).update({
        'events_joined': stats['totalJoined'],
        'active_tickets': stats['activeTickets'],
        'events_attended': stats['attendedEvents'],
        'last_updated': FieldValue.serverTimestamp(),
      });

      debugPrint('User ticket stats updated successfully');
    } catch (e) {
      debugPrint('Error in refreshUserTickets: $e');
    }
  }

  /// 🎯 9️⃣ Search Events
  /// Search events by name, description, or tags
  Future<List<EventModel>> searchEvents(
    String query, {
    String? category,
  }) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // Note: Firestore doesn't support full-text search natively
      // This is a simplified search - for production, consider Algolia or ElasticSearch

      Query baseQuery = _eventsCollection
          .where('is_public', isEqualTo: true)
          .where('is_active', isEqualTo: true);

      if (category != null &&
          category.isNotEmpty &&
          category.toLowerCase() != 'all') {
        baseQuery = baseQuery.where('category', isEqualTo: category);
      }

      final snapshot = await baseQuery.get();

      final allEvents = snapshot.docs
          .map((doc) => EventModel.fromDoc(doc))
          .toList();

      // Client-side filtering
      final queryLower = query.toLowerCase();
      return allEvents.where((event) {
        return event.name.toLowerCase().contains(queryLower) ||
            event.description?.toLowerCase().contains(queryLower) == true ||
            event.organizer.toLowerCase().contains(queryLower) ||
            event.tags.any((tag) => tag.toLowerCase().contains(queryLower));
      }).toList();
    } catch (e) {
      debugPrint('Error in searchEvents: $e');
      return [];
    }
  }

  /// 🔟 Get Events by Category
  /// Helper method to get events filtered by category
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return getAllEvents(category: category);
  }

  /// 🏆 Mark Event as Attended
  /// Update ticket status when user attends the event
  Future<Map<String, dynamic>> markEventAttended(
    String eventId,
    String uid,
  ) async {
    try {
      final ticketQuery = await _userTicketsCollection
          .where('user_id', isEqualTo: uid)
          .where('event_id', isEqualTo: eventId)
          .where('status', isEqualTo: 'active')
          .get();

      if (ticketQuery.docs.isEmpty) {
        return {'success': false, 'message': 'No active ticket found'};
      }

      final ticketDoc = ticketQuery.docs.first;

      await ticketDoc.reference.update({
        'status': 'attended',
        'attended_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Refresh user stats
      await refreshUserTickets(uid);

      return {'success': true, 'message': 'Event marked as attended'};
    } catch (e) {
      debugPrint('Error in markEventAttended: $e');
      return {
        'success': false,
        'message': 'Failed to mark attendance: ${e.toString()}',
      };
    }
  }

  /// 🎫 Get Ticket Details
  /// Get specific ticket information
  Future<UserEventTicket?> getTicketDetails(String eventId, String uid) async {
    try {
      final ticketQuery = await _userTicketsCollection
          .where('user_id', isEqualTo: uid)
          .where('event_id', isEqualTo: eventId)
          .limit(1)
          .get();

      if (ticketQuery.docs.isEmpty) {
        return null;
      }

      return UserEventTicket.fromDoc(ticketQuery.docs.first);
    } catch (e) {
      debugPrint('Error in getTicketDetails: $e');
      return null;
    }
  }

  /// 🔧 Health Check
  /// Test Firestore connectivity and permissions
  Future<bool> healthCheck() async {
    try {
      // Try to read from events collection
      final testQuery = await _eventsCollection.limit(1).get();
      debugPrint(
        'UserEventService health check: OK (${testQuery.docs.length} docs accessible)',
      );
      return true;
    } catch (e) {
      debugPrint('UserEventService health check failed: $e');
      return false;
    }
  }

  /// 🧹 Cleanup Method
  /// Clean up expired or invalid data (call periodically)
  Future<void> cleanup() async {
    try {
      debugPrint('Starting UserEventService cleanup...');

      // Add cleanup logic here if needed
      // For example, remove expired tickets, sync data, etc.

      debugPrint('UserEventService cleanup completed');
    } catch (e) {
      debugPrint('Error in UserEventService cleanup: $e');
    }
  }

  /// 📱 Get Current User UID
  /// Helper method to get current authenticated user ID
  String? get currentUserUid => _auth.currentUser?.uid;

  /// ✉️ Get Current User Email
  /// Helper method to get current authenticated user email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// 🔐 Check Authentication
  /// Verify if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// 🛠️ Debug Tool: Migrate Event Dates
  /// Updates all events to March 2026, except one which is set to Jan 2023.
  Future<void> debugMigrateEventDates() async {
    try {
      debugPrint('🛠️ Starting Event Date Migration...');
      final snapshot = await _eventsCollection.get();
      
      final batch = _firestore.batch();
      int count = 0;
      bool setExpiredEvent = false;

      for (var doc in snapshot.docs) {
        final eventRef = _eventsCollection.doc(doc.id);
        
        String newDate;
        
        // Set the FIRST event found as the expired one
        if (!setExpiredEvent) {
          newDate = '2025-12-03'; // Expired (Yesterday)
          setExpiredEvent = true;
          debugPrint('  -> Setting ${doc.id} as EXPIRED (2025-12-03)');
        } else {
          // Set others to March 2026
          // Randomize day slightly to avoid all being on the same day
          final day = 10 + (count % 20); 
          newDate = '2026-03-$day';
        }

        batch.update(eventRef, {
          'date': newDate,
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
      }

      await batch.commit();
      debugPrint('✅ Migration Complete. Updated $count events.');
    } catch (e) {
      debugPrint('❌ Error in debugMigrateEventDates: $e');
    }
  }

  /// 🛠️ Debug Tool: Cleanup Integrity
  /// 1. Removes duplicate tickets (keeps latest).
  /// 2. Syncs ticket dates with actual Event dates.
  /// 3. Deletes tickets for missing events.
  Future<void> debugCleanupIntegrity() async {
    try {
      debugPrint('🛠️ Starting Integrity Cleanup...');
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Error: User not logged in.');
        return;
      }

      // FIX: Only fetch CURRENT USER'S tickets to avoid Permission Denied
      final ticketsSnapshot = await _userTicketsCollection
          .where('user_id', isEqualTo: user.uid)
          .get();
      
      final eventsSnapshot = await _eventsCollection.get();
      
      // Map of Event ID -> Event Data
      final eventMap = {
        for (var doc in eventsSnapshot.docs) 
          doc.id: doc.data() as Map<String, dynamic>
      };

      // Group tickets by UserID_EventID
      final Map<String, List<DocumentSnapshot>> ticketGroups = {};

      for (var doc in ticketsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final uid = data['user_id'] as String?;
        final eventId = data['event_id'] as String?;

        if (uid != null && eventId != null) {
          final key = '${uid}_$eventId';
          if (!ticketGroups.containsKey(key)) {
            ticketGroups[key] = [];
          }
          ticketGroups[key]!.add(doc);
        }
      }

      final batch = _firestore.batch();
      int deletedCount = 0;
      int updatedCount = 0;

      for (var entry in ticketGroups.entries) {
        final tickets = entry.value;
        
        // Sort by joined_at descending (Latest first)
        tickets.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['joined_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = (bData['joined_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });

        // Keep the first one (Latest)
        final latestTicket = tickets.first;
        
        // Delete duplicates
        for (var i = 1; i < tickets.length; i++) {
          batch.delete(tickets[i].reference);
          deletedCount++;
          debugPrint('  🗑️ Deleting duplicate ticket: ${tickets[i].id}');
        }

        // Validate & Sync Latest Ticket
        final latestData = latestTicket.data() as Map<String, dynamic>;
        final eventId = latestData['event_id'] as String;
        
        if (!eventMap.containsKey(eventId)) {
           // Event doesn't exist -> Delete ticket
           batch.delete(latestTicket.reference);
           deletedCount++;
           debugPrint('  🗑️ Deleting orphan ticket (Event missing): ${latestTicket.id}');
        } else {
           // Event exists -> Check Date
           final eventData = eventMap[eventId]!;
           final realDate = eventData['date'] as String;
           final ticketDate = latestData['event_date'] as String?;

           if (ticketDate != realDate) {
             batch.update(latestTicket.reference, {
               'event_date': realDate,
               'updated_at': FieldValue.serverTimestamp(),
             });
             updatedCount++;
             debugPrint('  🔄 Syncing ticket date: ${latestTicket.id} ($ticketDate -> $realDate)');
           }
        }
      }

      await batch.commit();
      debugPrint('✅ Integrity Cleanup Complete.');
      debugPrint('   - Deleted: $deletedCount');
      debugPrint('   - Updated: $updatedCount');
      
    } catch (e) {
      debugPrint('❌ Error in debugCleanupIntegrity: $e');
    }
  }
}
