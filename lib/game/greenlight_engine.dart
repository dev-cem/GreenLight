import 'dart:math';

enum GreenlightPhase { idle, armed, green, result }

/// Core Greenlight state machine for one player's single attempt: Idle →
/// Armed (red, waiting, with the occasional bait flash) → Green → Result
/// (a clean reaction time, or a false start). Plain Dart, no Flutter/Flame
/// imports, so it's unit testable on its own and reusable behind any
/// renderer — mirrors Retrace's SimonGameEngine split of game logic from
/// presentation.
///
/// [update] drives the Armed countdown and bait-flash scheduling from
/// elapsed frame time (`dt`), so it naturally stops advancing whenever the
/// host stops ticking frames (e.g. the app backgrounded) — a player can't
/// exploit an early tap. The Green-phase reaction time itself is measured
/// with a real [Stopwatch] instead, for sub-frame precision on the number
/// that's actually compared between players.
class GreenlightEngine {
  final Random _random;

  GreenlightPhase phase = GreenlightPhase.idle;

  /// Set once [phase] reaches [GreenlightPhase.result] via a legal tap.
  int? reactionMs;

  /// True if [phase] reached [GreenlightPhase.result] via a tap during
  /// [GreenlightPhase.armed] — an instant DNF for this attempt.
  bool falseStart = false;

  double _armedElapsedMs = 0;
  double _armedDurationMs = 0;
  final Stopwatch _greenStopwatch = Stopwatch();

  List<double> _fakeFlashStartsMs = const [];
  int _nextFakeFlashIndex = 0;
  bool _showingFakeFlash = false;
  double _fakeFlashElapsedMs = 0;

  /// How long the screen holds on the red "Armed" state before flipping to
  /// green — randomized per attempt so players can't anticipate the flip.
  static const minArmedMs = 1500.0;
  static const maxArmedMs = 5000.0;

  /// Length of each bait flash — long enough to register as "something
  /// changed" but short enough to stay clearly distinct from the sustained
  /// green fill once it actually arrives.
  static const fakeFlashDurationMs = 180.0;

  /// Fired when a fresh attempt starts and the screen goes red.
  void Function()? onArmed;

  /// Fired at the start/end of a bait flash — a brief visual pulse during
  /// Armed that looks like it might be the real thing.
  void Function()? onFakeFlashStart;
  void Function()? onFakeFlashEnd;

  /// Fired the instant the screen flips to green — this is the moment the
  /// player's reaction time is measured from.
  void Function()? onGreen;

  /// Fired on a legal tap during Green, with the measured reaction time.
  void Function(int reactionMs)? onResult;

  /// Fired on a tap during Armed (including during a bait flash) — a false
  /// start, instant DNF for this attempt.
  void Function()? onFalseStart;

  GreenlightEngine({Random? random}) : _random = random ?? Random();

  void start() {
    phase = GreenlightPhase.armed;
    reactionMs = null;
    falseStart = false;
    _armedElapsedMs = 0;
    _armedDurationMs =
        minArmedMs + _random.nextDouble() * (maxArmedMs - minArmedMs);
    _fakeFlashStartsMs = _scheduleFakeFlashes();
    _nextFakeFlashIndex = 0;
    _showingFakeFlash = false;
    _fakeFlashElapsedMs = 0;
    _greenStopwatch
      ..reset()
      ..stop();
    onArmed?.call();
  }

  /// 0-2 bait flashes at random points in the armed window, each kept clear
  /// of the window's edges so a flash can never bleed into the real green
  /// flip or overlap another flash.
  List<double> _scheduleFakeFlashes() {
    const edgeMarginMs = 250.0;
    final count = _random.nextInt(3); // 0, 1, or 2
    final starts = <double>[];
    final latestStart = _armedDurationMs - fakeFlashDurationMs - edgeMarginMs;
    for (var i = 0; i < count; i++) {
      if (latestStart <= edgeMarginMs) break;
      starts.add(
        edgeMarginMs + _random.nextDouble() * (latestStart - edgeMarginMs),
      );
    }
    starts.sort();
    return starts;
  }

  void update(double dt) {
    if (phase == GreenlightPhase.armed) _updateArmed(dt * 1000);
  }

  void _updateArmed(double dtMs) {
    _armedElapsedMs += dtMs;

    if (_showingFakeFlash) {
      _fakeFlashElapsedMs += dtMs;
      if (_fakeFlashElapsedMs >= fakeFlashDurationMs) {
        _showingFakeFlash = false;
        onFakeFlashEnd?.call();
      }
    } else if (_nextFakeFlashIndex < _fakeFlashStartsMs.length &&
        _armedElapsedMs >= _fakeFlashStartsMs[_nextFakeFlashIndex]) {
      _nextFakeFlashIndex++;
      _showingFakeFlash = true;
      _fakeFlashElapsedMs = 0;
      onFakeFlashStart?.call();
    }

    if (_armedElapsedMs >= _armedDurationMs) {
      if (_showingFakeFlash) {
        _showingFakeFlash = false;
        onFakeFlashEnd?.call();
      }
      phase = GreenlightPhase.green;
      _greenStopwatch
        ..reset()
        ..start();
      onGreen?.call();
    }
  }

  /// Called by the input layer the instant the player taps.
  void submitTap() {
    switch (phase) {
      case GreenlightPhase.armed:
        falseStart = true;
        phase = GreenlightPhase.result;
        onFalseStart?.call();
      case GreenlightPhase.green:
        _greenStopwatch.stop();
        reactionMs = _greenStopwatch.elapsedMilliseconds;
        phase = GreenlightPhase.result;
        onResult?.call(reactionMs!);
      case GreenlightPhase.idle:
      case GreenlightPhase.result:
        break;
    }
  }
}
