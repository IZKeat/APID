// lib/strategies/library/return_strategy.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/book_loan_service.dart';
import '../../services/interaction_service.dart';
import '../../services/scan_point_service.dart';

/// 📚 Library Return Strategy
/// Handles book return workflow:
/// 1. Scan book barcode only (no student QR required)
/// 2. Find active loan and mark as returned
class ReturnStrategy {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Execute return operation
  /// Returns success message or null if failed
  static Future<String?> executeReturn({
    required String bookId,
    required ScanPoint scanPoint,
    String? processedByUserId,
  }) async {
    try {
      print('📚 [ReturnStrategy] Executing return for book: $bookId');

      // Step 1: Check if book exists
      final bookDoc =
          await _db.collection(BookLoanService.booksCollection).doc(bookId).get();

      if (!bookDoc.exists) {
        print('❌ [ReturnStrategy] Book not found: $bookId');
        await InteractionService.logError(
          type: 'return',
          errorMessage: 'Book not found in catalog',
          scanPointId: scanPoint.scanPointId,
          scanPointName: scanPoint.name,
          bookId: bookId,
        );
        return null;
      }

      final bookData = bookDoc.data()!;
      final bookTitle = bookData['title'] as String? ?? 'Unknown Book';

      // Step 2: Find active loan
      final activeLoan = await BookLoanService.findActiveLoan(bookId);

      if (activeLoan == null) {
        print('❌ [ReturnStrategy] No active loan found for book: $bookId');
        await InteractionService.logError(
          type: 'return',
          errorMessage: 'No active loan found for this book',
          scanPointId: scanPoint.scanPointId,
          scanPointName: scanPoint.name,
          bookId: bookId,
        );
        return null;
      }

      // Extract user info from the loan for logging
      final loanUserId = activeLoan['user_id'] as String?;
      final loanUserEmail = activeLoan['user_email'] as String?;

      // Step 3: Return the loan
      final success = await BookLoanService.returnLoan(
        bookId: bookId,
        processedByUserId: processedByUserId,
      );

      if (!success) {
        print('❌ [ReturnStrategy] Failed to return loan');
        await InteractionService.logError(
          type: 'return',
          errorMessage: 'Failed to return loan',
          scanPointId: scanPoint.scanPointId,
          scanPointName: scanPoint.name,
          bookId: bookId,
          userId: loanUserId,
          userEmail: loanUserEmail,
        );
        return null;
      }

      // Step 4: Log successful interaction
      await InteractionService.logReturn(
        bookId: bookId,
        bookTitle: bookTitle,
        scanPointId: scanPoint.scanPointId,
        scanPointName: scanPoint.name,
        userId: loanUserId,
        userEmail: loanUserEmail,
        remarks: 'Book returned successfully',
      );

      print('✅ [ReturnStrategy] Return completed successfully');
      return 'Book returned successfully: $bookTitle';
    } catch (e) {
      print('❌ [ReturnStrategy] Error executing return: $e');
      return null;
    }
  }
}
