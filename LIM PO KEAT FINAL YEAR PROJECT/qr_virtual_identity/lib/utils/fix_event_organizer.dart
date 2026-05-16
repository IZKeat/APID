import 'package:cloud_firestore/cloud_firestore.dart';

class EventFixer {
  /// Fixes the "APU Tech Talk" event to be owned by "Event Check-In Counter" (SP007)
  static Future<void> fixSp007Event() async {
    // ⏳ Delay to avoid conflict with initial UI rendering and threading issues
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      print('🔧 [EventFixer] Attempting to fix SP007 event data...');
      
      final db = FirebaseFirestore.instance;
      
      // 1. Find the event "APU Tech Talk" (EVT001)
      final eventRef = db.collection('events').doc('EVT001');
      final doc = await eventRef.get();

      if (doc.exists) {
        final currentOrganizer = doc.data()?['organizer'];
        const targetOrganizer = 'Event Check-In Counter';

        if (currentOrganizer != targetOrganizer) {
          await eventRef.update({
            'organizer': targetOrganizer,
            'updated_at': FieldValue.serverTimestamp(),
          });
          print('✅ [EventFixer] Fixed EVT001 organizer: "$currentOrganizer" -> "$targetOrganizer"');
        } else {
          print('✅ [EventFixer] EVT001 is already correct.');
        }
      } else {
        print('⚠️ [EventFixer] EVT001 not found.');
      }
    } catch (e) {
      print('❌ [EventFixer] Failed to fix event: $e');
    }
  }
}
