import 'package:shared_preferences/shared_preferences.dart';

/// Persists the player's vibration/music preferences (Settings screen)
/// across app launches, mirroring [HighScoreStore]'s load/save shape.
class SettingsStore {
  static const _vibrationKey = 'settings_vibration_enabled';
  static const _musicVolumeKey = 'settings_music_volume';
  static const _defaultMusicVolume = 0.7;
  static const _influencerModeKey = 'settings_influencer_mode_enabled';
  static const _maxRecordingSecondsKey = 'settings_max_recording_seconds';
  static const _defaultMaxRecordingSeconds = 10.0;
  static const minRecordingSeconds = 5.0;
  static const maxRecordingSeconds = 30.0;

  Future<bool> loadVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationKey) ?? true;
  }

  Future<void> saveVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, enabled);
  }

  Future<double> loadMusicVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_musicVolumeKey) ?? _defaultMusicVolume;
  }

  Future<void> saveMusicVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, volume);
  }

  Future<bool> loadInfluencerModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_influencerModeKey) ?? false;
  }

  Future<void> saveInfluencerModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_influencerModeKey, enabled);
  }

  /// Ceiling on how long an Influencer Mode recording is allowed to run
  /// (spec: player-configurable, capped at 30s) — clamped on load so a value
  /// saved by a future version with a wider range can never exceed today's
  /// cap.
  Future<double> loadMaxRecordingSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_maxRecordingSecondsKey) ??
        _defaultMaxRecordingSeconds;
    return value.clamp(minRecordingSeconds, maxRecordingSeconds);
  }

  Future<void> saveMaxRecordingSeconds(double seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      _maxRecordingSecondsKey,
      seconds.clamp(minRecordingSeconds, maxRecordingSeconds),
    );
  }
}
