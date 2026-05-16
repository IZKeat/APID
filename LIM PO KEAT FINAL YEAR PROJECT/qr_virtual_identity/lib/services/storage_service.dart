import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Secure storage instance
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyBiometricToken = 'biometric_token';

  static const String _keyBiometricPromptDismissed = 'biometric_prompt_dismissed';

  // 📖 User Guide Keys
  static const String keyGuideOnboarding = 'guide_onboarding_completed';
  static const String keyGuideSecurity = 'guide_security_completed';
  static const String keyGuideEvents = 'guide_events_completed';
  static const String keyGuideLevel = 'guide_level'; // 🎮 Gamification Level (0-3)

  /// Save ONLY email for "Remember Me"
  Future<void> saveRememberMeEmail(String email) async {
    try {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyRememberMe, value: 'true');
      // Ensure password is NOT stored for simple Remember Me
      await _storage.delete(key: _keyPassword); 
      debugPrint('📧 Remember Me: Email saved (Password removed)');
    } catch (e) {
      debugPrint('❌ Failed to save email: $e');
    }
  }

  /// Save full credentials securely (ONLY for Biometric)
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _storage.write(key: _keyEmail, value: email);
      await _storage.write(key: _keyPassword, value: password);
      debugPrint('🔐 Biometric Credentials saved securely');
    } catch (e) {
      debugPrint('❌ Failed to save biometric credentials: $e');
      rethrow;
    }
  }

  /// Retrieve Remember Me Email
  Future<String?> getRememberMeEmail() async {
    try {
      final rememberMe = await _storage.read(key: _keyRememberMe);
      if (rememberMe != 'true') return null;
      return await _storage.read(key: _keyEmail);
    } catch (e) {
      return null;
    }
  }

  /// Retrieve Biometric Credentials
  Future<Map<String, String>?> getBiometricCredentials() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all credentials
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyPassword);
      await _storage.delete(key: _keyRememberMe);
      debugPrint('🧹 Credentials cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear credentials: $e');
      rethrow;
    }
  }

  // 🚀 Onboarding Prompt Logic
  
  Future<void> setBiometricPromptDismissed(bool dismissed) async {
    await _storage.write(key: _keyBiometricPromptDismissed, value: dismissed.toString());
  }

  Future<bool> isBiometricPromptDismissed() async {
    final val = await _storage.read(key: _keyBiometricPromptDismissed);
    return val == 'true';
  }

  /// Check if "Remember Me" is enabled
  Future<bool> isRememberMeEnabled() async {
    final val = await _storage.read(key: _keyRememberMe);
    return val == 'true';
  }


  // 👆 Biometric Storage Logic

  /// Enable or Disable Biometric Login
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
    if (!enabled) {
      await _storage.delete(key: _keyBiometricToken);
    }
  }

  /// Check if Biometric Login is enabled
  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  /// Save Biometric Token (e.g., UUID or Encrypted UID)
  Future<void> setBiometricToken(String token) async {
    await _storage.write(key: _keyBiometricToken, value: token);
  }

  /// Get Biometric Token
  Future<String?> getBiometricToken() async {
    return await _storage.read(key: _keyBiometricToken);
  }
  // ⚙️ App Preferences Storage

  static const String _keyDarkMode = 'dark_mode';
  static const String _keyPushEnabled = 'push_enabled';
  static const String _keyEmailEnabled = 'email_enabled';

  Future<void> setDarkMode(bool enabled) async {
    await _storage.write(key: _keyDarkMode, value: enabled.toString());
  }

  Future<bool> isDarkMode() async {
    final val = await _storage.read(key: _keyDarkMode);
    return val == 'true';
  }

  Future<void> setPushEnabled(bool enabled) async {
    await _storage.write(key: _keyPushEnabled, value: enabled.toString());
  }

  Future<bool> isPushEnabled() async {
    final val = await _storage.read(key: _keyPushEnabled);
    // Default to true if not set
    return val == null ? true : val == 'true';
  }

  Future<void> setEmailEnabled(bool enabled) async {
    await _storage.write(key: _keyEmailEnabled, value: enabled.toString());
  }

  Future<bool> isEmailEnabled() async {
    final val = await _storage.read(key: _keyEmailEnabled);
    return val == 'true';
  }

  // 📍 Scan Point Caching (Offline Resilience)
  static const String _keyLastScanPointId = 'last_scan_point_id';
  static const String _keyLastScanPointName = 'last_scan_point_name';
  static const String _keyLastScanPointType = 'last_scan_point_type';

  Future<void> saveLastScanPoint({
    required String id,
    required String name,
    required String type,
  }) async {
    await _storage.write(key: _keyLastScanPointId, value: id);
    await _storage.write(key: _keyLastScanPointName, value: name);
    await _storage.write(key: _keyLastScanPointType, value: type);
  }

  Future<Map<String, String>?> getLastScanPoint() async {
    final id = await _storage.read(key: _keyLastScanPointId);
    final name = await _storage.read(key: _keyLastScanPointName);
    final type = await _storage.read(key: _keyLastScanPointType);

    if (id != null && name != null && type != null) {
      return {
        'scan_point_id': id,
        'name': name,
        'type': type,
      };
    }
    return null;
  }
  // 📱 Session Management (Single Device Login)
  static const String _keySessionId = 'current_session_id';

  Future<void> saveSessionId(String sessionId) async {
    await _storage.write(key: _keySessionId, value: sessionId);
    debugPrint('📱 Session ID saved: $sessionId');
  }

  Future<String?> getSessionId() async {
    return await _storage.read(key: _keySessionId);
  }

  Future<void> clearSessionId() async {
    await _storage.delete(key: _keySessionId);
    debugPrint('📱 Session ID cleared');
  }

  // 📖 User Guide Persistence

  /// Check if a specific guide has been completed
  Future<bool> isGuideCompleted(String key) async {
    final val = await _storage.read(key: key);
    return val == 'true';
  }

  /// Mark a specific guide as completed
  Future<void> completeGuide(String key) async {
    await _storage.write(key: key, value: 'true');
    debugPrint('✅ Guide completed: $key');
  }

  /// Reset all guides (for testing or "Reset Tips" feature)
  Future<void> resetGuides() async {
    await _storage.delete(key: keyGuideOnboarding);
    await _storage.delete(key: keyGuideSecurity);
    await _storage.delete(key: keyGuideEvents);
    await _storage.delete(key: keyGuideLevel); // Reset Level
    debugPrint('🔄 User Guides reset');
  }

  /// Get current Guide Level (0 = New User)
  Future<int> getGuideLevel() async {
    final val = await _storage.read(key: keyGuideLevel);
    return int.tryParse(val ?? '0') ?? 0;
  }

  /// Set Guide Level
  Future<void> setGuideLevel(int level) async {
    await _storage.write(key: keyGuideLevel, value: level.toString());
    debugPrint('🎮 Guide Level updated: $level');
  }
}
