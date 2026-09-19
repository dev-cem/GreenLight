import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Gradient;
import 'package:flutter/services.dart';

import '../audio/sfx_service.dart';
import '../theme/comic_theme.dart';
import 'greenlight_engine.dart';
import 'player.dart';
import 'settings_store.dart';

/// Renders one player's single Greenlight attempt: a full-canvas color state
/// (red while armed, green once it's time to tap) plus a big icon and prompt
/// text, so the state is never color-only (accessibility — the icon is the
/// reliable tell; a bait flash only ever brightens the red, it never swaps
/// the icon). Chrome (the "pass to player" handoff and the per-attempt
/// result panel) is left to Flutter overlays in [MatchScreen] — same
/// game-logic/presentation split as Retrace's SimonFlameGame.
///
/// Doesn't arm itself on load — [MatchScreen] calls [startAttempt] once the
/// player has confirmed the handoff, so the light can't start changing while
/// the phone is still being physically passed over.
class GreenlightFlameGame extends FlameGame with PanDetector {
  GreenlightFlameGame({
    required this.player,
    this.onAttemptFinished,
    this.onRunStart,
    this.transparentBackground = false,
  }) : engine = GreenlightEngine();

  final Player player;
  final GreenlightEngine engine;

  /// Fired once this attempt reaches a result — [MatchScreen] reads
  /// [engine]'s reactionMs/falseStart at that point to record this player's
  /// [PlayerResult].
  final VoidCallback? onAttemptFinished;

  /// Influencer Mode hook — fires the moment this attempt actually arms (the
  /// screen goes red), same "auto-start recording on first real action"
  /// pattern as Retrace's onRunStart.
  final VoidCallback? onRunStart;

  /// True when a camera preview is meant to show through as the screen's
  /// background (Influencer Mode) — [backgroundColor] returns transparent
  /// while idle instead of painting over that preview. The red/green fill
  /// still paints as normal once an attempt starts.
  final bool transparentBackground;

  final SettingsStore _settingsStore = SettingsStore();
  bool _vibrationEnabled = true;

  late final TextComponent _iconText;
  late final TextComponent _promptText;
  late final TextComponent _playerNameText;
  late final TextComponent _readyText;

  bool _started = false;
  bool _awaitingStart = false;
  double _startDelayElapsed = 0;
  static const _startDelayDuration = 0.9;

  Color _fill = ComicColors.background;

  @override
  Color backgroundColor() {
    if (transparentBackground && _fill == ComicColors.background) {
      return Colors.transparent;
    }
    return _fill;
  }

  @override
  Future<void> onLoad() async {
    _vibrationEnabled = await _settingsStore.loadVibrationEnabled();
    final center = size / 2;

    add(
      _playerNameText = TextComponent(
        text: player.name,
        position: Vector2(size.x / 2, 40),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: kComicFontFamily,
            color: ComicColors.paper,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );

    add(
      _iconText = TextComponent(
        text: '',
        position: center,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'MaterialIcons',
            color: Colors.white,
            fontSize: 120,
          ),
        ),
      ),
    );

    add(
      _promptText = TextComponent(
        text: '',
        position: Vector2(size.x / 2, center.y + 110),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: kComicFontFamily,
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );

    add(
      _readyText = TextComponent(
        text: '',
        position: center,
        anchor: Anchor.center,
        scale: Vector2.zero(),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: kComicFontFamily,
            color: ComicColors.paper,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    _wireEngine();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      final center = size / 2;
      _playerNameText.position = Vector2(size.x / 2, 40);
      _iconText.position = center;
      _promptText.position = Vector2(size.x / 2, center.y + 110);
      _readyText.position = center;
    }
  }

  void _wireEngine() {
    engine.onArmed = () {
      _fill = ComicColors.signalRed;
      _setIcon(Icons.block);
      _promptText.text = 'WAIT...';
      onRunStart?.call();
      if (_vibrationEnabled) HapticFeedback.selectionClick();
    };
    engine.onFakeFlashStart = () {
      _fill = Color.lerp(ComicColors.signalRed, Colors.white, 0.35)!;
    };
    engine.onFakeFlashEnd = () {
      _fill = ComicColors.signalRed;
    };
    engine.onGreen = () {
      _fill = ComicColors.signalGreen;
      _setIcon(Icons.check_circle);
      _promptText.text = 'TAP NOW!';
      SfxService.instance.playSuccess();
      if (_vibrationEnabled) HapticFeedback.mediumImpact();
    };
    engine.onResult = (reactionMs) {
      _promptText.text = '';
      if (_vibrationEnabled) HapticFeedback.lightImpact();
      onAttemptFinished?.call();
    };
    engine.onFalseStart = () {
      _fill = ComicColors.ink;
      _setIcon(Icons.close);
      _promptText.text = 'TOO SOON!';
      SfxService.instance.playEnd();
      if (_vibrationEnabled) HapticFeedback.heavyImpact();
      onAttemptFinished?.call();
    };
  }

  void _setIcon(IconData icon) {
    _iconText.text = String.fromCharCode(icon.codePoint);
  }

  /// Starts a short "READY?" beat before the light arms — called by
  /// [MatchScreen] once the current player has confirmed the handoff.
  void startAttempt() {
    _started = true;
    _fill = ComicColors.background;
    _iconText.text = '';
    _promptText.text = '';
    _awaitingStart = true;
    _startDelayElapsed = 0;
    _readyText.text = 'READY?';
    _readyText.scale = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_started) return;
    if (_awaitingStart) {
      _updateStartDelay(dt);
    } else {
      engine.update(dt);
    }
  }

  void _updateStartDelay(double dt) {
    _startDelayElapsed += dt;
    final t = (_startDelayElapsed / _startDelayDuration).clamp(0.0, 1.0);
    _readyText.scale = Vector2.all(Curves.easeOutBack.transform(t));
    if (_startDelayElapsed >= _startDelayDuration) {
      _awaitingStart = false;
      _readyText.text = '';
      engine.start();
    }
  }

  // A pan's onStart fires the instant a finger touches down — the same
  // latency as a tap-down — without depending on TapDetector, which isn't
  // actually re-exported by package:flame/events.dart in this version.
  @override
  void onPanStart(DragStartInfo info) {
    if (!_started || _awaitingStart) return;
    engine.submitTap();
  }
}
