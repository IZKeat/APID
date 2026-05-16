// lib/strategies/library/borrow_strategy.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/book_loan_service.dart';
import '../../services/interaction_service.dart';
import '../../services/scan_point_service.dart';

/// 📚 Library Borrow Strategy
/// Handles the two-step borrow workflow:
/// 1. Scan student QR code (hold user context)
/// 2. Scan book barcode (execute borrow)
class BorrowStrategy {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Execute borrow operation
  /// Returns success message or null if failed
  static Future<String?> executeBorrow({
    required String bookId,
    required String userId,
    required String userEmail,
    required ScanPoint scanPoint,
    String? processedByUserId,
  }) async {
    try {
      print('📖 [BorrowStrategy] Executing borrow for book: $bookId');

      // Step 1: Check if book exists
      final bookDoc =
          await _db.collection(BookLoanService.booksCollection).doc(bookId).get();

      if (!bookDoc.exists) {
        print('❌ [BorrowStrategy] Book not found: $bookId');
        await InteractionService.logError(
          type: 'borrow',
          errorMessage: 'Book not found in catalog',
          scanPointId: scanPoint.scanPointId,
          scanPointName: scanPoint.name,
          bookId: bookId,
          userId: userId,
          userEmail: userEmail,
        );
        return null;
      }

      final bookData = bookDoc.data()!;
      final bookTitle = bookData['title'] as String? ?? 'Unknown Book';
      final availability = bookData['availability'] as bool? ?? false;

      // Step 2: Check availability
      if (!availability) {
        print('❌ [BorrowStrategy] Book is already borrowed: $bookId');
        await InteractionService.logError(
          type: 'borrow',
          errorMessage: 'Book currently borrowed',
          scanPointId: scanPoint.scanPointId,
          scanPointName: scanPoint.name,
          bookId: bookId,
          userId: userId,
          userEmail: userEmail,
        );
        return null;
      }

      // Step 3: Double-check no active loan exists
      final existingLoan = await BookLoanService.findActiveLoan(bookId);
      if (existingLoan != null) {
        print('❌ [BorrowStrategy] Active loan already exists for book: $bookId');
        await InteractionService.logError(
          type: 'borrow',
          errorMessage: 'Book has an active loan',
          scanPointId: scanPoint.scanPointId,
          scanPointName: scanPoint.name,
          bookId: bookId,
          userId: userId,
          userEmail: userEmail,
        );
        return null;
      }

      // Step 4: Create loan
      final loanId = await BookLoanService.createLoan(
        bookId: bookId,
        bookTitle: bookTitle,
        userId: userId,
        userEmail: userEmail,
        scanPointId: scanPoint.scanPointId,
        processedByUserId: processedByUserId,
      );

      if (loanId == null) {
        print('❌ [BorrowStrategy] Failed to create loan');
        await InteractionService.logError(
          type: 'borrow',
          errorMessage: 'Failed to create loan',
          scanPointId: scanPoint.scanPointId,
          scanPointName: scanPoint.name,
          bookId: bookId,
          userId: userId,
          userEmail: userEmail,
        );
        return null;
      }

      // Step 5: Log successful interaction
      await InteractionService.logBorrow(
        bookId: bookId,
        bookTitle: bookTitle,
        userId: userId,
        userEmail: userEmail,
        scanPointId: scanPoint.scanPointId,
        scanPointName: scanPoint.name,
        remarks: 'Book borrowed successfully - Loan: $loanId',
      );

      print('✅ [BorrowStrategy] Borrow completed successfully');
      return 'Book borrowed successfully: $bookTitle';
    } catch (e) {
      print('❌ [BorrowStrategy] Error executing borrow: $e');
      return null;
    }
  }
}
