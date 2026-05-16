// test_firestore_connection.dart
// Test Firestore connection and real-time listening

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🧪 Testing Firestore Connection...\n');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firestore Emulator
  const emulatorHost = '10.75.131.74'; // Your PC IP
  const firestorePort = 8080;

  try {
    FirebaseFirestore.instance.useFirestoreEmulator(
      emulatorHost,
      firestorePort,
    );
    print(
      '✅ Connected to Firestore Emulator at $emulatorHost:$firestorePort\n',
    );
  } catch (e) {
    print('❌ Failed to connect to emulator: $e\n');
    exit(1);
  }

  // Test 1: Read scanner_triggers/SP002
  print('📖 Test 1: Reading scanner_triggers/SP002...');
  try {
    final doc = await FirebaseFirestore.instance
        .collection('scanner_triggers')
        .doc('SP002')
        .get();

    if (doc.exists) {
      print('✅ Document exists');
      print('   Data: ${doc.data()}');
    } else {
      print('⚠️ Document does not exist');
    }
  } catch (e) {
    print('❌ Read failed: $e');
  }

  // Test 2: Listen for real-time updates
  print('\n👂 Test 2: Setting up real-time listener...');
  print('   Listening to: scanner_triggers/SP002');
  print('   Now trigger from desktop and watch for updates!\n');

  var snapshotCount = 0;
  FirebaseFirestore.instance
      .collection('scanner_triggers')
      .doc('SP002')
      .snapshots()
      .listen((snapshot) {
        snapshotCount++;
        print('\n🔔 Snapshot #$snapshotCount received at ${DateTime.now()}');

        if (snapshot.exists) {
          final data = snapshot.data();
          print('   Document exists: true');
          print('   Data: $data');

          if (data != null) {
            print('   - active: ${data['active']}');
            print('   - scan_mode: ${data['scan_mode']}');
            print('   - triggered_at: ${data['triggered_at']}');
          }
        } else {
          print('   Document exists: false');
        }
      });

  // Keep running
  print('✅ Listener active. Press Ctrl+C to exit.\n');
  print('=' * 50);
  print('ACTION: Now click the trigger button on desktop!');
  print('=' * 50);

  // Wait forever
  await Future.delayed(Duration(hours: 1));
}
