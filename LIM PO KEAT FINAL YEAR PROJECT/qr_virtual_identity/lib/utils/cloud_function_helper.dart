// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// 
// /// 🛠️ Cloud Function Helper
// /// Bypasses `cloud_functions` plugin on Windows by using direct REST API calls.
// class CloudFunctionHelper {
//   static const String _projectId = 'po-keat-fyp';
//   static const String _region = 'us-central1';
// 
//   /// Call a Cloud Function (Callable)
//   /// Automatically switches between Plugin (Mobile/Web) and REST (Windows)
//   static Future<Map<String, dynamic>> call(String functionName, [Map<String, dynamic>? parameters]) async {
//     if (defaultTargetPlatform == TargetPlatform.windows) {
//       return _callViaRest(functionName, parameters);
//     } else {
//       return _callViaPlugin(functionName, parameters);
//     }
//   }
// 
//   /// Standard Plugin Call (Android/iOS/Web)
//   static Future<Map<String, dynamic>> _callViaPlugin(String functionName, Map<String, dynamic>? parameters) async {
//     try {
//       final result = await FirebaseFunctions.instance
//           .httpsCallable(functionName)
//           .call(parameters);
//       
//       if (result.data == null) return {};
//       
//       // Ensure we return a Map<String, dynamic>
//       return Map<String, dynamic>.from(result.data as Map);
//     } catch (e) {
//       debugPrint('❌ Plugin Call Failed: $e');
//       rethrow;
//     }
//   }
// 
//   /// REST API Call (Windows Workaround)
//   static Future<Map<String, dynamic>> _callViaRest(String functionName, Map<String, dynamic>? parameters) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) throw Exception('User not logged in');
// 
//     // Get fresh ID token
//     final token = await user.getIdToken();
//     
//     // Construct URL for Callable Function
//     final uri = Uri.parse('https://$_region-$_projectId.cloudfunctions.net/$functionName');
//     
//     debugPrint('🌐 REST Call to: $uri');
// 
//     final client = HttpClient();
//     try {
//       final request = await client.postUrl(uri);
//       request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
//       request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
//       
//       // Callable functions expect data wrapped in "data" key
//       final body = jsonEncode({'data': parameters ?? {}});
//       request.write(body);
// 
//       final response = await request.close();
//       final responseBody = await response.transform(utf8.decoder).join();
//       
//       debugPrint('📥 REST Response (${response.statusCode}): $responseBody');
// 
//       if (response.statusCode != 200) {
//         throw Exception('Cloud Function failed: ${response.statusCode} - $responseBody');
//       }
// 
//       final jsonResponse = jsonDecode(responseBody);
//       
//       // Callable functions return result in "result" key
//       if (jsonResponse is Map && jsonResponse.containsKey('result')) {
//         return Map<String, dynamic>.from(jsonResponse['result'] as Map);
//       } else {
//         return {};
//       }
//     } catch (e) {
//       debugPrint('❌ REST Call Failed: $e');
//       rethrow;
//     } finally {
//       client.close();
//     }
//   }
// }
