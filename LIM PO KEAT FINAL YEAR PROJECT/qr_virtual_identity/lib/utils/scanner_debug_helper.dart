// lib/utils/scanner_debug_helper.dart


/// 🔍 Scanner Debug Helper
/// Helps diagnose trigger communication issues between desktop and mobile terminals
class ScannerDebugHelper {
  // static final FirebaseFirestore _db = FirebaseFirestore.instance;
  // static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check the current user's scan point configuration
  static Future<void> checkUserScanPointSetup() async {
    /*
    print('\n🔍 ========== SCANNER DEBUG REPORT ==========');

    try {
      // 1. Check user login status
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ ERROR: No user logged in!');
        print('   → Please login first');
        return;
      }

      print('✅ User logged in:');
      print('   UID: ${user.uid}');
      print('   Email: ${user.email}');

      // 2. Check scan_point_id in user document
      final userDoc = await _db.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        print('❌ ERROR: User document not found!');
        print('   → User UID: ${user.uid}');
        return;
      }

      final userData = userDoc.data();
      if (userData == null) {
        print('❌ ERROR: User document data is null!');
        return;
      }

      print('\n📄 User Document Data:');
      print('   Email: ${userData['email']}');
      print('   Role: ${userData['role']}');
      print('   Scan Point ID: ${userData['scan_point_id']}');

      final scanPointId = userData['scan_point_id'] as String?;

      if (scanPointId == null || scanPointId.isEmpty) {
        print('\n❌ ERROR: User does not have scan_point_id assigned!');
        print('   → Please assign a scan point to this user in Firestore');
        print('   → Path: users/${user.uid}');
        print('   → Add field: scan_point_id = "SP002" (or appropriate ID)');
        return;
      }

      // 3. Check if scan point document exists
      final scanPointDoc = await _db
          .collection('scan_points')
          .doc(scanPointId)
          .get();

      if (!scanPointDoc.exists) {
        print('\n❌ ERROR: Scan point document not found!');
        print('   → Scan Point ID: $scanPointId');
        print('   → Please create scan point in Firestore');
        return;
      }

      final scanPointData = scanPointDoc.data();
      if (scanPointData == null) {
        print('❌ ERROR: Scan point document data is null!');
        return;
      }

      print('\n📍 Scan Point Document Data:');
      print('   ID: $scanPointId');
      print('   Name: ${scanPointData['name']}');
      print('   Type: ${scanPointData['type']}');
      print('   Active: ${scanPointData['active']}');
      print('   Owner UID: ${scanPointData['owner_uid']}');

      // 4. Check trigger document
      final triggerDoc = await _db
          .collection('scanner_triggers')
          .doc(scanPointId)
          .get();

      print('\n🔔 Scanner Trigger Status:');
      if (!triggerDoc.exists) {
        print('   ℹ️ No trigger document exists yet');
        print('   → This is normal before first trigger');
        print('   → Will be created when desktop triggers scanner');
      } else {
        final triggerData = triggerDoc.data();
        if (triggerData != null) {
          print('   Active: ${triggerData['active']}');
          print('   Scan Mode: ${triggerData['scan_mode']}');
          print('   Scan Point ID: ${triggerData['scan_point_id']}');
          print('   Triggered At: ${triggerData['triggered_at']}');
        }
      }

      // 5. Check if it's the same account (Desktop & Mobile)
      print('\n👥 Account Verification:');
      final ownerUid = scanPointData['owner_uid'] as String?;
      if (ownerUid == user.uid) {
        print('   ✅ CORRECT: Same account on desktop and mobile');
        print('   → Desktop owner UID: $ownerUid');
        print('   → Mobile user UID: ${user.uid}');
      } else {
        print('   ⚠️ WARNING: Different accounts detected!');
        print('   → Desktop owner UID: $ownerUid');
        print('   → Mobile user UID: ${user.uid}');
        print('   → For SP002, both should use: sp002@apu.edu.my');
      }

      // 6. Check scanner_status
      final statusDoc = await _db
          .collection('scanner_status')
          .doc(user.uid)
          .get();

      print('\n📊 Scanner Status:');
      if (!statusDoc.exists) {
        print('   ℹ️ No scanner status document exists yet');
      } else {
        final statusData = statusDoc.data();
        if (statusData != null) {
          print('   State: ${statusData['state']}');
          print('   Status: ${statusData['status']}');
          print('   Updated At: ${statusData['updated_at']}');
        }
      }

      print('\n✅ All checks completed!');
      print('=========================================\n');
    } catch (e) {
      print('\n❌ ERROR during debug check: $e');
      print('=========================================\n');
    }
    */
  }

  /// specific trigger (For testing purpose)
  static Future<void> testCreateTrigger(
    String scanPointId,
    String scanMode,
  ) async {
    /*
    try {
      print('\n🧪 ========== TEST TRIGGER CREATION ==========');
      print('   Scan Point ID: $scanPointId');
      print('   Scan Mode: $scanMode');
      print('   Writing to: scanner_triggers/$scanPointId');
      print('   Current time: ${DateTime.now()}');

      await _db.collection('scanner_triggers').doc(scanPointId).set({
        'active': true,
        'scan_mode': scanMode,
        'scan_point_id': scanPointId,
        'triggered_at': FieldValue.serverTimestamp(),
      });

      print('✅ Test trigger written to Firestore!');
      print('   Path: scanner_triggers/$scanPointId');
      print('   Data: {active: true, scan_mode: $scanMode}');
      print('   Check mobile device NOW for real-time update!');
      print('   Expected logs:');
      print('     🔔 [TriggerService] Snapshot received');
      print('     🔔 Data received: active: true');
      print('     🔥🔥🔥 TRIGGER IS ACTIVE!');
      print('==========================================\n');
      print('   Scan Point ID: $scanPointId');
      print('   Scan Mode: $scanMode');
    } catch (e) {
      print('❌ Failed to create test trigger: $e');
    }
    */
  }

  /// Listen to trigger changes (For testing purpose)
  static void listenToTriggers(String scanPointId) {
    /*
    print('\n👂 Starting trigger listener for: $scanPointId');

    _db
        .collection('scanner_triggers')
        .doc(scanPointId)
        .snapshots()
        .listen(
          (doc) {
            if (!doc.exists) {
              print('📭 Trigger document does not exist');
              return;
            }

            final data = doc.data();
            if (data == null) {
              print('📭 Trigger data is null');
              return;
            }

            print('\n🔔 TRIGGER UPDATE RECEIVED:');
            print('   Active: ${data['active']}');
            print('   Scan Mode: ${data['scan_mode']}');
            print('   Timestamp: ${DateTime.now()}');
          },
          onError: (error) {
            print('❌ Trigger listener error: $error');
          },
        );
    */
  }
}
