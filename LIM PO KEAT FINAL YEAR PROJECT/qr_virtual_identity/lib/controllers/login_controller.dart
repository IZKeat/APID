import 'dart:io';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../guards/biometric_guard.dart';
import '../utils/auth_exception_handler.dart';

class LoginController extends ChangeNotifier {
  final UserRepository _userRepository;
  final StorageService _storageService;
  final BiometricGuard _biometricGuard;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  LoginController({
    UserRepository? userRepository,
    StorageService? storageService,
    BiometricGuard? biometricGuard,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _userRepository = userRepository ?? UserRepository(),
        _storageService = storageService ?? StorageService(),
        _biometricGuard = biometricGuard ?? BiometricGuard(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // State Variables
  bool _isLoading = false;
  bool _isLoginSuccess = false;
  bool _isGoogleSignIn = false;
  bool _rememberMe = false;
  bool _canCheckBiometrics = false;
  bool _isPasswordVisible = false;

  // 🛡️ Validation Helpers (Poka-Yoke)
  bool _isValidEmail(String email) {
    // Standard Regex for Email Validation
    final emailRegex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    // Firebase defaults to 6 chars
    return password.length >= 6;
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoginSuccess => _isLoginSuccess;
  bool get isGoogleSignIn => _isGoogleSignIn;
  bool get rememberMe => _rememberMe;
  bool get canCheckBiometrics => _canCheckBiometrics;
  bool get isPasswordVisible => _isPasswordVisible;
  
  // 🛡️ Lockout State
  DateTime? _lockoutEndTime;
  DateTime? get lockoutEndTime => _lockoutEndTime;

  // Setters
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  // 🔄 Check Session & Biometrics
  Future<void> checkSessionAndBiometrics({
    required Function(User) onSessionOpen,
    required Function() onBiometricAuthRequired,
    required Function(String email, String password) onLoadCredentials,
  }) async {
    final sessionStatus = await _biometricGuard.checkSessionStatus();

    switch (sessionStatus) {
      case SessionStatus.sessionLocked:
        // 🔒 Session Locked: Require Biometric Unlock
        debugPrint("🔒 Session active, requiring biometric unlock");
        _canCheckBiometrics = true;
        _rememberMe = true;
        notifyListeners();
        
        // Trigger biometric auth callback
        onBiometricAuthRequired();
        break;

      case SessionStatus.sessionOpen:
        // 🔓 Session Open: Auto-enter
        debugPrint("🔓 Session active, auto-entering");
        final user = _auth.currentUser;
        if (user != null) {
          onSessionOpen(user);
        }
        break;

      case SessionStatus.noSession:
        // 2. No Session: Load saved email only (Strict Remember Me)
        await _loadCredentials(onLoadCredentials);

        // ⚡ Proactive Auth: If biometrics enabled & hardware supported, TRIGGER IMMEDIATELY
        if (_canCheckBiometrics) {
           debugPrint("⚡ Proactive Auth: Auto-triggering biometrics for seamless entry");
           onBiometricAuthRequired();
        }
        break;
    }
  }

  // 💾 Load Credentials (Email Only for UI)
  Future<void> _loadCredentials(Function(String, String) onLoad) async {
    try {
      final savedEmail = await _storageService.getRememberMeEmail();
      
      if (savedEmail != null) {
        // Only pre-fill email. Password is empty.
        onLoad(savedEmail, '');
        _rememberMe = true;
        
        // Check biometrics availability
        // Only show if user has explicitly ENABLED it in settings
        final bioEnabled = await _storageService.isBiometricEnabled();
        final hardwareSupport = await _biometricGuard.canCheckBiometrics();
        
        _canCheckBiometrics = bioEnabled && hardwareSupport;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠️ Failed to load credentials: $e");
    }
  }

  // 🛠️ Check if Biometric Onboarding should be shown
  Future<bool> shouldShowBiometricOnboarding() async {
    final bioEnabled = await _storageService.isBiometricEnabled();
    final hardwareSupport = await _biometricGuard.canCheckBiometrics();
    // Show if hardware supports it BUT user hasn't enabled it yet
    return hardwareSupport && !bioEnabled;
  }

  // 🔄 Helper: Update Session ID & Sync
  Future<void> _updateSessionAndSync(User user, {bool updateLocal = true, String? kickoutReason}) async {
    // 📱 Single Device Login: Generate & Save Session ID
    final sessionId = const Uuid().v4();
    
    // 📝 3. UPDATE REMOTE: Write to Firestore FIRST
    // If this fails (e.g. permission denied), we throw error and DO NOT update local.
    
    // FIX: Determine collection based on email to avoid creating "shadow" users
    // If email contains 'admin', we assume they are an admin and write to 'admins' collection.
    final isLikelyAdmin = user.email != null && user.email!.toLowerCase().contains('admin');
    final collectionPath = isLikelyAdmin ? 'admins' : 'users';

    // 🕵️‍♂️ Determine Platform for Session Split
    String sessionField = 'current_session_id'; // Fallback
    if (kIsWeb) {
      sessionField = 'session_id_desktop'; // Treat Web as Desktop
    } else if (Platform.isAndroid || Platform.isIOS) {
      sessionField = 'session_id_mobile';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      sessionField = 'session_id_desktop';
    }

    debugPrint("📱 Updating Session for Platform Field: $sessionField");

    await _firestore.collection(collectionPath).doc(user.uid).set({
      sessionField: sessionId,
      'last_login_at': FieldValue.serverTimestamp(),
      'kickout_reason': kickoutReason, // 🆕 Reason for session invalidation (nullable)
    }, SetOptions(merge: true));
    
    // 📝 4. UPDATE LOCAL: Write to Local Storage SECOND
    // Only reached if remote update succeeded.
    if (updateLocal) {
      await _storageService.saveSessionId(sessionId);
      debugPrint("📱 New Session ID generated and synced (Local+Remote): $sessionId");
    } else {
      debugPrint("📱 New Session ID generated (Remote Only): $sessionId");
    }
  }

  // 👆 Authenticate with Biometrics
  Future<void> authenticateWithBiometrics({
    required Function(User) onSuccess,
    required Function(String) onError,
    required String currentEmail,
    required String currentPassword,
    required Function() onManualLoginRequired,
    required Function() onStopSessionListener,
    required Function() onStartSessionListener,
    bool updateSession = true, // 🆕 Flag to control session update
  }) async {
    try {
      final authenticated = await _biometricGuard.authenticate();
      
      if (authenticated) {
        debugPrint("👆 Biometric authentication successful");
        
        // 🛑 1. PAUSE LISTENER: Prevent "Self-Kick" race condition
        onStopSessionListener();

        try {
          final user = _auth.currentUser;
          if (user != null) {
            // 🔓 Session Unlock Success (Already logged in)
            if (updateSession) {
              await _updateSessionAndSync(user);
            }
            onSuccess(user);
          } else {
            // ⚠️ Cold Boot with Biometrics
            final credentials = await _storageService.getBiometricCredentials();
            final storedEmail = credentials?['email'];
            final storedPassword = credentials?['password'];

            if (storedEmail != null && storedPassword != null) {
               debugPrint("🔄 Attempting silent login with secure credentials...");
               final credential = await _auth.signInWithEmailAndPassword(
                 email: storedEmail,
                 password: storedPassword,
               );
               if (credential.user != null) {
                  debugPrint("✅ Silent login successful");
                  if (updateSession) {
                    await _updateSessionAndSync(credential.user!);
                  }
                  onSuccess(credential.user!);
               } else {
                 throw Exception("Silent login failed");
               }
            } else {
              debugPrint("⚠️ No secure credentials found for biometric login");
              onManualLoginRequired();
            }
          }
        } catch (e) {
          debugPrint("❌ Biometric login error: $e");
          onManualLoginRequired();
        } finally {
          // ▶️ 5. RESUME LISTENER: Always restart protection
          onStartSessionListener();
        }
      }
    } on PlatformException catch (e) {
      debugPrint("❌ Biometric Platform Exception: ${e.code} - ${e.message}");
      // 🛡️ Poka-Yoke 1: Biometric Key Invalidated (Self-Healing)
      if (e.code == 'PermanentlyInvalidated' || e.code.contains('KeyPermanentlyInvalidated')) {
         await _storageService.setBiometricEnabled(false);
         await _storageService.clearCredentials();
         onError('Security Changed: Biometrics disabled. Please login with password to re-enable.');
         onManualLoginRequired();
         return;
      }
      // 🛡️ Poka-Yoke 2: Lockout (Too many attempts)
      if (e.code == 'Lockout' || e.code == 'LockedOut') {
         onError('Too many attempts. Switching to Password...');
         onManualLoginRequired(); // Fallback to password
         return;
      }
      onManualLoginRequired();
    } catch (e) {
      debugPrint("❌ Generic Biometric Error: $e");
      onManualLoginRequired();
    }
  }

  // 📧 Email/Password Login
  Future<void> loginUser({
    required String email,
    required String password,
    required Function(User) onSuccess,
    required Function(String) onError,
    required Function() onStopSessionListener,
    required Function() onStartSessionListener,
  }) async {
    if (_isLoading) return;

    // 🛡️ 0.1 Poka-Yoke: Network Awareness
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      onError('No internet connection. Please check your network.'); // 🌐 Offline Check
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      onError('Please enter email and password');
      return;
    }

    // 🛡️ 0.5 Poka-Yoke: Client-Side Validation
    if (!_isValidEmail(email)) {
       onError('Invalid email format. Please check your email.'); // 📧 "Anti-Stupidity" Check
       return;
    }

    if (!_isValidPassword(password)) {
       onError('Password must be at least 6 characters.'); // 🔑 "Anti-Stupidity" Check
       return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 🛑 1. PAUSE LISTENER: Prevent "Self-Kick" race condition
      // We must stop the listener BEFORE we start the login process, 
      // because auth state changes might trigger the global wrapper to restart it.
      onStopSessionListener();

      // 🛡️ 1.5 Rate Limit Check
      await _checkLoginLockout(email.trim());

      // 🔑 2. ACTION: Perform Login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception("Login failed");

      // ✅ Login Success: Reset Attempts
      await _resetLoginAttempts(email.trim());

      // 💾 Save or Clear Credentials
      await _handleRememberMe(email, password);

      // 📝 3 & 4. UPDATE SESSION (Remote + Local)
      await _updateSessionAndSync(user);

      // ✅ Login Success State
      _isLoading = false;
      _isLoginSuccess = true;
      notifyListeners();

      // Callback for UI animation or routing
      onSuccess(user);

    } catch (e) {
      debugPrint("❌ Login error: $e");
      _isLoading = false;
      _isLoginSuccess = false;
      notifyListeners();
      
      // 🛡️ Record Failure & Check for Lockout
      if (e is FirebaseAuthException && (e.code == 'wrong-password' || e.code == 'user-not-found' || e.code == 'invalid-credential')) {
         await _recordLoginFailure(email.trim());
      }

      final errorMessage = AuthExceptionHandler.handleException(e);
      onError(errorMessage);
    } finally {
      // ▶️ 5. RESUME LISTENER: Always restart protection
      // Even if login failed, we must re-enable the listener (though user might be null)
      onStartSessionListener();
    }
  }

  // 🛡️ Rate Limiting: Check Lockout
  Future<void> _checkLoginLockout(String email) async {
    try {
      final doc = await _firestore.collection('login_attempts').doc(email).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final lockoutUntil = data['lockout_until'] as Timestamp?;

      if (lockoutUntil != null) {
        final now = DateTime.now();
        final unlockTime = lockoutUntil.toDate();

        if (now.isBefore(unlockTime)) {
          _lockoutEndTime = unlockTime; // 🕒 Set Lockout State
          notifyListeners();
          
          final remaining = unlockTime.difference(now);
          final seconds = remaining.inSeconds;
          throw FirebaseAuthException(
            code: 'too-many-requests',
            message: 'Too many failed attempts. Please try again in $seconds seconds.',
          );
        } else {
           // Lockout expired
           _lockoutEndTime = null;
           notifyListeners();
        }
      }
    } catch (e) {
      if (e is FirebaseAuthException) rethrow;
      debugPrint("⚠️ Rate limit check failed: $e");
    }
  }

  // 🛡️ Rate Limiting: Record Failure
  Future<void> _recordLoginFailure(String email) async {
    try {
      final ref = _firestore.collection('login_attempts').doc(email);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(ref);
        
        int attempts = 0;
        Timestamp? lastAttemptTimestamp;

        if (doc.exists) {
          final data = doc.data()!;
          attempts = data['attempts'] ?? 0;
          final rawTimestamp = data['last_attempt_at'];
          if (rawTimestamp is Timestamp) {
            lastAttemptTimestamp = rawTimestamp;
          } else if (rawTimestamp is DateTime) {
            lastAttemptTimestamp = Timestamp.fromDate(rawTimestamp);
          }
        }

        // 🕒 Time-Based Reset Logic
        // If the user hasn't failed in the last 15 minutes, we treat this as a fresh start.
        // This prevents "permanent" lockouts for users who make occasional typos over days.
        if (lastAttemptTimestamp != null) {
          final lastAttemptTime = lastAttemptTimestamp.toDate();
          final timeDifference = DateTime.now().difference(lastAttemptTime);
          debugPrint("🕒 Time diff: ${timeDifference.inMinutes} mins");
          
          if (timeDifference.inMinutes > 15) {
             debugPrint("🕒 Login attempts reset due to inactivity (>15 mins)");
             attempts = 0; // Reset counter
          }
        }

        attempts++;
        
        DateTime? lockoutUntil;
        
        // Exponential Backoff Logic
        // 5 fails -> 30s
        // 10 fails -> 60s
        // 15 fails -> 120s
        // 20 fails -> 240s
        if (attempts >= 5 && attempts % 5 == 0) {
           final multiplier = (attempts / 5).floor() - 1; // 0, 1, 2...
           // 30 * 2^0 = 30
           // 30 * 2^1 = 60
           // 30 * 2^2 = 120
           final lockoutSeconds = 30 * (1 << multiplier); 
           lockoutUntil = DateTime.now().add(Duration(seconds: lockoutSeconds));
           
           // 🕒 Update Local State Immediately
           _lockoutEndTime = lockoutUntil;
           notifyListeners();
           
           debugPrint("🔒 Lockout triggered! Attempts: $attempts, Duration: ${lockoutSeconds}s");
        }

        transaction.set(ref, {
          'attempts': attempts,
          'last_attempt_at': FieldValue.serverTimestamp(),
          'lockout_until': lockoutUntil != null ? Timestamp.fromDate(lockoutUntil) : null,
        }, SetOptions(merge: true));
      });

    } catch (e) {
      debugPrint("⚠️ Failed to record login failure: $e");
    }
  }

  // 🛡️ Rate Limiting: Reset
  Future<void> _resetLoginAttempts(String email) async {
    try {
      await _firestore.collection('login_attempts').doc(email).delete();
    } catch (e) {
      debugPrint("⚠️ Failed to reset login attempts: $e");
    }
  }

  // 🌐 Google Sign-In
  Future<void> signInWithGoogle({
    required Function(User) onSuccess,
    required Function(String) onError,
  }) async {
    _isGoogleSignIn = true;
    notifyListeners();

    try {
      final userCredential = await AuthService.signInWithGoogle();
      if (userCredential == null) {
        onError('Google Sign-In cancelled.');
        return;
      }

      final user = userCredential.user;
      if (user == null) throw Exception("Google Sign-In failed");

      // 📱 Single Device Login: Generate & Save Session ID
      // We use the centralized helper to ensure consistency (Remote First + Kickout Reason Reset)
      await _updateSessionAndSync(user);

      onSuccess(user);

    } catch (e) {
      debugPrint("❌ Google Sign-In error: $e");
      final errorMessage = AuthExceptionHandler.handleException(e);
      onError(errorMessage);
    } finally {
      _isGoogleSignIn = false;
      notifyListeners();
    }
  }

  // 💾 Handle Remember Me Logic
  Future<void> _handleRememberMe(String email, String password) async {
    try {
      if (_rememberMe) {
        // 1. Always save email for UI "Remember Me"
        await _storageService.saveRememberMeEmail(email.trim());

        // 2. If Biometrics are ENABLED, also save secure credentials for silent login
        final bioEnabled = await _storageService.isBiometricEnabled();
        if (bioEnabled) {
          await _storageService.saveBiometricCredentials(
            email: email.trim(),
            password: password.trim(),
          );
        }
      } else {
        await _storageService.clearCredentials();
      }
    } catch (e) {
      debugPrint("⚠️ Failed to save credentials: $e");
    }
  }

  // 🧭 Routing Logic (Helper to determine where to go)
  Future<void> handleUserRouting(User user, {
    required Function(String route) onNavigate,
    required Function(String uid, UserModel userModel) onMerchantRoute,
    required Function(String) onError,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final userModel = await _userRepository.getUserData(user.email!, uid: user.uid);

      if (userModel == null) {
        throw Exception("User record not found in Firestore");
      }

      debugPrint("👤 Logged in as ${userModel.email} | Role: ${userModel.role}");

      if (userModel.isAdmin) {
        // Use a string constant or enum for routes if possible, but string is fine here
        onNavigate('/admin_dashboard'); // Routes.adminDashboard
      } else if (userModel.isStudent || userModel.isLecturer || userModel.isGuest) {
        onNavigate('/home'); // Routes.home
      } else if (userModel.isMerchant) {
        onMerchantRoute(user.uid, userModel);
      } else {
        throw Exception("Unknown role: ${userModel.role}");
      }
    } catch (e) {
      debugPrint("❌ Routing error: $e");
      
      // 🛠️ Self-Healing: Attempt to fix "Unknown Role"
      if (e.toString().contains("Unknown role") || e.toString().contains("User record not found")) {
         debugPrint("🚑 Attempting Self-Healing for User: ${user.email}");
         try {
           String? newRole;
           String? scanPointId;
           
           final email = user.email?.toLowerCase() ?? '';
           
           if (email.contains('admin')) {
             newRole = 'admin';
           } else if (email.startsWith('sp')) {
             newRole = 'merchant';
             // Extract scan point id (e.g. sp001 from sp001@test.com)
             scanPointId = email.split('@')[0];
           } else if (email.contains('student')) {
             newRole = 'student';
           } else if (email.contains('lecturer')) {
             newRole = 'lecturer';
           }

           if (newRole != null) {
             debugPrint("🔧 Fixing role to: $newRole");
             final data = {
               'email': user.email,
               'role': newRole,
               'updated_at': FieldValue.serverTimestamp(),
             };
             
             if (scanPointId != null) {
               data['scan_point_id'] = scanPointId;
             }

             // Update Firestore (User might need to be in 'admins' or 'users')
             // For simplicity, we put everyone in 'users' first, unless it's strictly admin
             // But UserRepository checks 'admins' too.
             
             if (newRole == 'admin') {
                await _firestore.collection('admins').doc(user.uid).set(data, SetOptions(merge: true));
             } else {
                await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
             }
             
             // Retry Routing
             debugPrint("🔄 Retrying routing after fix...");
             final userModel = await _userRepository.getUserData(user.email!, uid: user.uid);
             if (userModel != null) {
                if (userModel.isAdmin) {
                  onNavigate('/admin_dashboard');
                } else if (userModel.isStudent || userModel.isLecturer || userModel.isGuest) {
                  onNavigate('/home');
                } else if (userModel.isMerchant) {
                  onMerchantRoute(user.uid, userModel);
                }
                return; // Success!
             }
           }
         } catch (fixError) {
           debugPrint("❌ Self-Healing Failed: $fixError");
         }
      }

      final errorMessage = AuthExceptionHandler.handleException(e);
      onError(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 📧 Send Password Reset Email
  Future<void> sendPasswordResetEmail({
    required String email,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    if (_isLoading) return;

    if (email.isEmpty) {
      onError('Please enter your email address');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.sendPasswordResetEmail(email.trim());
      onSuccess();
    } catch (e) {
      debugPrint("❌ Password Reset error: $e");
      final errorMessage = AuthExceptionHandler.handleException(e);
      onError(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Merchant Specific Routing Logic
  Future<void> routeMerchantByScanPointType(
    String uid,
    UserModel userModel, {
    required Function(String route) onNavigate,
    required Function(String message) onShowMessage,
    required bool isWeb,
    required bool isDesktop,
  }) async {
      try {
      final scanPointId = userModel.scanPointId;

      if (scanPointId == null || scanPointId.isEmpty) {
        throw Exception('Merchant user has no scan_point_id assigned');
      }

      if (_userRepository.isScanPointBlacklisted(scanPointId)) {
        await _auth.signOut();
        onShowMessage('Access Denied: Merchant $scanPointId is temporarily disabled.');
        return;
      }

      final scanPointData = await _userRepository.getScanPoint(scanPointId);

      if (scanPointData == null) {
        throw Exception('Scan point $scanPointId not found');
      }

      if (isDesktop) {
         // Routes.merchantDashboardDesktop (Assuming this is the route name or handling it in UI)
         // Since the original code pushed a MaterialPageRoute, we might need to handle that in UI
         // For now, let's assume we pass a route string or a callback
         onNavigate('MERCHANT_DESKTOP'); 
      } else if (isWeb) {
         onShowMessage('QR Scanner is disabled on Web. Please use desktop or mobile app.');
      } else {
         onNavigate('/mobile_scanner_terminal'); // Routes.mobileScannerTerminal
      }

    } on FirebaseException catch (e) {
      String errorMessage;
      if (e.code == 'unavailable') {
        errorMessage = 'Database unavailable. Please ensure Firestore Emulator is running.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Check Firestore security rules.';
      } else {
        errorMessage = 'Database error: ${e.message}';
      }
      onShowMessage(errorMessage);
    } catch (e) {
      final errorMessage = AuthExceptionHandler.handleException(e);
      onShowMessage(errorMessage);
    }
    }

  // 🔐 OTP: Send Code
  Future<void> sendOtp({
    required String email,
    required Function() onSuccess,
    required Function(String) onError,
    Function(String)? onMessage,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _callCloudFunction('sendOtp', {'email': email});
      if (result != null && result['devOtp'] != null) {
        debugPrint("🔐 [DEV MODE] OTP: ${result['devOtp']}");
        if (onMessage != null) {
          onMessage("DEV OTP: ${result['devOtp']}");
        }
      }
      onSuccess();
    } catch (e) {
      debugPrint("❌ Send OTP error: $e");
      String message = e.toString();
      if (e is FirebaseFunctionsException) {
        message = e.message ?? e.code;
      }
      onError(message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔐 OTP: Verify Code
  Future<void> verifyOtp({
    required String email,
    required String code,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _callCloudFunction('verifyOtp', {'email': email, 'code': code});
      onSuccess();
    } catch (e) {
      debugPrint("❌ Verify OTP error: $e");
      String message = e.toString();
      if (e is FirebaseFunctionsException) {
        message = e.message ?? e.code;
      }
      onError(message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔐 OTP: Reset Password
  Future<void> resetPasswordWithOtp({
    required String email,
    required String newPassword,
    required String code,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _callCloudFunction('resetPassword', {
        'email': email,
        'newPassword': newPassword,
        'code': code,
      });
      onSuccess();
    } catch (e) {
      debugPrint("❌ Reset Password error: $e");
      String message = e.toString();
      if (e is FirebaseFunctionsException) {
        message = e.message ?? e.code;
      }
      onError(message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🔐 Update Password (for Biometric Flow)
  Future<void> updatePassword({
    required String newPassword,
    required Function() onSuccess,
    required Function(String) onError,
    bool logoutOthers = true, // 🆕 Force logout other devices by rotating session
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'User not logged in');
      }
      
      // 1. Update Password
      await user.updatePassword(newPassword);
      
      // 2. Rotate Session ID (Force Logout Others)
      // 2. Rotate Session ID (Force Logout Others)
      if (logoutOthers) {
        debugPrint("🔐 Password updated. Rotating session ID to logout other devices...");
        
        // 🗑️ Clear Biometric Credentials (Force Manual Re-login)
        // If Remember Me is ON, we downgrade to just Email. If OFF, we clear all.
        if (_rememberMe && user.email != null) {
          await _storageService.saveRememberMeEmail(user.email!);
          debugPrint("🔐 Biometric credentials cleared (Downgraded to Email-only)");
        } else {
          await _storageService.clearCredentials();
          debugPrint("🔐 All credentials cleared");
        }

        // 🛑 CRITICAL: We pass updateLocal: false to ensure THIS device also gets "kicked"
        // by the session listener (Remote != Local).
        // We also set kickoutReason to 'password_changed' so other devices show correct message.
        await _updateSessionAndSync(
          user, 
          updateLocal: false, 
          kickoutReason: 'password_changed'
        );
      }
      
      onSuccess();
    } catch (e) {
      debugPrint("❌ Update Password error: $e");
      final message = AuthExceptionHandler.handleException(e);
      onError(message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🌐 Helper: Call Cloud Function (REST Fallback for Windows)
  Future<dynamic> _callCloudFunction(String functionName, Map<String, dynamic> data) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      // Use standard plugin for supported platforms
      final callable = FirebaseFunctions.instance.httpsCallable(functionName);
      final result = await callable.call(data);
      return result.data;
    } else {
      // 🖥️ Windows/Linux: Use REST API
      try {
        final url = Uri.parse('https://us-central1-po-keat-fyp.cloudfunctions.net/$functionName');
        final client = HttpClient();
        final request = await client.postUrl(url);
        request.headers.set('Content-Type', 'application/json');
        request.write(jsonEncode({'data': data}));
        
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();
        
        if (response.statusCode != 200) {
           // Try to parse error
           try {
              final errorJson = jsonDecode(responseBody);
              if (errorJson['error'] != null) {
                 throw FirebaseFunctionsException(
                   code: 'unknown',
                   message: errorJson['error']['message'] ?? 'Unknown error',
                 );
              }
           } catch (_) {}
           throw FirebaseFunctionsException(
              code: 'internal', 
              message: 'Server returned ${response.statusCode}: $responseBody'
           );
        }
        
        final json = jsonDecode(responseBody);
        if (json['error'] != null) {
           throw FirebaseFunctionsException(
              code: 'unknown',
              message: json['error']['message'] ?? 'Unknown error',
           );
        }
        return json['result'];
      } catch (e) {
         debugPrint("❌ REST Call Error: $e");
         rethrow;
      }
    }
  }
}

