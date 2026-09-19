import 'package:audioplayers/audioplayers.dart';

/// Plays the game's short one-shot cues: a "pop" on each accepted player
/// action (live feedback to go with the icon echo in [SimonFlameGame]), a
/// "start" cue when a run begins, a "success" cue when a round is completed,
/// and an "end" cue on game over. Each cue gets its own [AudioPlayer] so,
/// e.g., a fail's end cue never cuts off a pop that's still finishing. No
/// files ship with the repo yet — drop them at `assets/audio/pop.mp3`,
/// `start.mp3`, `success.mp3`, and `end.mp3` (folder already declared in
/// pubspec.yaml) and playback will pick them up; until then, each play call
/// fails silently rather than crashing the app.
class SfxService {
  SfxService._();

  static final SfxService instance = SfxService._();

  static const _pop = 'audio/pop.mp3';
  static const _start = 'audio/start.mp3';
  static const _success = 'audio/success.mp3';
  static const _end = 'audio/end.mp3';

  final AudioPlayer _popPlayer = AudioPlayer();
  final AudioPlayer _startPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _endPlayer = AudioPlayer();

  bool _preloaded = false;

  /// Loads every cue onto its dedicated player up front, so the first real
  /// play call doesn't pay a decode/buffer delay. Without this, `play()`
  /// has to read and decode the asset from scratch on its first use — that
  /// delay can land squarely inside the short post-round pause and make the
  /// success cue sound like it fires at the *end* of the pause instead of
  /// the instant the round was won. Call once at startup; no-ops quietly if
  /// the assets aren't in place yet, and [_play] falls back to a cold
  /// `play()` call in that case.
  Future<void> preload() async {
    if (_preloaded) return;
    try {
      await Future.wait([
        _popPlayer.setSourceAsset(_pop),
        _startPlayer.setSourceAsset(_start),
        _successPlayer.setSourceAsset(_success),
        _endPlayer.setSourceAsset(_end),
      ]);
      _preloaded = true;
    } catch (_) {
      // Assets not present yet — see class doc.
    }
  }

  Future<void> playPop() => _play(_popPlayer, _pop);
  Future<void> playStart() => _play(_startPlayer, _start);
  Future<void> playSuccess() => _play(_successPlayer, _success);
  Future<void> playEnd() => _play(_endPlayer, _end);

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      if (_preloaded) {
        await player.seek(Duration.zero);
        await player.resume();
      } else {
        await player.play(AssetSource(asset), mode: PlayerMode.lowLatency);
      }
    } catch (_) {
      // Asset not present yet — see class doc.
    }
  }
}
