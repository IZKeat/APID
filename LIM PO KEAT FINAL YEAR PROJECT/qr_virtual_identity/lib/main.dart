// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'utils/seed_service.dart';
import 'package:provider/provider.dart';
import 'controllers/session_controller.dart';
import 'widgets/session_expired_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/guide_service.dart'; // Import
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM

// 🔔 Background Message Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set the background messaging handler early on, as a named top-level function
  if (!Platform.isWindows) { // 🛡️ Windows Fix: Avoid background isolate threading issues
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Debug overlay flags are not set here. If you need rendering debug flags,
  // set them inside debug-only blocks or via the rendering library imports.
  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🛡️ Windows Fix: Disable persistence to prevent "non-platform thread" crash
  if (Platform.isWindows) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  // Clear any previous auth state to avoid INVALID_REFRESH_TOKEN errors during testing
  // Clear any previous auth state to avoid INVALID_REFRESH_TOKEN errors during testing
  // await FirebaseAuth.instance.signOut(); // 🔒 Disabled for Biometric Session Persistence

  // Emulator settings
  const bool useFirestoreEmulator =
      false; // ✅ Use Production Firestore (Fixes connection issues)
  const bool enableGoogleSignIn = true; // Enable Google Sign-In functionality
  const firestorePort = 8080;

  // 🔧 Configure emulator host based on platform
  // For real Android devices, replace this IP with your computer's actual IP address!
  // Run "ipconfig" in PowerShell to find your IPv4 address (e.g., 192.168.1.100)
  const String computerIpForRealDevice =
      '10.163.167.74'; // ⚠️ YOUR PC's IP! (Updated: 2025-11-19)

  final String emulatorHost = kIsWeb
      ? '127.0.0.1'
      : Platform.isAndroid
      ? computerIpForRealDevice // Use computer IP for real Android devices
      : '127.0.0.1'; // Desktop/iOS use localhost

  print('📱 Platform: ${Platform.operatingSystem}');

  // Hybrid Mode: REAL Firebase Auth + LOCAL Firestore Emulator
  // This allows Google Sign-In to work while keeping data local for development

  try {
    // Configure Auth: Use REAL Firebase Auth (not emulator)
    print('✅ Using REAL Firebase Auth (cloud) - Google Sign-In enabled');

    // Configure Firestore: Use LOCAL Emulator for data
    if (useFirestoreEmulator) {
      print(
        '📱 Connecting to Firestore Emulator at: $emulatorHost:$firestorePort',
      );
      FirebaseFirestore.instance.useFirestoreEmulator(
        emulatorHost,
        firestorePort,
      );
      print(
        '✅ Using Firestore Emulator at $emulatorHost:$firestorePort (local data)',
      );
    }

    if (enableGoogleSignIn) {
      print('✅ Google Sign-In enabled via real Firebase Auth');
    }
  } catch (e) {
    print('❌ Failed to connect to Firebase/Emulators: $e');
  }

  // 🔹 Only seed data on Desktop (Windows) in debug mode
  // Skip seeding on mobile to avoid startup delays
  // 🔹 Seeding disabled: Data is now persistent in online database
  // 🔹 Seeding enabled for Product Images update
  if (kDebugMode && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    print('🌱 Seeding data (Desktop only)...');
    try {
      // clearExisting: false ensures we just update the products, not wipe everything
      // await SeedService.rebuildFirestore(clearExisting: false);
      // await SeedService.updateProductImagesOnly(); // 🖼️ Surgical Update Complete (Disabled)
    } catch (e) {
      print('⚠️ Seeding failed: $e');
    }
  }

  // 🧭 Initialize Guide Service
  await GuideService().init();

  // 🔔 Initialize FCM Service (Mobile Only)
  // We pass a dummy context or handle context inside init differently?
  // Actually FCM init needs context for Overlay? 
  // Wait, main() doesn't have context. We should move init to MyApp or HomePage.
  // Let's move it to HomePage for context access.
  // Or use a GlobalKey<NavigatorState> context.
  
  // For now, let's just leave it here and call it in HomePage.


  // Bootstrap the app
  runApp(const MyApp());
}



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()),
      ],
      child: Consumer<SessionController>(
        builder: (context, sessionController, child) {
          return MaterialApp(
            navigatorKey: navigatorKey, // 🔑 Inject Global Key
            title: 'QR Virtual Identity',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            debugShowCheckedModeBanner: false,
            initialRoute: '/login',
            routes: appRoutes,
            builder: (context, child) {
              return SessionListenerWrapper(child: child!);
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(child: Text('Route ${settings.name} not found')),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SessionListenerWrapper extends StatefulWidget {
  final Widget child;
  const SessionListenerWrapper({super.key, required this.child});

  @override
  State<SessionListenerWrapper> createState() => _SessionListenerWrapperState();
}

class _SessionListenerWrapperState extends State<SessionListenerWrapper> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        context.read<SessionController>().startSessionListener(user.uid);
      } else {
        context.read<SessionController>().stopSessionListener();
      }
    });
    
    context.read<SessionController>().addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    context.read<SessionController>().removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (FirebaseAuth.instance.currentUser != null) {
       _showSessionExpiredDialog();
    }
  }

  void _showSessionExpiredDialog() async {
    // FIX: Use navigatorKey.currentContext to get the context UNDER the Navigator
    final navContext = navigatorKey.currentContext;
    if (navContext != null) {
      // 1. Auto Logout immediately
      await FirebaseAuth.instance.signOut();

      // 2. Navigate to Login Screen
      Navigator.of(navContext).pushNamedAndRemoveUntil('/login', (route) => false);

      // 3. Show Notification Dialog AFTER logging out
      if (navContext.mounted) {
        showDialog(
          context: navContext, 
          barrierDismissible: false,
          builder: (context) => SessionExpiredDialog(
            title: context.read<SessionController>().customKickoutMessage != null 
                ? "Security Update" 
                : null,
            message: context.read<SessionController>().customKickoutMessage,
            onLogout: () {
              // User acknowledged the message, just close the dialog
              Navigator.of(context).pop();
              // Clear message after showing
              context.read<SessionController>().setKickoutMessage(null);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
