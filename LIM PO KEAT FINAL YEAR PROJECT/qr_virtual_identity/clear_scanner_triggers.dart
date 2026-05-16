// clear_scanner_triggers.dart
// Utility script to clear old scanner_triggers documents
// Usage: dart run clear_scanner_triggers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🧹 Starting scanner triggers cleanup...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('scanner_triggers');

    // Fetch all documents
    print('📡 Fetching all scanner_triggers documents...');
    final querySnapshot = await collection.get();

    if (querySnapshot.docs.isEmpty) {
      print('✅ No scanner_triggers documents found. Collection is clean.');
      return;
    }

    print('📄 Found ${querySnapshot.docs.length} documents to delete');

    // Batch delete
    final batch = firestore.batch();
    int count = 0;

    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
      count++;

      // Firestore batch limit is 500 operations
      if (count >= 500) {
        print('🔥 Committing batch of $count deletions...');
        await batch.commit();
        count = 0;
      }
    }

    // Commit remaining operations
    if (count > 0) {
      print('🔥 Committing final batch of $count deletions...');
      await batch.commit();
    }

    print(
      '✅ Successfully cleared ${querySnapshot.docs.length} scanner_triggers documents',
    );
    print('🎯 Collection is now clean and ready for testing');
  } catch (e) {
    print('❌ Error during cleanup: $e');
    print(
      '💡 Make sure Firebase is properly configured and you have admin permissions',
    );
  }
}
