// inspect_firestore.dart - READ-ONLY Firestore structure inspector
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  print('🔍 FIRESTORE STRUCTURE INSPECTOR (READ-ONLY MODE)');
  print('═══════════════════════════════════════════════════════════════');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Connect to Firestore emulator
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  print('✅ Connected to Firestore Emulator at 127.0.0.1:8080\n');

  final db = FirebaseFirestore.instance;

  // List of expected collections based on codebase analysis
  final expectedCollections = [
    'admins',
    'users',
    'scan_points',
    'interactions',
    'logs',
    'events',
    'user_tickets',
    'guest_users',
    'guest_tickets',
    'books',
    'book_loans',
    'library_sessions',
    'ticket_scans',
    'scanner_triggers',
    'scanner_status',
  ];

  print('📋 ROOT COLLECTION LIST');
  print('═══════════════════════════════════════════════════════════════\n');

  final foundCollections = <String>[];
  final emptyCollections = <String>[];

  for (final collectionName in expectedCollections) {
    try {
      final snapshot = await db.collection(collectionName).limit(5).get();

      if (snapshot.docs.isEmpty) {
        emptyCollections.add(collectionName);
        print('⚪ $collectionName (empty)');
      } else {
        foundCollections.add(collectionName);
        print('✅ $collectionName (${snapshot.docs.length}+ documents)');
      }
    } catch (e) {
      print('❌ $collectionName (error: $e)');
    }
  }

  print('\n');
  print('═══════════════════════════════════════════════════════════════');
  print('📊 DETAILED COLLECTION ANALYSIS');
  print('═══════════════════════════════════════════════════════════════\n');

  // Analyze each found collection
  for (final collectionName in foundCollections) {
    await analyzeCollection(db, collectionName);
    print('');
  }

  // Summary
  print('═══════════════════════════════════════════════════════════════');
  print('📈 FIRESTORE DATABASE SUMMARY');
  print('═══════════════════════════════════════════════════════════════\n');

  print('Total Collections Checked: ${expectedCollections.length}');
  print('Collections with Data: ${foundCollections.length}');
  print('Empty Collections: ${emptyCollections.length}');

  if (emptyCollections.isNotEmpty) {
    print('\n⚠️  Empty Collections:');
    for (final name in emptyCollections) {
      print('   - $name');
    }
  }

  print('\n✅ Inspection complete!\n');
}

Future<void> analyzeCollection(
  FirebaseFirestore db,
  String collectionName,
) async {
  print('─────────────────────────────────────────────────────────────────');
  print('Collection: $collectionName');
  print('─────────────────────────────────────────────────────────────────');

  try {
    // Get first 10 documents for analysis
    final snapshot = await db.collection(collectionName).limit(10).get();
    final docCount = snapshot.docs.length;

    // Sample document IDs
    final sampleIds = snapshot.docs.take(5).map((doc) => doc.id).toList();
    print('Sample Document IDs: ${sampleIds.join(", ")}');
    print('Documents Sampled: $docCount');

    if (snapshot.docs.isEmpty) {
      print('Status: Empty collection\n');
      return;
    }

    // Infer schema from first document
    final firstDoc = snapshot.docs.first;
    final data = firstDoc.data();

    print('\nInferred Schema (from first document):');
    final schema = inferSchema(data);
    print(const JsonEncoder.withIndent('  ').convert(schema));

    // Check for subcollections (only check first document)
    print('\nChecking for subcollections...');
    final subcollections = await checkSubcollections(firstDoc.reference);

    if (subcollections.isNotEmpty) {
      print('Subcollections Found:');
      for (final subName in subcollections) {
        print('  - $subName');
      }
    } else {
      print('No subcollections found');
    }

    // Field consistency check across multiple documents
    if (snapshot.docs.length > 1) {
      print('\nField Consistency Check:');
      final allFields = <String>{};
      final fieldCounts = <String, int>{};

      for (final doc in snapshot.docs) {
        final docData = doc.data();
        for (final key in docData.keys) {
          allFields.add(key);
          fieldCounts[key] = (fieldCounts[key] ?? 0) + 1;
        }
      }

      final inconsistentFields = <String>[];
      for (final field in allFields) {
        if (fieldCounts[field]! < snapshot.docs.length) {
          inconsistentFields.add(
            '$field (${fieldCounts[field]}/${snapshot.docs.length} docs)',
          );
        }
      }

      if (inconsistentFields.isEmpty) {
        print('✅ All fields consistent across sampled documents');
      } else {
        print('⚠️  Inconsistent fields detected:');
        for (final field in inconsistentFields) {
          print('   - $field');
        }
      }
    }
  } catch (e) {
    print('❌ Error analyzing collection: $e');
  }
}

Map<String, dynamic> inferSchema(Map<String, dynamic> data) {
  final schema = <String, dynamic>{};

  for (final entry in data.entries) {
    final value = entry.value;

    if (value == null) {
      schema[entry.key] = 'null';
    } else if (value is String) {
      schema[entry.key] = 'string';
    } else if (value is int) {
      schema[entry.key] = 'integer';
    } else if (value is double) {
      schema[entry.key] = 'double';
    } else if (value is bool) {
      schema[entry.key] = 'boolean';
    } else if (value is Timestamp) {
      schema[entry.key] = 'Timestamp';
    } else if (value is List) {
      if (value.isEmpty) {
        schema[entry.key] = 'array (empty)';
      } else {
        final firstItemType = value.first.runtimeType.toString();
        schema[entry.key] = 'array<$firstItemType>';
      }
    } else if (value is Map) {
      schema[entry.key] = 'map';
    } else {
      schema[entry.key] = value.runtimeType.toString();
    }
  }

  return schema;
}

Future<List<String>> checkSubcollections(DocumentReference docRef) async {
  // Note: Firestore doesn't have a direct API to list subcollections in client SDK
  // We can only check known subcollection names
  final knownSubcollections = ['joined_events', 'transactions', 'activities'];
  final found = <String>[];

  for (final subName in knownSubcollections) {
    try {
      final subSnap = await docRef.collection(subName).limit(1).get();
      if (subSnap.docs.isNotEmpty) {
        found.add(subName);
      }
    } catch (e) {
      // Subcollection doesn't exist or error
    }
  }

  return found;
}
