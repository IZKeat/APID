// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 👤 User Service for Smart Campus Identity Hub
/// Provides analytics, timeline, and achievement data for students/lecturers
class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user UID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user email
  static String? get currentUserEmail => _auth.currentUser?.email;

  /// Get user profile data
  static Future<DocumentSnapshot> getUserProfile(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  /// Get Smart Summary metrics for dashboard
  static Future<Map<String, dynamic>> getSmartSummary(String uid) async {
    try {
      // Get user email
      final userDoc = await getUserProfile(uid);
      final userEmail = userDoc.data() != null
          ? (userDoc.data() as Map<String, dynamic>)['email']
          : null;

      if (userEmail == null) {
        return _getEmptySummary();
      }

      // Get all interactions for this user
      final interactionsSnap = await _db
          .collection('interactions')
          .where('user_email', isEqualTo: userEmail)
          .where('status', isEqualTo: 'success')
          .get();

      final interactions = interactionsSnap.docs;

      // Calculate metrics
      double totalSpent = 0.0;
      int booksBorrowed = 0;
      int gateAccesses = 0;
      int totalInteractions = interactions.length;

      for (final doc in interactions) {
        final type = doc['type'] as String?;
        final amount = doc['amount'] as num?;

        switch (type) {
          case 'purchase':
            totalSpent += (amount ?? 0).toDouble();
            break;
          case 'refund':
            totalSpent -= (amount ?? 0).abs().toDouble();
            break;
          case 'borrow':
            booksBorrowed++;
            break;
          case 'entry':
          case 'exit':
            gateAccesses++;
            break;
        }
      }

      return {
        'total_spent': totalSpent,
        'books_borrowed': booksBorrowed,
        'gate_accesses': gateAccesses,
        'total_interactions': totalInteractions,
      };
    } catch (e) {
      print('Error getting smart summary: $e');
      return _getEmptySummary();
    }
  }

  static Map<String, dynamic> _getEmptySummary() {
    return {
      'total_spent': 0.0,
      'books_borrowed': 0,
      'gate_accesses': 0,
      'total_interactions': 0,
    };
  }

  /// Get Activity Timeline stream (real-time updates)
  static Stream<List<Map<String, dynamic>>> getTimeline(String uid) {
    return _db.collection('users').doc(uid).snapshots().asyncMap((
      userDoc,
    ) async {
      final userEmail = userDoc.data()?['email'];
      if (userEmail == null) return [];

      final interactionsSnap = await _db
          .collection('interactions')
          .where('user_email', isEqualTo: userEmail)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return interactionsSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'unknown',
          'scan_point_name': data['scan_point_name'] ?? 'Unknown',
          'remarks': data['remarks'] ?? '',
          'amount': data['amount'],
          'timestamp': data['timestamp'],
          'status': data['status'] ?? 'unknown',
          // Additional fields for specific types
          'book_title': data['book_title'],
          'class_name': data['class_name'],
          'resource_name': data['resource_name'],
        };
      }).toList();
    });
  }

  /// Get user achievements
  static Future<List<Map<String, dynamic>>> getAchievements(String uid) async {
    try {
      final userDoc = await getUserProfile(uid);
      final userEmail = userDoc.data() != null
          ? (userDoc.data() as Map<String, dynamic>)['email']
          : null;

      if (userEmail == null) {
        return _getDefaultAchievements(unlocked: false);
      }

      // Get interaction counts
      final summary = await getSmartSummary(uid);
      final totalInteractions = summary['total_interactions'] as int;
      final booksBorrowed = summary['books_borrowed'] as int;
      final gateAccesses = summary['gate_accesses'] as int;

      // Get joined events count
      final eventsSnap = await _db
          .collection('user_events')
          .doc(uid)
          .collection('joined_events')
          .get();
      final eventsJoined = eventsSnap.docs.length;

      // Define achievements with unlock conditions
      final achievements = [
        {
          'id': 'campus_explorer',
          'title': 'Campus Explorer',
          'description': 'Complete 10 interactions',
          'tier': 'Bronze',
          'icon': 'explore',
          'unlocked': totalInteractions >= 10,
          'progress': totalInteractions,
          'target': 10,
        },
        {
          'id': 'knowledge_seeker',
          'title': 'Knowledge Seeker',
          'description': 'Borrow 5 books from the library',
          'tier': 'Silver',
          'icon': 'book',
          'unlocked': booksBorrowed >= 5,
          'progress': booksBorrowed,
          'target': 5,
        },
        {
          'id': 'campus_citizen',
          'title': 'Campus Citizen',
          'description': 'Complete 20 total interactions',
          'tier': 'Gold',
          'icon': 'stars',
          'unlocked': totalInteractions >= 20,
          'progress': totalInteractions,
          'target': 20,
        },
        {
          'id': 'apu_pioneer',
          'title': 'APU Pioneer',
          'description': 'Join 3 campus activities',
          'tier': 'Purple',
          'icon': 'premium',
          'unlocked': eventsJoined >= 3,
          'progress': eventsJoined,
          'target': 3,
        },
        {
          'id': 'frequent_visitor',
          'title': 'Frequent Visitor',
          'description': 'Access campus gates 15 times',
          'tier': 'Bronze',
          'icon': 'door',
          'unlocked': gateAccesses >= 15,
          'progress': gateAccesses,
          'target': 15,
        },
        {
          'id': 'super_student',
          'title': 'Super Student',
          'description': 'Complete 50 interactions',
          'tier': 'Platinum',
          'icon': 'workspace_premium',
          'unlocked': totalInteractions >= 50,
          'progress': totalInteractions,
          'target': 50,
        },
      ];

      return achievements;
    } catch (e) {
      print('Error getting achievements: $e');
      return _getDefaultAchievements(unlocked: false);
    }
  }

  static List<Map<String, dynamic>> _getDefaultAchievements({
    required bool unlocked,
  }) {
    return [
      {
        'id': 'campus_explorer',
        'title': 'Campus Explorer',
        'description': 'Complete 10 interactions',
        'tier': 'Bronze',
        'unlocked': unlocked,
      },
      {
        'id': 'knowledge_seeker',
        'title': 'Knowledge Seeker',
        'description': 'Borrow 5 books from the library',
        'tier': 'Silver',
        'unlocked': unlocked,
      },
      {
        'id': 'campus_citizen',
        'title': 'Campus Citizen',
        'description': 'Complete 20 total interactions',
        'tier': 'Gold',
        'unlocked': unlocked,
      },
      {
        'id': 'apu_pioneer',
        'title': 'APU Pioneer',
        'description': 'Join 3 campus activities',
        'tier': 'Purple',
        'unlocked': unlocked,
      },
    ];
  }

  /// Get monthly spending data for charts
  static Future<Map<String, double>> getMonthlySpending(String uid) async {
    try {
      final userDoc = await getUserProfile(uid);
      final userEmail = userDoc.data() != null
          ? (userDoc.data() as Map<String, dynamic>)['email']
          : null;

      if (userEmail == null) return {};

      // Get last 6 months of purchase data
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

      final purchasesSnap = await _db
          .collection('interactions')
          .where('user_email', isEqualTo: userEmail)
          .where('type', whereIn: ['purchase', 'refund'])
          .where('status', isEqualTo: 'success')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(sixMonthsAgo))
          .get();

      // Group by month
      final monthlyData = <String, double>{};

      for (final doc in purchasesSnap.docs) {
        final timestamp = doc['timestamp'] as Timestamp?;
        final amount = (doc['amount'] ?? 0) as num;
        final type = doc['type'] as String;

        if (timestamp != null) {
          final date = timestamp.toDate();
          final monthKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';

          monthlyData[monthKey] =
              (monthlyData[monthKey] ?? 0.0) +
              (type == 'purchase'
                  ? amount.toDouble()
                  : -amount.abs().toDouble());
        }
      }

      return monthlyData;
    } catch (e) {
      print('Error getting monthly spending: $e');
      return {};
    }
  }

  /// Get scan points distribution for pie chart
  static Future<Map<String, int>> getScanPointsDistribution(String uid) async {
    try {
      final userDoc = await getUserProfile(uid);
      final userEmail = userDoc.data() != null
          ? (userDoc.data() as Map<String, dynamic>)['email']
          : null;

      if (userEmail == null) return {};

      final interactionsSnap = await _db
          .collection('interactions')
          .where('user_email', isEqualTo: userEmail)
          .where('status', isEqualTo: 'success')
          .get();

      final distribution = <String, int>{};

      for (final doc in interactionsSnap.docs) {
        final scanPointName = doc['scan_point_name'] as String? ?? 'Unknown';
        distribution[scanPointName] = (distribution[scanPointName] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      print('Error getting scan points distribution: $e');
      return {};
    }
  }

  /// Join an event (for Activities page)
  static Future<Map<String, dynamic>> joinEvent({
    required String eventId,
    required String uid,
  }) async {
    try {
      // Check if already joined
      final existingDoc = await _db
          .collection('user_events')
          .doc(uid)
          .collection('joined_events')
          .doc(eventId)
          .get();

      if (existingDoc.exists) {
        return {
          'success': false,
          'error': 'You have already joined this event',
        };
      }

      // Get event data
      final eventDoc = await _db.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        return {'success': false, 'error': 'Event not found'};
      }

      // Add to user's joined events
      await _db
          .collection('user_events')
          .doc(uid)
          .collection('joined_events')
          .doc(eventId)
          .set({
            'event_id': eventId,
            'joined_at': FieldValue.serverTimestamp(),
            'status': 'registered',
          });

      // Update event attendees count
      await _db.collection('events').doc(eventId).update({
        'current_attendees': FieldValue.increment(1),
      });

      return {'success': true};
    } catch (e) {
      print('Error joining event: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Leave an event
  static Future<Map<String, dynamic>> leaveEvent({
    required String eventId,
    required String uid,
  }) async {
    try {
      // Remove from user's joined events
      await _db
          .collection('user_events')
          .doc(uid)
          .collection('joined_events')
          .doc(eventId)
          .delete();

      // Update event attendees count
      await _db.collection('events').doc(eventId).update({
        'current_attendees': FieldValue.increment(-1),
      });

      return {'success': true};
    } catch (e) {
      print('Error leaving event: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check if user has joined an event
  static Future<bool> hasJoinedEvent(String uid, String eventId) async {
    final doc = await _db
        .collection('user_events')
        .doc(uid)
        .collection('joined_events')
        .doc(eventId)
        .get();

    return doc.exists;
  }

  /// Get joined events stream
  static Stream<List<String>> getJoinedEventsStream(String uid) {
    return _db
        .collection('user_events')
        .doc(uid)
        .collection('joined_events')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Update user permissions (Syncs with access_permissions array)
  static Future<void> updateUserPermissions(
    String uid,
    Map<String, bool> permissions,
  ) async {
    // Convert Map<String, bool> back to List<String> for access_permissions
    // Only include keys that are true and start with 'SP' (ScanPoints)
    // or keep legacy keys if needed, but primarily we want to sync SP IDs.
    
    // 1. Get current permissions to preserve any we don't know about? 
    // Actually, the dialog should be the source of truth for the ones it manages.
    // But to be safe, let's just map the ones we are toggling.
    
    final accessPermissionsList = <String>[];
    permissions.forEach((key, value) {
      if (value == true) {
        // If it's a known legacy key, we might need to map it to an SP ID if applicable,
        // but for now, the dialog will pass SP IDs directly for new features.
        // Legacy keys: 'access_library', 'access_main_gate', etc.
        
        if (key.startsWith('SP')) {
          accessPermissionsList.add(key);
        } else {
          // Map legacy keys to SP IDs for backward compatibility if needed
          // 'access_main_gate' -> 'SP003'
          // 'access_library' -> 'SP002'
          if (key == 'access_main_gate') accessPermissionsList.add('SP003');
          if (key == 'access_library') accessPermissionsList.add('SP002');
          if (key == 'lecture_hall_b') accessPermissionsList.add('SP006');
        }
      }
    });

    // Remove duplicates
    final uniquePermissions = accessPermissionsList.toSet().toList();

    await _db.collection('users').doc(uid).update({
      'access_permissions': uniquePermissions,
      // We can also update the legacy 'permissions' map for older UI parts if they exist,
      // but we should move towards using the array.
      'permissions': permissions, 
    });
  }

  /// Get user permissions with defaults based on role
  static Future<Map<String, bool>> getUserPermissions(String uid) async {
    final doc = await getUserProfile(uid);
    if (!doc.exists || doc.data() == null) return {};

    final data = doc.data() as Map<String, dynamic>;
    final role = data['role'] as String? ?? 'student';
    
    // 1. Read from new 'access_permissions' array (Source of Truth for Access)
    final accessPermissions = List<String>.from(data['access_permissions'] ?? []);
    
    // 2. Read legacy 'permissions' map (for UI backward compatibility)
    final storedPermissions =
        (data['permissions'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as bool),
        ) ??
        {};

    // Define defaults
    final defaults = <String, bool>{};
    if (role == 'student' || role == 'guest') {
      // Legacy defaults
      defaults['access_library'] = accessPermissions.contains('SP002'); // SP002 = Library
      defaults['access_main_gate'] = accessPermissions.contains('SP003'); // SP003 = Main Gate
      defaults['join_event'] = storedPermissions['join_event'] ?? true;
      defaults['make_transaction'] = storedPermissions['make_transaction'] ?? true;
      
      // New Access Points
      defaults['SP006'] = accessPermissions.contains('SP006'); // Lecture Hall B
    } else if (role == 'merchant') {
      defaults['can_scan'] = true;
      defaults['can_refund'] = false;
    }

    // Auto-map all SP permissions from the array to ensure dynamic visibility
    for (final perm in accessPermissions) {
      if (perm.startsWith('SP')) {
        defaults[perm] = true;
      }
    }

    // Merge: 
    // If 'access_permissions' has the ID, it overrides the legacy map for that specific access.
    // We return a map that the Dialog can consume.
    
    return {...storedPermissions, ...defaults};
  }
  /// Get aggregated user stats for Profile Page
  static Future<Map<String, dynamic>> getUserStats(String uid) async {
    try {
      print('DEBUG: getUserStats called for targetUid: $uid');
      
      // 1. Get Tickets Count (FIXED: Query user_tickets collection)
      final ticketsSnap = await _db
          .collection('user_tickets')
          .where('user_id', isEqualTo: uid)
          .get();
      
      final allTickets = ticketsSnap.docs;
      
      // Count Active Tickets (for display)
      final activeTicketsCount = allTickets.where((doc) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'active';
        return ['active', 'registered', 'booked'].contains(status);
      }).length;

      // Count Attended Events (for points)
      final attendedEventsCount = allTickets.where((doc) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        return status == 'attended' || status == 'completed';
      }).length;

      // 2. Get Smart Summary (Interactions)
      final summary = await getSmartSummary(uid);
      final totalSpent = (summary['total_spent'] as num? ?? 0).toDouble();
      final booksBorrowed = summary['books_borrowed'] as int? ?? 0;
      final gateAccesses = summary['gate_accesses'] as int? ?? 0;
      
      // 3. Get Guide Points
      final userDoc = await getUserProfile(uid);
      final guidePoints = (userDoc.data() as Map<String, dynamic>?)?['guide_points'] as int? ?? 0;

      // 4. Calculate Weighted Points 🧮
      // Formula:
      // - Purchase: 1 pt / RM1
      // - Borrow: 50 pts / Book
      // - Access: 5 pts / Entry
      // - Event: 100 pts / Attended
      // - Guide: Fixed
      
      final pointsFromSpending = totalSpent.floor(); // 1 pt per RM1
      final pointsFromBooks = booksBorrowed * 50;
      final pointsFromAccess = gateAccesses * 5;
      final pointsFromEvents = attendedEventsCount * 100;

      final totalPoints = pointsFromSpending + 
                          pointsFromBooks + 
                          pointsFromAccess + 
                          pointsFromEvents + 
                          guidePoints;

      // 5. Calculate Rank
      final rankInfo = _calculateRank(totalPoints);

      print('DEBUG: Stats Calculated');
      print(' - Tickets (Active): $activeTicketsCount');
      print(' - Points Breakdown:');
      print('   - Spending: $pointsFromSpending ($totalSpent)');
      print('   - Books: $pointsFromBooks ($booksBorrowed)');
      print('   - Access: $pointsFromAccess ($gateAccesses)');
      print('   - Events: $pointsFromEvents ($attendedEventsCount)');
      print('   - Guide: $guidePoints');
      print(' - Total Points: $totalPoints');
      print(' - Rank: ${rankInfo['current_rank']}');

      return {
        'tickets_count': activeTicketsCount,
        'points': totalPoints,
        'rank_title': rankInfo['current_rank'],
        'rank_color': rankInfo['color'],
        'next_rank_title': rankInfo['next_rank'],
        'next_rank_threshold': rankInfo['next_threshold'],
        'progress': rankInfo['progress'], // 0.0 to 1.0
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'tickets_count': 0,
        'points': 0,
        'rank_title': 'Novice',
        'rank_color': 0xFF9E9E9E, // Grey
        'next_rank_title': 'Bronze',
        'next_rank_threshold': 500,
        'progress': 0.0,
      };
    }
  }

  /// 🏆 Calculate Rank based on Points
  static Map<String, dynamic> _calculateRank(int points) {
    if (points >= 5000) {
      return {
        'current_rank': 'Diamond',
        'next_rank': 'Max Rank',
        'next_threshold': 5000,
        'color': 0xFF00BCD4, // Cyan
        'progress': 1.0,
      };
    } else if (points >= 2000) {
      return {
        'current_rank': 'Gold',
        'next_rank': 'Diamond',
        'next_threshold': 5000,
        'color': 0xFFFFD700, // Gold
        'progress': (points - 2000) / (5000 - 2000),
      };
    } else if (points >= 1000) {
      return {
        'current_rank': 'Silver',
        'next_rank': 'Gold',
        'next_threshold': 2000,
        'color': 0xFFC0C0C0, // Silver
        'progress': (points - 1000) / (2000 - 1000),
      };
    } else if (points >= 500) {
      return {
        'current_rank': 'Bronze',
        'next_rank': 'Silver',
        'next_threshold': 1000,
        'color': 0xFFCD7F32, // Bronze
        'progress': (points - 500) / (1000 - 500),
      };
    } else {
      return {
        'current_rank': 'Novice',
        'next_rank': 'Bronze',
        'next_threshold': 500,
        'color': 0xFF9E9E9E, // Grey
        'progress': points / 500,
      };
    }
  }

  /// Add points for completing guides
  static Future<void> addGuidePoints(String uid, int amount) async {
    try {
      await _db.collection('users').doc(uid).update({
        'guide_points': FieldValue.increment(amount),
      });
      print('💰 Added $amount guide points for user $uid');
    } catch (e) {
      print('Error adding guide points: $e');
      // Create field if it doesn't exist
      await _db.collection('users').doc(uid).set({
        'guide_points': amount,
      }, SetOptions(merge: true));
    }
  }
}
