import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for playing audio notifications
/// Centralized audio playback for the app
class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play success sound when attendance is marked
  Future<void> playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing success sound: $e');
      }
    }
  }

  /// Play error sound when attendance fails
  Future<void> playErrorSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing error sound: $e');
      }
    }
  }

  /// Play notification sound
  Future<void> playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing notification sound: $e');
      }
    }
  }

  /// Stop current audio
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Release audio resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

/// Convenience getter
final audioService = AudioService();
