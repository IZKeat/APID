import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';

/// 🛡️ Biometric Guard
/// Encapsulates logic for checking session status and enforcing biometric authentication.
/// Follows the Single Responsibility Principle (SRP).
class BiometricGuard {
  final BiometricService _biometricService = BiometricService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Checks the current session status.
  Future<SessionStatus> checkSessionStatus() async {
    final user = _auth.currentUser;
    
    // 1. No active Firebase session
    if (user == null) {
      return SessionStatus.noSession;
    }

    // 2. Check if Biometric Lock is enabled
    final bioEnabled = await _storageService.isBiometricEnabled();
    if (bioEnabled) {
      return SessionStatus.sessionLocked; // 🔒 Requires unlock
    }

    // 3. Session is open (no bio required)
    return SessionStatus.sessionOpen; // 🔓 Auto-enter
  }

  /// Authenticates the user using biometrics.
  /// Returns true if successful.
  Future<bool> authenticate() async {
    try {
      final canCheck = await _biometricService.canCheckBiometrics();
      if (!canCheck) {
        debugPrint("⚠️ Biometric hardware not available or not enrolled.");
        return false;
      }
      return await _biometricService.authenticate();
    } catch (e) {
      debugPrint("❌ Biometric authentication error: $e");
      return false;
    }
  }

  /// Checks if biometrics can be checked (hardware support).
  Future<bool> canCheckBiometrics() async {
    return await _biometricService.canCheckBiometrics();
  }
}

/// Status of the user session
enum SessionStatus {
  /// No user logged in (cold boot)
  noSession,
  
  /// User logged in, but biometric lock is enabled
  sessionLocked,
  
  /// User logged in, no lock enabled
  sessionOpen,
}
