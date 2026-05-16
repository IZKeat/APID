// lib/services/scanner_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/ticket_parser.dart';

/// 🎯 Scanner Service
/// Handles ticket verification, duplicate scan prevention, and merchant permissions
class ScannerService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verify ticket with comprehensive validation
  static Future<TicketVerificationResult> verifyTicket(String qrData) async {
    try {
      // 1. Parse QR data
      final ticket = TicketParser.fromQrData(qrData);
      if (ticket == null) {
        return TicketVerificationResult.error('Invalid QR code format');
      }

      // 2. Check ticket expiry (max 30 minutes old)
      if (ticket.isExpired) {
        return TicketVerificationResult.error(
          'Ticket expired ${ticket.ageInMinutes} minutes ago',
        );
      }

      // 3. Check merchant permission
      final merchantCheck = await _checkMerchantPermission(ticket.eventId);
      if (!merchantCheck.success) {
        return TicketVerificationResult.error(merchantCheck.message);
      }

      // 4. Use Firestore transaction for atomic operations
      return await _db.runTransaction<TicketVerificationResult>((
        transaction,
      ) async {
        // Check if ticket exists and is valid
        final ticketValidation = await _validateTicketInTransaction(
          transaction,
          ticket,
        );
        if (!ticketValidation.success) {
          return TicketVerificationResult.error(ticketValidation.message);
        }

        // Check for duplicate scan
        final duplicateCheck = await _checkDuplicateScan(transaction, ticket);
        if (!duplicateCheck.success) {
          return TicketVerificationResult.error(duplicateCheck.message);
        }

        // Update ticket status and add log entry
        await _processSuccessfulScan(
          transaction,
          ticket,
          ticketValidation.data,
        );

        return TicketVerificationResult.success(
          'Ticket verified successfully',
          data: ticketValidation.data,
        );
      });
    } catch (e) {
      return TicketVerificationResult.error(
        'Verification failed: ${e.toString()}',
      );
    }
  }

  /// Check merchant permission to scan tickets for this event
  static Future<_ValidationResult> _checkMerchantPermission(
    String eventId,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return _ValidationResult(false, 'Not authenticated');
      }

      // Check if user is merchant/admin
      final userDoc = await _db
          .collection('users')
          .doc(currentUser.email)
          .get();

      if (!userDoc.exists) {
        return _ValidationResult(false, 'User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userType = userData['type'] as String? ?? '';

      // Allow merchants and admins to scan tickets
      if (!['merchant', 'admin'].contains(userType)) {
        return _ValidationResult(false, 'Insufficient permissions');
      }

      // Optional: Check if merchant is associated with this specific event
      // For now, we allow all merchants to scan any event ticket

      return _ValidationResult(true, 'Permission granted');
    } catch (e) {
      return _ValidationResult(false, 'Permission check failed: $e');
    }
  }

  /// Validate ticket exists and is active
  static Future<_ValidationResult> _validateTicketInTransaction(
    Transaction transaction,
    TicketParser ticket,
  ) async {
    // Check in user_tickets collection first
    final userTicketQuery = await _db
        .collection('user_tickets')
        .where('event_id', isEqualTo: ticket.eventId)
        .where('user_id', isEqualTo: ticket.userId)
        .limit(1)
        .get();

    if (userTicketQuery.docs.isNotEmpty) {
      final ticketDoc = userTicketQuery.docs.first;
      final ticketData = ticketDoc.data();

      if (ticketData['status'] != 'active') {
        return _ValidationResult(false, 'Ticket is not active');
      }

      return _ValidationResult(
        true,
        'Valid user ticket',
        data: {
          'ticket_id': ticketDoc.id,
          'collection': 'user_tickets',
          ...ticketData,
        },
      );
    }

    // Check in guest_tickets collection
    final guestTicketQuery = await _db
        .collection('guest_tickets')
        .where('event_id', isEqualTo: ticket.eventId)
        .where('user_id', isEqualTo: ticket.userId)
        .limit(1)
        .get();

    if (guestTicketQuery.docs.isNotEmpty) {
      final ticketDoc = guestTicketQuery.docs.first;
      final ticketData = ticketDoc.data();

      if (ticketData['status'] != 'active') {
        return _ValidationResult(false, 'Ticket is not active');
      }

      if (ticketData['verified'] == true) {
        return _ValidationResult(false, 'Ticket already verified');
      }

      return _ValidationResult(
        true,
        'Valid guest ticket',
        data: {
          'ticket_id': ticketDoc.id,
          'collection': 'guest_tickets',
          ...ticketData,
        },
      );
    }

    return _ValidationResult(false, 'Ticket not found');
  }

  /// Check for duplicate scan prevention
  static Future<_ValidationResult> _checkDuplicateScan(
    Transaction transaction,
    TicketParser ticket,
  ) async {
    // Check if this exact ticket has been scanned recently (last 5 minutes)
    final recentScanQuery = await _db
        .collection('ticket_scans')
        .where('scan_id', isEqualTo: ticket.scanId)
        .where(
          'timestamp',
          isGreaterThan: DateTime.now().subtract(const Duration(minutes: 5)),
        )
        .limit(1)
        .get();

    if (recentScanQuery.docs.isNotEmpty) {
      final scanData = recentScanQuery.docs.first.data();
      final scanTime = (scanData['timestamp'] as Timestamp).toDate();
      final minutesAgo = DateTime.now().difference(scanTime).inMinutes;

      return _ValidationResult(
        false,
        'Ticket already scanned $minutesAgo minutes ago',
      );
    }

    return _ValidationResult(true, 'No recent duplicate scan found');
  }

  /// Process successful scan - update ticket and add logs
  static Future<void> _processSuccessfulScan(
    Transaction transaction,
    TicketParser ticket,
    Map<String, dynamic>? ticketData,
  ) async {
    if (ticketData == null) return;

    final currentUser = _auth.currentUser!;
    final now = Timestamp.now();
    final collection = ticketData['collection'] as String;
    final ticketId = ticketData['ticket_id'] as String;

    // Update ticket status
    if (collection == 'guest_tickets') {
      transaction.update(_db.collection('guest_tickets').doc(ticketId), {
        'verified': true,
        'verified_at': now,
        'verified_by': currentUser.email,
        'updated_at': now,
      });
    } else if (collection == 'user_tickets') {
      transaction.update(_db.collection('user_tickets').doc(ticketId), {
        'verified': true,
        'verified_at': now,
        'verified_by': currentUser.email,
        'updated_at': now,
      });
    }

    // Add scan log entry
    transaction.set(_db.collection('ticket_scans').doc(), {
      'scan_id': ticket.scanId,
      'ticket_id': ticketId,
      'event_id': ticket.eventId,
      'user_id': ticket.userId,
      'scanned_by': currentUser.email,
      'scanner_id': currentUser.uid,
      'timestamp': now,
      'ticket_timestamp': Timestamp.fromDate(ticket.timestamp),
      'collection_source': collection,
      'status': 'success',
      'event_name': ticketData['event_name'] ?? 'Unknown Event',
      'user_email': ticketData['user_email'] ?? '',
      'created_at': now,
    });

    // Update event attendance count
    transaction.update(_db.collection('events').doc(ticket.eventId), {
      'scanned_count': FieldValue.increment(1),
      'updated_at': now,
    });
  }
}

/// Result of ticket verification operation
class TicketVerificationResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const TicketVerificationResult._({
    required this.success,
    required this.message,
    this.data,
  });

  factory TicketVerificationResult.success(
    String message, {
    Map<String, dynamic>? data,
  }) {
    return TicketVerificationResult._(
      success: true,
      message: message,
      data: data,
    );
  }

  factory TicketVerificationResult.error(String message) {
    return TicketVerificationResult._(
      success: false,
      message: message,
      data: null,
    );
  }
}

/// Internal validation result helper
class _ValidationResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const _ValidationResult(this.success, this.message, {this.data});
}
