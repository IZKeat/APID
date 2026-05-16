import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 🔊 AudioHelper
/// Centralized audio management for the application.
/// Uses `audioplayers` to play sound effects for feedback.
class AudioHelper {
  static final AudioPlayer _player = AudioPlayer();

  // Sound Assets
  static const String _successSound = 'sounds/success.mp3';
  static const String _errorSound = 'sounds/error.mp3';
  static const String _beepSound = 'sounds/beep.mp3';

  /// Play success sound (Ka-ching!)
  static Future<void> playSuccess() async {
    await _playSound(_successSound);
  }

  /// Play error sound (Buzz/Error tone)
  static Future<void> playError() async {
    await _playSound(_errorSound);
  }

  /// Play generic beep (Scan feedback)
  static Future<void> playBeep() async {
    await _playSound(_beepSound);
  }

  /// Internal helper to play sound safely
  static Future<void> _playSound(String assetPath) async {
    try {
      // Set volume to 1.0 (max)
      await _player.setVolume(1.0);
      
      // Play from asset
      await _player.play(AssetSource(assetPath), mode: PlayerMode.lowLatency);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AudioHelper] Failed to play sound ($assetPath): $e');
      }
    }
  }

  /// Preload sounds to reduce latency
  static Future<void> preloadSounds() async {
    try {
      await _player.setSource(AssetSource(_successSound));
      await _player.setSource(AssetSource(_errorSound));
      await _player.setSource(AssetSource(_beepSound));
    } catch (e) {
       // Ignore preload errors
    }
  }
}
