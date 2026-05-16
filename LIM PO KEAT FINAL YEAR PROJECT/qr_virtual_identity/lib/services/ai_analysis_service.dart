// lib/services/ai_analysis_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_analysis_report.dart';
import '../services/gemini_service.dart';
import '../services/wallet_service.dart';
import '../services/library_service.dart';
import '../services/access_service.dart';
import '../services/user_event_service.dart';

/// 🧠 AI Analysis Service
/// Aggregates user data from various services and uses Gemini to generate
/// a personalized "Campus Persona" report.
class AiAnalysisService {
  static final AiAnalysisService _instance = AiAnalysisService._internal();
  factory AiAnalysisService() => _instance;
  AiAnalysisService._internal();

  final GeminiService _geminiService = GeminiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🚀 Generate Analysis Report
  /// Fetches data, formats prompt, calls AI, and returns parsed report.
  Future<AiAnalysisReport?> generateReport() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Aggregate Data (Concurrent Fetching)
      final userData = await _aggregateUserData(user.uid);

      // 2. Format Prompt
      final prompt = jsonEncode(userData);

      // 3. Call Gemini
      final jsonResponse = await _geminiService.generateUserReport(prompt);

      if (jsonResponse == null) return null;

      // 4. Parse & Return
      return AiAnalysisReport.fromRawJson(jsonResponse);
    } catch (e) {
      print('❌ Error generating AI report: $e');
      return null;
    }
  }

  /// 📊 Aggregate User Data
  /// Collects relevant data points for the last 30 days.
  Future<Map<String, dynamic>> _aggregateUserData(String uid) async {
    try {
      // Fetch data concurrently for performance
      final results = await Future.wait([
        WalletService.getSpendingStats(), // 0: Wallet
        LibraryService.getUserBorrowedItems(uid), // 1: Library
        AccessService.getUserAccessHistory(uid, limit: 30), // 2: Access
        UserEventService().getUserEventStats(uid), // 3: Events
      ]);

      final walletStats = results[0] as Map<String, dynamic>;
      final borrowedItems = results[1] as List<Map<String, dynamic>>;
      final accessHistory = results[2] as List<Map<String, dynamic>>;
      final eventStats = results[3] as Map<String, int>;

      // Process Wallet Data
      final totalSpent = walletStats['totalSpent'] ?? 0.0;
      final categorySpending = walletStats['categorySpending'] ?? {};

      // Process Library Data
      final bookTitles = borrowedItems
          .map((item) => item['book_title'] as String? ?? 'Unknown Book')
          .toList();

      // Process Access Data
      // Count frequency of locations
      final locationCounts = <String, int>{};
      for (var entry in accessHistory) {
        final location = entry['scan_point_name'] as String? ?? 'Unknown';
        locationCounts[location] = (locationCounts[location] ?? 0) + 1;
      }
      // Get top 3 locations
      final topLocations = locationCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top3Locations = topLocations.take(3).map((e) => e.key).toList();

      // Construct Data Map
      return {
        'period': 'Last 30 Days',
        'wallet': {
          'totalSpent': totalSpent,
          'topCategories': categorySpending,
        },
        'library': {
          'booksBorrowed': bookTitles.length,
          'titles': bookTitles,
        },
        'access': {
          'frequentLocations': top3Locations,
          'totalEntries': accessHistory.length,
        },
        'events': {
          'joined': eventStats['totalJoined'],
          'attended': eventStats['attendedEvents'],
        },
      };
    } catch (e) {
      print('❌ Error aggregating user data: $e');
      return {};
    }
  }
}
