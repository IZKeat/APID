// lib/pages/merchant_dashboard_desktop.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:apid/pages_desktop/profile_desktop_page.dart';
import 'package:apid/routes.dart';
import 'package:apid/pages/merchant/merchant_pos_page.dart';
import 'package:apid/pages_desktop/widgets/desktop_sidebar.dart';
import 'package:apid/pages_desktop/views/library_view.dart';
import 'package:apid/pages_desktop/views/access_view.dart';
import 'package:apid/pages_desktop/views/attendance_view.dart';
import 'package:apid/pages_desktop/views/commerce_profile_view.dart';
import 'package:apid/utils/fix_event_organizer.dart';
import 'package:animations/animations.dart';

// Material 3 Color Palette
class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const secondary = Color(0xFFE9E7FD);
  static const fontDark = Color(0xFF1E1E1E);
}

/// Merchant Dashboard (Desktop)
/// - Dynamically loads the merchant document based on logged-in user (owner_uid)
/// - Displays transaction summary, revenue chart, and activity stats
/// - Works for multiple merchants automatically
class MerchantDashboardDesktop extends StatefulWidget {
  final String? prototypeUid; // ⚠️ For FYP Prototype Bypass
  const MerchantDashboardDesktop({super.key, this.prototypeUid});

  @override
  State<MerchantDashboardDesktop> createState() =>
      _MerchantDashboardDesktopState();
}

class _MerchantDashboardDesktopState extends State<MerchantDashboardDesktop> {
  String _currentView = 'POS'; // Replaces _selectedIndex
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isScannerTriggered = false; // Track scanner triggered state
  bool _isProcessing = false; // Track if mobile is processing
  String? _triggeredDocId; // Store trigger document ID for stop operation
  StreamSubscription<DocumentSnapshot>? _scannerStatusSubscription; // Scanner status listener
  String? _selectedEventId; // Selected Event ID for attendance
  String? _selectedEventName; // Selected Event name (for display/trigger)
  Timer? _scannerTimeoutTimer; // ⏱️ Timer for scanner timeout
  StreamSubscription<QuerySnapshot>? _interactionSubscription; // 👂 Listen for success

  User? get _authUser => FirebaseAuth.instance.currentUser;
  String? get _uid => widget.prototypeUid ?? _authUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _merchantStream;

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    final email = _authUser?.email ?? '';

    // Set initial view based on email (matching React logic)
    if (email.startsWith('sp002')) {
      _currentView = 'LIBRARY';
    } else if (email.startsWith('sp006')) {
      _currentView = 'ACCESS';
    } else if (email.startsWith('sp007')) {
      _currentView = 'ATTENDANCE';
    } else {
      _currentView = 'POS';
    }

    // 🔧 AUTO-FIX: Ensure SP007 can see the event
    if (email.startsWith('sp007')) {
      EventFixer.fixSp007Event();
    }

    if (uid != null) {
      // ✅ Stream scan_points belonging to this logged-in user
      _merchantStream = FirebaseFirestore.instance
          .collection('scan_points')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .snapshots();

      // ✅ Update last_active timestamp whenever the dashboard opens
      FirebaseFirestore.instance
          .collection('scan_points')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .get()
          .then((snap) {
            if (snap.docs.isNotEmpty) {
              snap.docs.first.reference.update({
                'last_active': FieldValue.serverTimestamp(),
              });
            }
          });

      // ✅ Listen to scanner status for real-time sync with mobile device
      _scannerStatusSubscription = FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (!mounted) return;

              print(
                '🖥 [Desktop] Scanner status snapshot received - exists: ${snapshot.exists}',
              );

              if (!snapshot.exists) {
                print('🖥 [Desktop] No scanner status found, setting to idle');
                if (_isScannerTriggered) {
                  setState(() => _isScannerTriggered = false);
                  print('🖥 [Desktop] UI updated to idle (no document)');
                }
                return;
              }

              final data = snapshot.data();
              if (data == null) {
                print('🖥 [Desktop] Scanner status data is null');
                return;
              }

              final status = data['status'] as String?;
              final state =
                  data['state'] as String?; // New field for consistency
              final updatedAt = data['updated_at'] as Timestamp?;

              // Use 'state' field first, fall back to 'status' for compatibility
              final currentState = state ?? status;
              
              // Check if active OR processing
              final shouldBeTriggered =
                  (currentState == 'ACTIVE' || currentState == 'active' || currentState == 'PROCESSING' || currentState == 'processing');
              
              // Check if processing specifically
              final isProcessing = (currentState == 'PROCESSING' || currentState == 'processing');

              print(
                '🖥 [Desktop] Scanner state: $currentState, should be triggered: $shouldBeTriggered, processing: $isProcessing',
              );
              if (updatedAt != null) {
                print('🖥 [Desktop] Updated at: ${updatedAt.toDate()}');
              }

              // Update triggered state if changed
              if (_isScannerTriggered != shouldBeTriggered) {
                setState(() {
                  _isScannerTriggered = shouldBeTriggered;
                });
                print(
                  '🖥 [Desktop] UI updated - triggered: $_isScannerTriggered',
                );
              }
              
              // Update processing state if changed
              if (_isProcessing != isProcessing) {
                setState(() {
                  _isProcessing = isProcessing;
                });
                print('🖥 [Desktop] UI updated - processing: $_isProcessing');
              }
            },
            onError: (error) {
              print('❌ [Desktop] Scanner status listener error: $error');
            },
          );
    }
  }

  @override
  void dispose() {
    _scannerTimeoutTimer?.cancel();
    _scannerStatusSubscription?.cancel();
    _interactionSubscription?.cancel();
    super.dispose();
  }

  void _onNavigate(String view) {
    setState(() => _currentView = view);
  }

  void triggerMobileScanner() async {
    final uid = _uid;
    if (uid == null || _isScannerTriggered) return;

    try {
      // Get merchant's scan point data to determine scan_mode
      final merchantSnap = await FirebaseFirestore.instance
          .collection('scan_points')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (merchantSnap.docs.isEmpty) {
        throw Exception('No scan point found for this merchant');
      }

      final scanPointData = merchantSnap.docs.first.data();
      final scanPointId = scanPointData['scan_point_id'] as String;
      final scanPointType = scanPointData['type'] as String? ?? 'commerce';

      print(
        '🖥 [Desktop] Starting trigger for $scanPointId (type: $scanPointType)',
      );

      // ✅ Immediately update scanner_status to ACTIVE
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .set({
            'state': 'ACTIVE',
            'status': 'active',
            'updated_at': FieldValue.serverTimestamp(),
          });

      setState(() => _isScannerTriggered = true);

      // ✅ Write UNIFIED trigger to scanner_triggers/{scan_point_id}
      await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .doc(scanPointId)
          .set({
            'active': true,
            'scan_mode': scanPointType, // commerce, library, booking, or access
            'scan_point_id': scanPointId,
            'triggered_at': FieldValue.serverTimestamp(),
          });

      _triggeredDocId = scanPointId;
      print('🖥 [Desktop] Trigger created for scan point: $scanPointId');

      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    } catch (e) {
      print('❌ [Desktop] Failed to trigger scanner: $e');

      // Revert scanner status to IDLE on failure
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .set({
            'state': 'IDLE',
            'status': 'idle',
            'updated_at': FieldValue.serverTimestamp(),
          });

      setState(() => _isScannerTriggered = false);
      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    }
  }

  void stopMobileScanner() async {
    final uid = _uid;
    if (!_isScannerTriggered || uid == null) return;

    // 🛡️ Safety: Cancel timer
    _scannerTimeoutTimer?.cancel();
    _interactionSubscription?.cancel();

    try {
      print('🖥 [Desktop] Sending stop command for UID: $uid');

      // ✅ Immediately update scanner_status to IDLE
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .set({
            'state': 'IDLE',
            'status': 'idle',
            'updated_at': FieldValue.serverTimestamp(),
          });

      // ✅ Immediately update desktop UI to IDLE
      setState(() => _isScannerTriggered = false);

      // ✅ Insert a stop trigger in scanner_triggers
      await FirebaseFirestore.instance.collection('scanner_triggers').add({
        'triggered_by': uid,
        'target_uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'triggered_from': 'desktop',
        'status': 'stopped',
        'stop_reason': 'desktop_stop_command',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update existing trigger if we have the ID
      if (_triggeredDocId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('scanner_triggers')
              .doc(_triggeredDocId!)
              .update({
                'active': false,
                'status': 'stopped',
                'stopped_at': FieldValue.serverTimestamp(),
                'stopped_reason': 'desktop_stop_command',
              });
        } catch (e) {
          print('⚠️ [Desktop] Failed to update existing trigger: $e');
        }
        _triggeredDocId = null;
      }

      print('🖥 [Desktop] Stop command completed');

      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    } catch (e) {
      print('❌ [Desktop] Failed to stop scanner: $e');
      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    }
  }

  /// Trigger Library Mode on mobile device
  /// This activates the library workflow based on the specified mode
  void triggerLibraryScanner({String mode = 'borrow'}) async {
    final uid = _uid;
    if (uid == null || _isScannerTriggered) return;

    // 🛡️ Safety: Cancel any existing timer
    _scannerTimeoutTimer?.cancel();

    try {
      print('\n========================================');
      print('📚 [Desktop] Triggering Library Scanner');
      print('📚 [Desktop] User UID: $uid');
      print('📚 [Desktop] User email: ${_authUser?.email ?? "Prototype Mode"}');
      print('📚 [Desktop] Mode: $mode');
      print('========================================');

      // Get merchant's scan point ID
      final merchantSnap = await FirebaseFirestore.instance
          .collection('scan_points')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (merchantSnap.docs.isEmpty) {
        print('❌ [Desktop] No scan point found for this merchant!');
        throw Exception('No scan point found for this merchant');
      }

      final scanPointData = merchantSnap.docs.first.data();
      final scanPointId = scanPointData['scan_point_id'] as String;
      final scanPointName = scanPointData['name'] as String?;

      print('✅ [Desktop] Found scan point:');
      print('   - ID: $scanPointId');
      print('   - Name: $scanPointName');

      final scanModeValue = mode == 'return'
          ? 'library_return'
          : 'library_borrow';
      print('📚 [Desktop] Scan mode value: $scanModeValue');

      // ✅ Immediately update scanner_status to ACTIVE
      print('📚 [Desktop] Updating scanner_status to ACTIVE...');
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .set({
            'state': 'ACTIVE',
            'status': 'active',
            'updated_at': FieldValue.serverTimestamp(),
          });
      print('✅ [Desktop] Scanner status updated');

      setState(() => _isScannerTriggered = true);

      // 👂 Listen for successful interactions
      final triggerTime = DateTime.now();
      _interactionSubscription?.cancel();
      _interactionSubscription = FirebaseFirestore.instance
          .collection('interactions')
          .where('scan_point_id', isEqualTo: scanPointId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              final data = doc.data();
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              // Check if interaction happened AFTER we triggered the scanner
              if (timestamp != null && timestamp.isAfter(triggerTime)) {
                print('✅ [Desktop] New interaction detected!');
                _interactionSubscription?.cancel(); // Stop listening
                stopMobileScanner(); // Stop scanner
                if (mounted) {
                   _showSuccessDialog(context, data);
                }
              }
            }
          });

      // ⏱️ Start 60s Timeout Timer
      _scannerTimeoutTimer = Timer(const Duration(seconds: 60), () {
        if (mounted && _isScannerTriggered) {
          print('⏰ [Desktop] Scanner timed out after 60s');
          stopMobileScanner();
          // Snackbar removed for Jelly UI
          // ScaffoldMessenger.of(context).showSnackBar(...)
        }
      });

      // ✅ Write Library Mode trigger with specific mode
      print('\n========================================');
      print('📚 [Desktop] About to write trigger...');
      print('   Target path: scanner_triggers/$scanPointId');
      print('   Current time: ${DateTime.now()}');
      print('   Data: {active: true, scan_mode: $scanModeValue}');

      await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .doc(scanPointId)
          .set({
            'active': true,
            'scan_mode': scanModeValue,
            'scan_point_id': scanPointId,
            'triggered_at': FieldValue.serverTimestamp(),
          })
          .then((_) {
            print('✅ [Desktop] Firestore .set() completed successfully!');
          })
          .catchError((error) {
            print('❌ [Desktop] Firestore .set() FAILED: $error');
            throw error;
          });

      _triggeredDocId = scanPointId;
      print('✅ [Desktop] Trigger written successfully!');
      print('   Path: scanner_triggers/$scanPointId');
      print('   Active: true');
      print('   Scan Mode: $scanModeValue');
      print('   Timestamp: ${DateTime.now()}');
      print('========================================\n');

      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    } catch (e) {
      print('❌ [Desktop] Failed to trigger Library Mode: $e');
      _scannerTimeoutTimer?.cancel(); // Cancel timer on error

      // Revert scanner status to IDLE on failure
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .set({
            'state': 'IDLE',
            'status': 'idle',
            'updated_at': FieldValue.serverTimestamp(),
          });

      setState(() => _isScannerTriggered = false);
      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    }
  }

  /// Trigger Access Control Mode on mobile device
  /// This activates the access control scanner for entry verification
  void triggerAccessScanner() async {
    final uid = _uid;
    if (uid == null || _isScannerTriggered) return;

    try {
      // Get merchant's scan point ID
      final merchantSnap = await FirebaseFirestore.instance
          .collection('scan_points')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (merchantSnap.docs.isEmpty) {
        throw Exception('No scan point found for this merchant');
      }

      final scanPointId =
          merchantSnap.docs.first.data()['scan_point_id'] as String;

      print(
        '🔐 [Desktop] Starting Access Control Mode trigger for $scanPointId',
      );

      // ✅ Immediately update scanner_status to ACTIVE
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .set({
            'state': 'ACTIVE',
            'status': 'active',
            'scan_mode': 'access',
            'scan_point_id': scanPointId,
            'triggered_at': FieldValue.serverTimestamp(),
          });

      // ✅ Write UNIFIED trigger to scanner_triggers/{scan_point_id}
      await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .doc(scanPointId)
          .set({
            'active': true,
            'scan_mode': 'access',
            'scan_point_id': scanPointId,
            'triggered_at': FieldValue.serverTimestamp(),
          });

      _triggeredDocId = scanPointId;
      print(
        '🔐 [Desktop] Access Control Mode trigger created for scan point: $scanPointId',
      );

      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    } catch (e) {
      print('❌ [Desktop] Failed to trigger access scanner: $e');
      setState(() => _isScannerTriggered = false);
      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    }
  }

  /// Trigger Event Check-In Mode on mobile device
  /// This activates the event ticket scanner for check-in verification
  void triggerEventScanner({String? eventId, String? eventName}) async {
    final uid = _uid;
    if (uid == null || _isScannerTriggered) return;

    // Update state if arguments provided
    if (eventId != null) {
      setState(() {
        _selectedEventId = eventId;
        _selectedEventName = eventName;
      });
    }

    try {
      // Get merchant's scan point ID
      final merchantSnap = await FirebaseFirestore.instance
          .collection('scan_points')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (merchantSnap.docs.isEmpty) {
        throw Exception('No scan point found for this merchant');
      }

      final scanPointId =
          merchantSnap.docs.first.data()['scan_point_id'] as String;

      print(
        '🎫 [Desktop] Starting Event Check-In Mode trigger for $scanPointId',
      );

      if (_selectedEventId == null) {
        // Try to auto-assign the "APU Tech Talk" event when none selected
        print(
          'dY-� [Desktop] No event selected - attempting auto-assign (APU Tech Talk)...',
        );
        final autoEvent = await _autoAssignDefaultEvent();
        _selectedEventId = autoEvent?['id'];
        _selectedEventName = autoEvent?['name'];
        if (_selectedEventId != null) {
          print(
            '�o. [Desktop] Auto-assigned event: $_selectedEventName ($_selectedEventId)',
          );
        } else {
          print(
            '�s��,? [Desktop] Auto-assign failed; proceeding without event_id',
          );
        }
      }

      // ✅ Immediately update scanner_status to ACTIVE
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .set({
            'state': 'ACTIVE',
            'status': 'active',
            'scan_mode': 'event',
            'scan_point_id': scanPointId,
            // Pass event_id only if selected; mobile can auto-assign when null
            if (_selectedEventId != null) 'event_id': _selectedEventId,
            if (_selectedEventName != null) 'event_name': _selectedEventName,
            'triggered_at': FieldValue.serverTimestamp(),
          });

      // ✅ Write UNIFIED trigger to scanner_triggers/{scan_point_id}
      await FirebaseFirestore.instance
          .collection('scanner_triggers')
          .doc(scanPointId)
          .set({
            'active': true,
            'scan_mode': 'event',
            'scan_point_id': scanPointId,
            if (_selectedEventId != null) 'event_id': _selectedEventId,
            if (_selectedEventName != null) 'event_name': _selectedEventName,
            'triggered_at': FieldValue.serverTimestamp(),
          });

      _triggeredDocId = scanPointId;
      print(
        '🎫 [Desktop] Event Check-In Mode trigger created for scan point: $scanPointId',
      );

      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    } catch (e) {
      print('❌ [Desktop] Failed to trigger Access Control Mode: $e');

      // Revert scanner status to IDLE on failure
      await FirebaseFirestore.instance
          .collection('scanner_status')
          .doc(uid)
          .set({
            'state': 'IDLE',
            'status': 'idle',
            'updated_at': FieldValue.serverTimestamp(),
          });

      setState(() => _isScannerTriggered = false);
      // Snackbar removed for Jelly UI
      // if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...) }
    }
  }

  /// Attempt to auto-assign a default event (APU Tech Talk) when none is selected
  Future<Map<String, String>?> _autoAssignDefaultEvent() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('events')
          .where('name', isEqualTo: 'APU Tech Talk')
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final doc = snap.docs.first;
      final data = doc.data();
      final name = data['name'] as String? ?? 'APU Tech Talk';
      final id = (data['event_id'] as String?) ?? doc.id;

      return {'id': id, 'name': name};
    } catch (e) {
      print('�?O [Desktop] Auto-assign default event failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_uid == null) {
      return Scaffold(
        body: Center(
          child: Text('Not signed in', style: theme.textTheme.titleLarge),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _merchantStream,
          builder: (context, merchantSnap) {
            if (!merchantSnap.hasData || merchantSnap.data!.docs.isEmpty) {
              return const Center(child: Text('Merchant not found'));
            }

            final merchantData = merchantSnap.data!.docs.first.data();
            final merchantId =
                merchantData['scan_point_id'] ??
                merchantData['merchant_id'] ??
                '';
            print(
              '🖥 [Desktop] Loaded Merchant ID (ScanPoint ID): $merchantId',
            );
            final shopName =
                merchantData['name'] ?? merchantData['shop_name'] ?? 'My Shop';

            // Fallback values
            final fallbackScanCount = (merchantData['scan_count'] ?? 0)
                .toString();
            final fallbackTxnCount =
                (merchantData['interaction_count'] ??
                        merchantData['txn_count'] ??
                        0)
                    .toString();
            final fallbackRevenue = merchantData['type'] == 'commerce'
                ? (merchantData['revenue'] ?? 0.0).toDouble()
                : 0.0;
            final lastActive = merchantData['last_active'] is Timestamp
                ? (merchantData['last_active'] as Timestamp).toDate()
                : null;

            // ✅ Dynamically load interactions for this scan point
            final transactionsStream = FirebaseFirestore.instance
                .collection('interactions')
                .where('scan_point_id', isEqualTo: merchantId)
                .orderBy('timestamp', descending: true)
                .snapshots();

            final spType = merchantData['type'] as String? ?? 'commerce';

            // --- Content Builder ---
            Widget buildContent() {
              if (_currentView == 'PROFILE') {
                return CommerceProfileView(merchantData: merchantData);
              }

              switch (spType) {
                case 'library':
                  if (_currentView == 'LIBRARY') {
                    return LibraryView(
                      onTriggerBorrow: () => triggerLibraryScanner(mode: 'borrow'),
                      onTriggerReturn: () => triggerLibraryScanner(mode: 'return'),
                      isTriggered: _isScannerTriggered,
                      isProcessing: _isProcessing,
                      onStop: stopMobileScanner,
                    );
                  }
                  break;

                case 'event':
                  if (_currentView == 'ATTENDANCE') {
                    return AttendanceView(
                      organizerName: shopName,
                      onTriggerAttendance: (eventId, eventName) =>
                          triggerEventScanner(eventId: eventId, eventName: eventName),
                      isTriggered: _isScannerTriggered,
                      isProcessing: _isProcessing,
                      onStop: stopMobileScanner,
                    );
                  }
                  break;

                case 'access':
                  if (_currentView == 'ACCESS') {
                    return AccessView(
                      onTriggerAccess: triggerAccessScanner,
                      isTriggered: _isScannerTriggered,
                      isProcessing: _isProcessing,
                      onStop: stopMobileScanner,
                    );
                  }
                  break;

                case 'commerce':
                  if (_currentView == 'PROFILE') {
                    return CommerceProfileView(merchantData: merchantData);
                  }
                  if (_currentView == 'POS') {
                    return MerchantPOSPage(scanPointId: merchantId);
                  }
                  break;

                default:
              }

              // Fallback if view doesn't match type (shouldn't happen with correct sidebar logic)
              return Center(child: Text('View $_currentView not available for $spType'));
            }

            return Row(
              children: [
                // ✅ New React-style Sidebar
                DesktopSidebar(
                  activeView: _currentView,
                  onNavigate: _onNavigate,
                  onLogout: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil(Routes.login, (route) => false);
                    }
                  },
                  userEmail: _authUser?.email,
                ),

                // --- Main content ---
                Expanded(
                  child: Container(
                    color: const Color(0xFFF3F4F6), // bg-gray-100
                    child: PageTransitionSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation,
                      ) {
                        return FadeThroughTransition(
                          animation: animation,
                          secondaryAnimation: secondaryAnimation,
                          child: child,
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(_currentView),
                        child: buildContent(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7), // green-100
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A), // green-600
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Success!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                data['student_name'] != null
                    ? '${data['student_name']} (${data['student_id'] ?? 'N/A'})'
                    : (data['detail'] ?? 'Operation completed successfully.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}


