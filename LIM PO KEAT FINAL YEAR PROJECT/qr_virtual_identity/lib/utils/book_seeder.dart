// lib/utils/book_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apid/utils/book_data.dart';

class BookSeeder {
  static Future<void> seedBooks() async {
    final db = FirebaseFirestore.instance;

    print("📚 Seeding ${apuLibraryBooks.length} library books...");

    for (final book in apuLibraryBooks) {
      final String? isbn = book["isbn"];

      // Skip malformed items
      if (isbn == null || isbn.isEmpty) {
        print("⚠️ Skipped invalid book entry: ${book["title"]}");
        continue;
      }

      await db.collection("books").doc(isbn).set({
        "title": book["title"],
        "authors": book["authors"],
        "publisher": book["publisher"],
        "year": book["year"],
        "edition": book["edition"],
        "isbn": isbn,
        "call_number": book["callNumber"],
        "subjects": book["subjects"],
        "availability": true,
        "created_at": FieldValue.serverTimestamp(),
      });

      print("  ├─ Inserted: $isbn — ${book["title"]}");
    }

    print("✅ Successfully seeded ${apuLibraryBooks.length} books.\n");
  }
}
