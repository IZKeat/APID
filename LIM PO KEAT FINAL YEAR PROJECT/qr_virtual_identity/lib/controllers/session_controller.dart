import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';

class SessionController extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  
  // 🆕 Custom message for session expiry dialog (e.g. "Password Changed")
  String? _customKickoutMessage;
  String? get customKickoutMessage => _customKickoutMessage;

  void setKickoutMessage(String? message) {
    _customKickoutMessage = message;
  }

  // State to control listener execution (prevent race conditions during login)
  bool _isPaused = false;

  void setPaused(bool paused) {
    _isPaused = paused;
    if (paused) {
      stopSessionListener();
    }
    debugPrint("📱 Session Listener Paused: $paused");
  }

  // Start listening to session changes
  void startSessionListener(String uid) {
    // 🛑 Guard: If paused (e.g. during login process), do not start
    if (_isPaused) {
      debugPrint("📱 Session Listener start blocked (Paused)");
      return;
    }

    // Cancel any existing listener to prevent duplicates
    stopSessionListener();

    debugPrint("📱 Starting Session Listener for UID: $uid");

    // 🕵️‍♂️ Dynamic Collection Lookup
    // We don't know if the user is in 'users' or 'admins' just from UID.
    // We'll try 'users' first (most common), and if it doesn't exist, we'll try 'admins'.
    // Ideally, we should know the role, but AuthStateChanges only gives us User.
    
    _startListeningToCollection(uid, 'users');
  }

  void _startListeningToCollection(String uid, String collection) {
    _sessionSubscription = FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      
      // 1. If doc doesn't exist in 'users', try 'admins' (only if we haven't tried yet)
      if (!snapshot.exists) {
        if (collection == 'users') {
           debugPrint("⚠️ User not found in 'users', checking 'admins'...");
           _sessionSubscription?.cancel(); // Stop this listener
           _startListeningToCollection(uid, 'admins'); // Switch to admins
        }
        return;
      }

      final data = snapshot.data();
      if (data == null) return;

      // 🕵️‍♂️ Determine Platform for Session Check
      String sessionField = 'current_session_id'; // Fallback
      if (kIsWeb) {
        sessionField = 'session_id_desktop';
      } else if (Platform.isAndroid || Platform.isIOS) {
        sessionField = 'session_id_mobile';
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        sessionField = 'session_id_desktop';
      }

      if (!data.containsKey(sessionField)) {
        // If the new field doesn't exist yet (e.g. old user record), ignore or fallback
        // Ideally, we should check 'current_session_id' as legacy fallback if needed,
        // but for strict separation, we wait for a new login to set the field.
        return;
      }

      final remoteSessionId = data[sessionField] as String?;
      final localSessionId = await _storageService.getSessionId();

      if (remoteSessionId != null) {
        // FIX: If remote has a session ID, we must match it.
        // If local is null, we assume login is in progress and skip the check.
        if (localSessionId != null && remoteSessionId != localSessionId) {
          
          // 🛑 Race Condition Fix: Double Check
          // Sometimes Firestore updates faster than local storage during login.
          // We wait 500ms and check again to be sure it's not a false positive.
          await Future.delayed(const Duration(milliseconds: 500));
          final recheckLocalSessionId = await _storageService.getSessionId();

          if (recheckLocalSessionId == null || remoteSessionId != recheckLocalSessionId) {
             debugPrint("⚠️ Session Invalid (Confirmed)! Remote: $remoteSessionId, Local: $recheckLocalSessionId");
             
             // 🆕 Check Kickout Reason
             final kickoutReason = data['kickout_reason'] as String?;
             if (kickoutReason == 'password_changed') {
               setKickoutMessage("Password changed successfully.\nPlease login again with your new password.");
             } else {
               setKickoutMessage(null); // Use default "Logged in on another device"
             }

             _handleForceLogout();
          } else {
            debugPrint("✅ Session Valid after re-check (Race condition avoided).");
          }
        }
      }
    }, onError: (error) {
      debugPrint("❌ Session Listener Error ($collection): $error");
    });
  }

  // Stop listening
  void stopSessionListener() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    debugPrint("📱 Session Listener Stopped");
  }

  // Handle Force Logout
  Future<void> _handleForceLogout() async {
    // Stop listener to prevent loops
    stopSessionListener();

    // Notify UI (This will be handled by a global listener or callback)
    notifyListeners(); 
  }
}
