// lib/services/interaction_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 📊 Interaction Service
/// Manages all interaction logging for library operations
class InteractionService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String interactionsCollection = "interactions";

  /// Log a library borrow interaction
  static Future<void> logBorrow({
    required String bookId,
    required String bookTitle,
    required String userId,
    required String userEmail,
    required String scanPointId,
    required String scanPointName,
    String? remarks,
  }) async {
    try {
      final interactionId = _db.collection(interactionsCollection).doc().id;

      await _db.collection(interactionsCollection).doc(interactionId).set({
        'interaction_id': interactionId,
        'type': 'borrow',
        'status': 'success',
        'book_id': bookId,
        'book_title': bookTitle,
        'user_id': userId,
        'user_email': userEmail,
        'scan_point_id': scanPointId,
        'scan_point_name': scanPointName,
        'remarks': remarks ?? 'Book borrowed successfully',
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      print('✅ [InteractionService] Logged borrow interaction: $interactionId');
    } catch (e) {
      print('❌ [InteractionService] Error logging borrow interaction: $e');
    }
  }

  /// Log a library return interaction
  static Future<void> logReturn({
    required String bookId,
    required String bookTitle,
    required String scanPointId,
    required String scanPointName,
    String? userId,
    String? userEmail,
    String? remarks,
  }) async {
    try {
      final interactionId = _db.collection(interactionsCollection).doc().id;

      await _db.collection(interactionsCollection).doc(interactionId).set({
        'interaction_id': interactionId,
        'type': 'return',
        'status': 'success',
        'book_id': bookId,
        'book_title': bookTitle,
        'scan_point_id': scanPointId,
        'scan_point_name': scanPointName,
        'remarks': remarks ?? 'Book returned successfully',
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        // Optional user fields (may not be required for returns)
        if (userId != null) 'user_id': userId,
        if (userEmail != null) 'user_email': userEmail,
      });

      print('✅ [InteractionService] Logged return interaction: $interactionId');
    } catch (e) {
      print('❌ [InteractionService] Error logging return interaction: $e');
    }
  }

  /// Log a library error interaction
  static Future<void> logError({
    required String type,
    required String errorMessage,
    required String scanPointId,
    required String scanPointName,
    String? bookId,
    String? userId,
    String? userEmail,
  }) async {
    try {
      final interactionId = _db.collection(interactionsCollection).doc().id;

      await _db.collection(interactionsCollection).doc(interactionId).set({
        'interaction_id': interactionId,
        'type': type,
        'status': 'error',
        'scan_point_id': scanPointId,
        'scan_point_name': scanPointName,
        'remarks': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        if (bookId != null) 'book_id': bookId,
        if (userId != null) 'user_id': userId,
        if (userEmail != null) 'user_email': userEmail,
      });

      print('✅ [InteractionService] Logged error interaction: $interactionId');
    } catch (e) {
      print('❌ [InteractionService] Error logging error interaction: $e');
    }
  }

  /// Log an event check-in interaction
  static Future<void> logEventCheckIn({
    required String ticketId,
    required String eventId,
    required String eventName,
    required String userId,
    required String userEmail,
    required String scanPointId,
    required String scanPointName,
    String? userName,
    String? remarks,
  }) async {
    try {
      final interactionId = _db.collection(interactionsCollection).doc().id;

      await _db.collection(interactionsCollection).doc(interactionId).set({
        'interaction_id': interactionId,
        'type': 'event_checkin',
        'status': 'success',
        'ticket_id': ticketId,
        'event_id': eventId,
        'event_name': eventName,
        'user_id': userId,
        'user_email': userEmail,
        'user_name': userName,
        'scan_point_id': scanPointId,
        'scan_point_name': scanPointName,
        'remarks': remarks ?? 'Event check-in successful',
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      print(
        '✅ [InteractionService] Logged event check-in interaction: $interactionId',
      );
    } catch (e) {
      print(
        '❌ [InteractionService] Error logging event check-in interaction: $e',
      );
    }
  }
}
