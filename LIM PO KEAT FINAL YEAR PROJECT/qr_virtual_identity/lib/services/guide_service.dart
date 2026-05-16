import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'storage_service.dart';

/// 🧭 GuideService
///
/// Manages the state and logic for the User Guide system.
/// Determines which guides should be shown and handles their completion status.
class GuideService {
  // Singleton instance
  static final GuideService _instance = GuideService._internal();
  factory GuideService() => _instance;
  GuideService._internal();

  final StorageService _storage = StorageService();

  // Guide Keys (Mapped to StorageService keys)
  // static const String guideOnboarding = StorageService.keyGuideOnboarding; // Deprecated
  // static const String guideSecurity = StorageService.keyGuideSecurity; // Deprecated
  // static const String guideEvents = StorageService.keyGuideEvents; // Deprecated

  // In-memory cache
  int _currentLevel = 0;

  /// Initialize the service by loading completion statuses into memory
  Future<void> init() async {
    try {
      // Production Logic: Load from storage
      _currentLevel = await _storage.getGuideLevel();
      
      // 🛠️ DEBUG: Reset to 0 (Commented out for Production)
      // _currentLevel = 0; 
      // await _storage.setGuideLevel(0);
      
      debugPrint('🧭 GuideService initialized: Level $_currentLevel');
    } catch (e) {
      debugPrint('⚠️ GuideService init failed: $e');
    }
  }

  /// Check if a specific Level should start
  ///
  /// Level 1: Navigation (Start immediately if level == 0)
  /// Level 2: Functions (Start if level == 1)
  /// Level 3: Profile (Start if level == 2)
  bool shouldStartLevel(int level) {
    // ⏸️ PAUSED: Turorial disabled by user request
    return false;
    
    // Original Logic:
    // return _currentLevel == (level - 1);
  }

  /// Complete a Level and Level Up!
  Future<void> completeLevel(int level) async {
    if (level <= _currentLevel) return; // Already completed

    // 1. Update State
    _currentLevel = level;
    
    // 2. Persist
    await _storage.setGuideLevel(_currentLevel);
    
    // 3. Grant Points (Mock for now, connect to UserService later)
    _grantPoints(10);
    
    debugPrint('🎉 Level $level Completed! Current Level: $_currentLevel');
  }

  Future<void> _grantPoints(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint('💰 Granting $amount points to ${user.uid} for completing Level $_currentLevel');
      await UserService.addGuidePoints(user.uid, amount);
    } else {
      debugPrint('⚠️ Cannot grant points: User not logged in');
    }
  }



  /// Skip a Level (No Points Awarded)
  Future<void> skipLevel(int level) async {
    if (level <= _currentLevel) return; // Already completed

    // 1. Update State
    _currentLevel = level;
    
    // 2. Persist
    await _storage.setGuideLevel(_currentLevel);
    
    // 3. NO Points Granted
    debugPrint('⏭️ Level $level Skipped! Current Level: $_currentLevel (No Points Awarded)');
  }

  /// Reset all guides (Debug / User Request)
  Future<void> resetAll() async {
    _currentLevel = 0;
    await _storage.resetGuides();
    debugPrint('🔄 User Guides reset to Level 0');
  }
}
