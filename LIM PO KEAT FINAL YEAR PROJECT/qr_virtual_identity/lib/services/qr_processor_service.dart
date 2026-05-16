import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/qr_parser.dart';
import '../services/scan_point_service.dart';
import '../services/scanner_service.dart';
import '../services/commerce_service.dart';
import '../services/library_service.dart';
import '../services/access_service.dart';

/// 🎯 QR Process Response
/// Standardized response for all QR processing operations
class QrProcessResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? errorCode;

  const QrProcessResponse._({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
  });

  /// Create successful response
  factory QrProcessResponse.success(
    String message, [
    Map<String, dynamic>? data,
  ]) {
    return QrProcessResponse._(success: true, message: message, data: data);
  }

  /// Create error response
  factory QrProcessResponse.error(String message, [String? errorCode]) {
    return QrProcessResponse._(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    return 'QrProcessResponse(success: $success, message: $message, data: $data, errorCode: $errorCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QrProcessResponse &&
        other.success == success &&
        other.message == message &&
        other.errorCode == errorCode;
  }

  @override
  int get hashCode => Object.hash(success, message, errorCode);
}

/// 🎯 Central QR Processor Service
/// Routes QR codes to appropriate business logic services based on QR type and scan point context
class QrProcessorService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Process any QR code with scan point context
  ///
  /// This is the central routing method that determines which service should handle
  /// the QR code based on its type and the current scan point configuration
  static Future<QrProcessResponse> process(
    QrParseResult qr,
    ScanPoint scanPoint, {
    String mode = 'borrow',
    Map<String, dynamic>? extraData,
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        return QrProcessResponse.error(
          'User not authenticated',
          'AUTH_REQUIRED',
        );
      }

      final userId = user.uid;

      print(
        '🎯 [QrProcessor] Processing ${qr.type} QR for ${scanPoint.type} scan point',
      );
      print('🎯 [QrProcessor] User: $userId, Scan Point: ${scanPoint.name}');

      // Validate scan point is active
      if (!scanPoint.active) {
        return QrProcessResponse.error(
          'This scan point is currently inactive',
          'SCAN_POINT_INACTIVE',
        );
      }

      // Route to appropriate service based on QR type
      switch (qr.type) {
        case QrType.ticket:
          return await _processTicketQr(qr, scanPoint, userId);

        case QrType.user:
          return await _processUserQr(qr, scanPoint, userId, extraData: extraData);

        case QrType.item:
          return await _processItemQr(qr, scanPoint, userId, mode: mode);

        case QrType.scanPoint:
          return await _processScanPointQr(qr, scanPoint, userId);

        default:
          return QrProcessResponse.error(
            'Unsupported QR code type: ${qr.type}',
            'UNSUPPORTED_QR_TYPE',
          );
      }
    } catch (e) {
      print('❌ [QrProcessor] Unexpected error processing QR: $e');
      return QrProcessResponse.error(
        'Failed to process QR code: ${e.toString()}',
        'PROCESSING_ERROR',
      );
    }
  }

  /// Process TICKET QR codes (event check-in)
  static Future<QrProcessResponse> _processTicketQr(
    QrParseResult qr,
    ScanPoint scanPoint,
    String userId,
  ) async {
    try {
      print(
        '🎫 [QrProcessor] Processing ticket QR for event: ${qr.ticket?.eventId}',
      );

      // Validate ticket data
      if (qr.ticket == null) {
        return QrProcessResponse.error('Invalid ticket data', 'INVALID_TICKET');
      }

      // Use existing scanner service for ticket verification
      final result = await ScannerService.verifyTicket(qr.raw);

      if (result.success) {
        return QrProcessResponse.success('Ticket verified successfully', {
          'event_id': qr.ticket!.eventId,
          'ticket_user_id': qr.ticket!.userId,
          'scan_point': scanPoint.name,
          'verification_type': 'ticket_checkin',
        });
      } else {
        return QrProcessResponse.error(
          result.message,
          'TICKET_VERIFICATION_FAILED',
        );
      }
    } catch (e) {
      print('❌ [QrProcessor] Error processing ticket QR: $e');
      return QrProcessResponse.error(
        'Ticket processing failed: ${e.toString()}',
        'TICKET_ERROR',
      );
    }
  }

  /// Process USER QR codes (commerce payments, identification)
  static Future<QrProcessResponse> _processUserQr(
    QrParseResult qr,
    ScanPoint scanPoint,
    String userId, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      print('👤 [QrProcessor] Processing user QR: ${qr.userId}');

      // Route based on scan point type
      switch (scanPoint.type) {
        case 'commerce':
          return await CommerceService.processPayment(
            userId: qr.userId!,
            scanPoint: scanPoint,
            amount: extraData?['amount'],
            items: extraData?['items'],
          );

        case 'access':
          return await AccessService.processEntry(
            userId: qr.userId!,
            scanPoint: scanPoint,
          );

        case 'library':
          return await LibraryService.processUser(
            userId: qr.userId!,
            scanPoint: scanPoint,
            processedByUserId: userId,
          );

        default:
          return QrProcessResponse.error(
            'User QR codes are not supported for ${scanPoint.type} scan points',
            'INCOMPATIBLE_SCAN_POINT',
          );
      }
    } on TimeoutException catch (e) {
      print('❌ [QrProcessor] Timeout error processing user QR: $e');
      return QrProcessResponse.error(
        'Request Timed Out. Please try again.',
        'TIMEOUT_ERROR',
      );
    } on SocketException catch (e) {
      print('❌ [QrProcessor] Network error processing user QR: $e');
      return QrProcessResponse.error(
        'Network Unavailable. Please check your Wifi/Data.',
        'NETWORK_ERROR',
      );
    } catch (e) {
      print('❌ [QrProcessor] Error processing user QR: $e');
      return QrProcessResponse.error(
        'User QR processing failed: ${e.toString()}',
        'USER_QR_ERROR',
      );
    }
  }

  /// Process ITEM QR codes (library books, resources)
  static Future<QrProcessResponse> _processItemQr(
    QrParseResult qr,
    ScanPoint scanPoint,
    String userId, {
    String mode = 'borrow',
  }) async {
    try {
      print('📦 [QrProcessor] Processing item QR: ${qr.itemId}');

      // Route based on scan point type
      switch (scanPoint.type) {
        case 'library':
          return await LibraryService.processItem(
            itemId: qr.itemId!,
            scanPoint: scanPoint,
            processedByUserId: userId,
            mode: mode,
          );

        default:
          return QrProcessResponse.error(
            'Item QR codes are not supported for ${scanPoint.type} scan points',
            'INCOMPATIBLE_SCAN_POINT',
          );
      }
    } catch (e) {
      print('❌ [QrProcessor] Error processing item QR: $e');
      return QrProcessResponse.error(
        'Item QR processing failed: ${e.toString()}',
        'ITEM_QR_ERROR',
      );
    }
  }

  /// Process SCANPOINT/MERCHANT QR codes (access control, configuration)
  static Future<QrProcessResponse> _processScanPointQr(
    QrParseResult qr,
    ScanPoint scanPoint,
    String userId,
  ) async {
    try {
      print('🏪 [QrProcessor] Processing scan point QR: ${qr.scanPointId}');

      // Route based on scan point type
      switch (scanPoint.type) {
        case 'access':
          return await AccessService.processEntry(
            userId: userId,
            scanPoint: scanPoint,
          );

        default:
          return QrProcessResponse.error(
            'Scan point QR codes are not supported for ${scanPoint.type} scan points',
            'INCOMPATIBLE_SCAN_POINT',
          );
      }
    } catch (e) {
      print('❌ [QrProcessor] Error processing scan point QR: $e');
      return QrProcessResponse.error(
        'Scan point QR processing failed: ${e.toString()}',
        'SCAN_POINT_QR_ERROR',
      );
    }
  }

  /// Get processing statistics for a scan point
  static Future<Map<String, dynamic>> getProcessingStats(
    String scanPointId,
  ) async {
    try {
      final stats = {
        'total_scans': 0,
        'successful_scans': 0,
        'failed_scans': 0,
        'last_scan': null,
      };

      // This could be extended to query actual statistics from Firestore
      print('📊 [QrProcessor] Getting processing stats for: $scanPointId');

      return stats;
    } catch (e) {
      print('❌ [QrProcessor] Error getting processing stats: $e');
      return {};
    }
  }
}
