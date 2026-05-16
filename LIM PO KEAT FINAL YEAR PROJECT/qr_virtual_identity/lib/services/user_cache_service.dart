import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 🧠 User Cache Service
/// Efficiently manages UID -> Email mappings to reduce Firestore reads.
/// Uses a singleton pattern with in-memory caching.
class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // 💾 In-memory cache: {uid: email}
  final Map<String, String> _emailCache = {};
  
  // ⏳ Pending requests to prevent duplicate fetches
  final Map<String, Future<String>> _pendingRequests = {};

  /// Get email synchronously from cache (returns null if not cached)
  String? getEmailSync(String uid) => _emailCache[uid];

  /// Get email for a UID, using cache if available.
  /// Returns 'Unknown User' if not found or error.
  Future<String> getEmail(String uid) async {
    if (uid.isEmpty) return 'Unknown';
    
    // 1. Check Cache
    if (_emailCache.containsKey(uid)) {
      return _emailCache[uid]!;
    }

    // 2. Check Pending Requests (Deduplication)
    if (_pendingRequests.containsKey(uid)) {
      return await _pendingRequests[uid]!;
    }

    // 3. Fetch from Firestore
    final future = _fetchEmail(uid);
    _pendingRequests[uid] = future;

    try {
      final email = await future;
      _pendingRequests.remove(uid);
      return email;
    } catch (e) {
      _pendingRequests.remove(uid);
      return 'Error loading email';
    }
  }

  Future<String> _fetchEmail(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final email = doc.data()!['email'] as String? ?? 'No Email';
        _emailCache[uid] = email;
        return email;
      } else {
        _emailCache[uid] = 'User Not Found';
        return 'User Not Found';
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching email for $uid: $e');
      return 'Error';
    }
  }

  /// Batch prefetch emails for a list of UIDs
  Future<void> prefetch(List<String> uids) async {
    final uncached = uids.where((uid) => !_emailCache.containsKey(uid) && !_pendingRequests.containsKey(uid)).toSet();
    
    if (uncached.isEmpty) return;

    // Firestore 'in' query is limited to 10 items.
    // We'll fetch individually for simplicity as batching 'in' queries is complex logic
    // and this is an FYP. The deduplication logic above handles the heavy lifting.
    for (final uid in uncached) {
      getEmail(uid); // Fire and forget
    }
  }

  /// Clear cache (useful on logout)
  void clear() {
    _emailCache.clear();
    _pendingRequests.clear();
  }
}
