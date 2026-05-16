import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device supports biometrics and if the user has enrolled
  Future<bool> canCheckBiometrics() async {
    try {
      // 🔒 Strict Check: Must have hardware AND enrolled biometrics
      final bool canCheck = await _auth.canCheckBiometrics;
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      
      debugPrint("🔍 Biometric Check: CanCheck=$canCheck, Available=$available");
      
      return canCheck && available.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint("⚠️ Error checking biometrics: $e");
      return false;
    }
  }

  /// Get list of available biometrics
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint("⚠️ Error getting available biometrics: $e");
      return <BiometricType>[];
    }
  }

  /// Authenticate the user
  Future<bool> authenticate() async {
    try {
      final available = await getAvailableBiometrics();
      debugPrint("🔍 Attempting authentication. Available biometrics: $available");

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("⚠️ Authentication error: Code=${e.code}, Message=${e.message}, Details=${e.details}");
      return false;
    } catch (e) {
      debugPrint("⚠️ Unknown Authentication error: $e");
      return false;
    }
  }
}
