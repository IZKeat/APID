// lib/services/book_loan_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 📚 Book Loan Service
/// Manages book loan operations using the book_loans collection as source of truth
class BookLoanService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String bookLoansCollection = "book_loans";
  static const String booksCollection = "books";

  /// Create a new book loan
  /// Returns the loan_id if successful, null otherwise
  static Future<String?> createLoan({
    required String bookId,
    required String bookTitle,
    required String userId,
    required String userEmail,
    required String scanPointId,
    String? processedByUserId,
  }) async {
    try {
      // Check if book is already borrowed
      final existingLoan = await findActiveLoan(bookId);
      if (existingLoan != null) {
        print('⚠️ [BookLoanService] Book $bookId already has an active loan');
        return null;
      }

      // Generate loan ID with prefix
      final loanId = 'LOAN_${_db.collection(bookLoansCollection).doc().id}';

      // Calculate due date (14 days from now)
      final borrowedAt = DateTime.now();
      final dueDate = borrowedAt.add(const Duration(days: 14));

      // Create loan document
      await _db.collection(bookLoansCollection).doc(loanId).set({
        'loan_id': loanId,
        'book_id': bookId,
        'book_title': bookTitle,
        'user_id': userId,
        'user_email': userEmail,
        'scan_point_id': scanPointId,
        'borrowed_at': Timestamp.fromDate(borrowedAt),
        'due_date': Timestamp.fromDate(dueDate),
        'return_at': null,
        'status': 'borrowed',
        'processed_by_user_id': processedByUserId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update book availability
      await _db.collection(booksCollection).doc(bookId).update({
        'availability': false,
        'last_loan_at': FieldValue.serverTimestamp(),
      });

      print('✅ [BookLoanService] Loan created: $loanId');
      return loanId;
    } catch (e) {
      print('❌ [BookLoanService] Error creating loan: $e');
      return null;
    }
  }

  /// Return a book loan
  /// Returns true if successful, false otherwise
  static Future<bool> returnLoan({
    required String bookId,
    String? processedByUserId,
  }) async {
    try {
      // Find active loan
      final activeLoan = await findActiveLoan(bookId);
      if (activeLoan == null) {
        print('⚠️ [BookLoanService] No active loan found for book $bookId');
        return false;
      }

      final loanId = activeLoan['loan_id'] as String;

      // Update loan document
      await _db.collection(bookLoansCollection).doc(loanId).update({
        'return_at': FieldValue.serverTimestamp(),
        'status': 'returned',
        'return_processed_by_user_id': processedByUserId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update book availability
      await _db.collection(booksCollection).doc(bookId).update({
        'availability': true,
        'last_return_at': FieldValue.serverTimestamp(),
      });

      print('✅ [BookLoanService] Loan returned: $loanId');
      return true;
    } catch (e) {
      print('❌ [BookLoanService] Error returning loan: $e');
      return false;
    }
  }

  /// Find active loan for a book
  /// Returns loan data if found, null otherwise
  static Future<Map<String, dynamic>?> findActiveLoan(String bookId) async {
    try {
      final loanQuery = await _db
          .collection(bookLoansCollection)
          .where('book_id', isEqualTo: bookId)
          .where('status', isEqualTo: 'borrowed')
          .limit(1)
          .get();

      if (loanQuery.docs.isEmpty) {
        return null;
      }

      final loanDoc = loanQuery.docs.first;
      return {'loan_id': loanDoc.id, ...loanDoc.data()};
    } catch (e) {
      print('❌ [BookLoanService] Error finding active loan: $e');
      return null;
    }
  }

  /// Get all active loans for a user
  static Future<List<Map<String, dynamic>>> getUserActiveLoans(
    String userId,
  ) async {
    try {
      final loansQuery = await _db
          .collection(bookLoansCollection)
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'borrowed')
          .get();

      return loansQuery.docs
          .map((doc) => {'loan_id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('❌ [BookLoanService] Error getting user active loans: $e');
      return [];
    }
  }

  /// Get loan history for a book
  static Future<List<Map<String, dynamic>>> getBookLoanHistory(
    String bookId,
  ) async {
    try {
      final loansQuery = await _db
          .collection(bookLoansCollection)
          .where('book_id', isEqualTo: bookId)
          .orderBy('borrowed_at', descending: true)
          .get();

      return loansQuery.docs
          .map((doc) => {'loan_id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('❌ [BookLoanService] Error getting book loan history: $e');
      return [];
    }
  }

  /// Check if a book is available
  static Future<bool> isBookAvailable(String bookId) async {
    try {
      final bookDoc = await _db.collection(booksCollection).doc(bookId).get();

      if (!bookDoc.exists) {
        return false;
      }

      final availability = bookDoc.data()?['availability'] as bool? ?? false;
      return availability;
    } catch (e) {
      print('❌ [BookLoanService] Error checking book availability: $e');
      return false;
    }
  }
}
