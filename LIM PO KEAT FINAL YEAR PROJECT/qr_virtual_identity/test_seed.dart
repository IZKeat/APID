// test_seed.dart - Quick script to test seeding
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';
import 'lib/utils/seed_service.dart';

Future<void> main() async {
  print('🔧 Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Clear auth state
  await FirebaseAuth.instance.signOut();

  // Connect to Firestore emulator
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  print('✅ Connected to Firestore Emulator at 127.0.0.1:8080');

  // Run seeding
  print('\n🌱 Starting seed process...\n');
  await SeedService.rebuildFirestore(clearExisting: true);

  print('\n✅ Seeding complete!');
  print('\n📋 You can now login with:');
  print('   • sp002@apu.edu.my (password: 123456) - Library Counter');
  print('   • sp001@apu.edu.my (password: 123456) - Smokey Café');
  print('   • sp004@apu.edu.my (password: 123456) - Lab A Room Booking');
  print('   • sp005@apu.edu.my (password: 123456) - Campus Mart');
}
