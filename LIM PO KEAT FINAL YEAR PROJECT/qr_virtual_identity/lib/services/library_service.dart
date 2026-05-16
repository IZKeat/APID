// lib/services/library_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/scan_point_service.dart';
import '../services/qr_processor_service.dart';
import '../strategies/library/borrow_strategy.dart';
import '../strategies/library/return_strategy.dart';
import '../services/book_loan_service.dart';

/// 📚 Library Service
/// Handles library sessions, book catalog, and book loans with a two-step workflow:
/// 1. Scan student QR code to identify the user
/// 2. Scan book barcode to borrow or return the book
class LibraryService {
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
      print('❌ [LibraryService] Security Check Error: $e');
      return false;
    }
  }

  /// Collection names
  static const String booksCollection = "books";
  static const String bookLoansCollection = "book_loans";
  static const String librarySessionsCollection = "library_sessions";

  /// Process user QR codes for library operations
  ///
  /// This is step 1 of the library workflow:
  /// - Validates the scan point is a library type
  /// - Creates or updates a library session for this scan point
  /// - Returns a success message prompting to scan the book barcode
  static Future<QrProcessResponse> processUser({
    required String userId,
    required ScanPoint scanPoint,
    String? processedByUserId,
    // Security Parameters
    int? timestamp,
    String? nonce,
    String? signature,
  }) async {
    try {
      print('📚 [LibraryService] Processing user QR: $userId');

      // 🔒 Security Check: HMAC Verification
      if (timestamp != null && nonce != null && signature != null) {
        // Check for replay attacks (Timestamp expiry - 60 seconds)
        final now = DateTime.now().millisecondsSinceEpoch;
        if ((now - timestamp).abs() > 60000) {
             return QrProcessResponse.error(
            'QR Code Expired. Please refresh.',
            'QR_EXPIRED',
          );
        }

        final isValid = _verifyHmac(userId, timestamp, nonce, signature);
        if (!isValid) {
          return QrProcessResponse.error(
            'Security Alert: Invalid QR Signature',
            'INVALID_SIGNATURE',
          );
        }
        print('🔒 [LibraryService] HMAC Correct. Secure Access.');
      } else {
        print('⚠️ [LibraryService] Warning: Processing unsecured transaction!');
      }

      print(
        '📚 [LibraryService] Scan point: ${scanPoint.name} (${scanPoint.type})',
      );

      // Validate scan point type
      if (scanPoint.type != 'library') {
        return QrProcessResponse.error(
          'User QR codes are only supported at library scan points',
          'INVALID_SCAN_POINT_TYPE',
        );
      }

      // Use scanPointId if available, otherwise fall back to id
      final scanPointIdentifier = scanPoint.scanPointId.isNotEmpty
          ? scanPoint.scanPointId
          : scanPoint.id;

      // Write or update library session
      await _db.collection(librarySessionsCollection).doc(scanPoint.id).set({
        'scan_point_id': scanPointIdentifier,
        'scan_point_name': scanPoint.name,
        'current_user_id': userId,
        'processed_by_user_id': processedByUserId,
        'status': 'awaiting_book',
        'last_action': 'user_scanned',
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('📚 [LibraryService] Library session created for user: $userId');

      return QrProcessResponse.success(
        'Student identified. Please scan the book barcode.',
        {
          'current_user_id': userId,
          'scan_point': scanPoint.name,
          'stage': 'awaiting_book',
        },
      );
    } catch (e) {
      print('❌ [LibraryService] Error processing user QR: $e');
      return QrProcessResponse.error(
        'User QR processing failed: ${e.toString()}',
        'USER_QR_ERROR',
      );
    }
  }

  /// Process item QR codes for library operations
  ///
  /// This is step 2 of the library workflow:
  /// - Validates the scan point is a library type
  /// - For BORROW mode: Checks for an active library session
  /// - For RETURN mode: Skips session check, uses active loan's user_id
  /// - Loads the book from the catalog
  /// - Determines if this is a borrow or return operation
  /// - Executes the appropriate transaction
  static Future<QrProcessResponse> processItem({
    required String itemId,
    required ScanPoint scanPoint,
    String? processedByUserId,
    String mode = 'borrow', // 'borrow' or 'return'
  }) async {
    try {
      print('📚 [LibraryService] Processing item QR: $itemId (mode: $mode)');
      print(
        '📚 [LibraryService] Scan point: ${scanPoint.name} (${scanPoint.type})',
      );

      // Validate scan point type
      if (scanPoint.type != 'library') {
        return QrProcessResponse.error(
          'Item QR codes are only supported at library scan points',
          'INVALID_SCAN_POINT_TYPE',
        );
      }

      // For RETURN mode: Skip session check and get user from active loan
      String? currentUserId;

      if (mode == 'return') {
        print('📚 [LibraryService] Return mode - checking for active loan');

        // Check for active loan first
        final activeLoan = await BookLoanService.findActiveLoan(itemId);

        if (activeLoan == null) {
          return QrProcessResponse.error(
            'No active loan found for this book. Cannot process return.',
            'NO_ACTIVE_LOAN',
          );
        }

        // Get user ID from the loan itself
        currentUserId = activeLoan['user_id'] as String?;

        if (currentUserId == null || currentUserId.isEmpty) {
          return QrProcessResponse.error(
            'Invalid loan data - no user ID found.',
            'INVALID_LOAN_DATA',
          );
        }

        print(
          '📚 [LibraryService] Return mode - user from loan: $currentUserId',
        );
      } else {
        // BORROW mode: Load the current library session
        print('📚 [LibraryService] Borrow mode - checking library session');

        final sessionDoc = await _db
            .collection(librarySessionsCollection)
            .doc(scanPoint.id)
            .get();

        if (!sessionDoc.exists) {
          return QrProcessResponse.error(
            'Please scan a student QR code first before scanning a book.',
            'NO_ACTIVE_SESSION',
          );
        }

        final sessionData = sessionDoc.data()!;
        currentUserId = sessionData['current_user_id'] as String?;

        if (currentUserId == null || currentUserId.isEmpty) {
          return QrProcessResponse.error(
            'Please scan a student QR code first before scanning a book.',
            'NO_ACTIVE_SESSION',
          );
        }

        print(
          '📚 [LibraryService] Active session found for user: $currentUserId',
        );
      }

      // Load the book document
      final bookDoc = await _db.collection(booksCollection).doc(itemId).get();

      if (!bookDoc.exists) {
        return QrProcessResponse.error(
          'Book not found in library catalog',
          'BOOK_NOT_FOUND',
        );
      }

      final bookData = bookDoc.data()!;
      final bookTitle = bookData['title'] as String? ?? 'Unknown Book';

      print('📚 [LibraryService] Book found: $bookTitle');

      // Get user email for logging
      final userDoc = await _db.collection('users').doc(currentUserId).get();
      final userEmail = userDoc.exists
          ? (userDoc.data()?['email'] as String? ?? 'unknown@email.com')
          : 'unknown@email.com';

      // Check for an active loan for this book
      final activeLoan = await BookLoanService.findActiveLoan(itemId);

      if (activeLoan == null) {
        // No active loan - perform BORROW using BorrowStrategy
        final result = await BorrowStrategy.executeBorrow(
          bookId: itemId,
          userId: currentUserId,
          userEmail: userEmail,
          scanPoint: scanPoint,
          processedByUserId: processedByUserId,
        );

        if (result != null) {
          // Reset session only in borrow mode
          if (mode == 'borrow') {
            await _resetSession(scanPoint.id);
          }

          return QrProcessResponse.success(result, {
            'book_id': itemId,
            'book_title': bookTitle,
            'user_id': currentUserId,
            'loan_type': 'borrow',
            'scan_point': scanPoint.name,
          });
        } else {
          return QrProcessResponse.error(
            'Failed to borrow book. Please try again.',
            'BORROW_FAILED',
          );
        }
      } else {
        // Active loan exists - perform RETURN using ReturnStrategy
        final result = await ReturnStrategy.executeReturn(
          bookId: itemId,
          scanPoint: scanPoint,
          processedByUserId: processedByUserId,
        );

        if (result != null) {
          // Reset session only in borrow mode
          if (mode == 'borrow') {
            await _resetSession(scanPoint.id);
          }

          return QrProcessResponse.success(result, {
            'book_id': itemId,
            'book_title': bookTitle,
            'user_id': currentUserId,
            'loan_type': 'return',
            'scan_point': scanPoint.name,
          });
        } else {
          return QrProcessResponse.error(
            'Failed to return book. Please try again.',
            'RETURN_FAILED',
          );
        }
      }
    } catch (e) {
      print('❌ [LibraryService] Error processing item QR: $e');
      return QrProcessResponse.error(
        'Item QR processing failed: ${e.toString()}',
        'ITEM_QR_ERROR',
      );
    }
  }

  // Removed _findActiveLoan - now using BookLoanService.findActiveLoan

  // Removed _processBorrow and _processReturn - now using BorrowStrategy and ReturnStrategy

  /// Reset library session after completing a transaction
  static Future<void> _resetSession(String scanPointId) async {
    try {
      await _db.collection(librarySessionsCollection).doc(scanPointId).update({
        'status': 'idle',
        'current_user_id': null,
        'last_action': 'completed',
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('📚 [LibraryService] Library session reset for: $scanPointId');
    } catch (e) {
      print('❌ [LibraryService] Error resetting session: $e');
    }
  }

  /// Get library statistics for a scan point
  static Future<Map<String, dynamic>> getLibraryStats(
    String scanPointId,
  ) async {
    try {
      print('📊 [LibraryService] Getting library stats for: $scanPointId');

      // Get active borrows
      final activeBorrows = await _db
          .collection(bookLoansCollection)
          .where('scan_point_id', isEqualTo: scanPointId)
          .where('status', isEqualTo: 'borrowed')
          .get();

      // Get today's library activities
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayActivities = await _db
          .collection(bookLoansCollection)
          .where('scan_point_id', isEqualTo: scanPointId)
          .where(
            'borrowed_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      return {
        'active_borrows': activeBorrows.docs.length,
        'today_activities': todayActivities.docs.length,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ [LibraryService] Error getting library stats: $e');
      return {};
    }
  }

  /// Get user's borrowed items
  static Future<List<Map<String, dynamic>>> getUserBorrowedItems(
    String userId,
  ) async {
    // Delegate to BookLoanService
    return await BookLoanService.getUserActiveLoans(userId);
  }
}
