import 'package:audioplayers/audioplayers.dart';

/// Loops a background-music track at a volume set by the Settings screen's
/// music slider. No track ships with the repo yet — drop the file at
/// `assets/audio/background_music.mp3` (folder already declared in
/// pubspec.yaml) and playback will pick it up; until then, [setVolume]
/// fails silently rather than crashing the app.
class MusicService {
  MusicService._();

  static final MusicService instance = MusicService._();

  static const _track = 'audio/background_music.mp3';

  /// Fraction of the user's chosen volume applied while a round is in
  /// progress, so music doesn't compete with the per-action pop sound (see
  /// [SfxService]) — was a flat 0.35 back when volume was a fixed 1.0.
  static const _duckedRatio = 0.35;

  final AudioPlayer _player = AudioPlayer();
  double _volume = 0;
  bool _ducked = false;
  bool _playing = false;

  double get volume => _volume;

  /// [volume] is 0..1, straight off the Settings screen's slider — 0 pauses
  /// playback, anything above starts/keeps it looping at that level.
  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (volume <= 0) {
      _playing = false;
      await _player.pause();
      return;
    }
    try {
      final effective = _ducked ? volume * _duckedRatio : volume;
      if (!_playing) {
        _playing = true;
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(effective);
        await _player.play(AssetSource(_track));
      } else {
        await _player.setVolume(effective);
      }
    } catch (_) {
      // No background-music asset yet — see class doc.
    }
  }

  /// Lowers music volume while a round is in progress, relative to the
  /// user's chosen volume rather than a fixed level.
  Future<void> duck() async {
    _ducked = true;
    await _player.setVolume(_volume * _duckedRatio);
  }

  /// Restores the user's chosen music volume once gameplay ends.
  Future<void> restoreVolume() async {
    _ducked = false;
    await _player.setVolume(_volume);
  }
}
