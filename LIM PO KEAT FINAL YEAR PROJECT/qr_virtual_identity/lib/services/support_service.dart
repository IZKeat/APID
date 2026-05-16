import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 🛠️ Support Service
/// Handles all logic related to customer support tickets and feedback.
///
/// **Responsibilities:**
/// - Create support tickets in Firestore.
/// - Capture device and app metadata for debugging.
/// - Validate user input before submission.
class SupportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📝 Create a new support ticket
  ///
  /// **Description:**
  /// Creates a new document in the `support_tickets` collection with user details,
  /// message content, and automatically captured device information.
  ///
  /// **Parameters:**
  /// - `category`: The type of issue (e.g., 'Bug', 'Account', 'Other').
  /// - `subject`: A brief summary of the issue.
  /// - `message`: The detailed description of the problem.
  ///
  /// **Returns:**
  /// - `Future<void>`: Completes successfully if the ticket is created.
  ///
  /// **Throws:**
  /// - `Exception`: If the user is not logged in or input is invalid.
  /// - `FirebaseException`: If the network request fails.
  Future<void> createTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    // 1. Input Validation
    if (category.isEmpty || subject.isEmpty || message.isEmpty) {
      throw Exception('All fields are required.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to submit a ticket.');
    }

    try {
      // 2. Capture Device & App Info
      final deviceInfo = await _getDeviceInfo();
      final appInfo = await _getAppInfo();

      // 3. Prepare Data
      final ticketData = {
        'userId': user.uid,
        'userEmail': user.email ?? 'unknown@email.com',
        'category': category,
        'subject': subject,
        'message': message,
        'status': 'pending', // Default status
        'createdAt': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo,
        'appInfo': appInfo,
        'platform': Platform.operatingSystem,
      };

      // 4. Write to Firestore
      await _db.collection('support_tickets').add(ticketData);
      
    } catch (e) {
      // Log error internally if needed
      print('❌ [SupportService] Error creating ticket: $e');
      rethrow; // Propagate error to UI for handling
    }
  }

  /// 📱 Get Device Information
  /// Captures model, OS version, and manufacturer.
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return {
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': 'Android ${androidInfo.version.release}',
          'sdk': androidInfo.version.sdkInt.toString(),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return {
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
        };
      }
      return {'unknown': 'Unsupported platform'};
    } catch (e) {
      return {'error': 'Failed to get device info'};
    }
  }

  /// 📦 Get App Information
  /// Captures app version and build number.
  Future<Map<String, String>> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };
    } catch (e) {
      return {'error': 'Failed to get app info'};
    }
  }
}
