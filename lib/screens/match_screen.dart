import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../camera/camera_recording_service.dart';
import '../game/greenlight_flame_game.dart';
import '../game/high_score_store.dart';
import '../game/leaderboard_store.dart';
import '../game/match_result.dart';
import '../game/player.dart';
import '../game/settings_store.dart';
import '../theme/comic_theme.dart';
import '../widgets/camera_preview_cover.dart';
import '../widgets/comic_button.dart';
import '../widgets/comic_panel.dart';
import 'match_results_screen.dart';

/// Drives every player's single attempt in turn: a "pass the phone" handoff
/// panel, then the live [GreenlightFlameGame] canvas, then a brief per-player
/// result panel before moving on — pass-and-play, one shared device.
///
/// [cameraService], when supplied by PlayerSetupScreen/PreGameCameraScreen
/// (Influencer Mode), shows the live camera feed as this screen's background
/// for the whole match — one continuous recording spans every player's
/// attempt, not one per player — and is started automatically on the first
/// attempt if not already recording manually. Ownership passes to
/// [MatchResultsScreen] once the last player finishes.
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, required this.players, this.cameraService});

  final List<Player> players;
  final CameraRecordingService? cameraService;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final SettingsStore _settingsStore = SettingsStore();
  final HighScoreStore _highScoreStore = HighScoreStore();
  final LeaderboardStore _leaderboardStore = LeaderboardStore();

  final List<PlayerResult> _results = [];
  int _playerIndex = 0;
  bool _lastResultIsNewBest = false;
  bool _handedOff = false;

  late GreenlightFlameGame _game;

  Player get _currentPlayer => widget.players[_playerIndex];
  bool get _isLastPlayer => _playerIndex == widget.players.length - 1;

  @override
  void initState() {
    super.initState();
    _game = _buildGame();
  }

  GreenlightFlameGame _buildGame() {
    return GreenlightFlameGame(
      player: _currentPlayer,
      onRunStart: widget.cameraService == null ? null : _handleRunStart,
      onAttemptFinished: _handleAttemptFinished,
      transparentBackground: widget.cameraService != null,
    );
  }

  Future<void> _handleRunStart() async {
    final service = widget.cameraService;
    if (service == null || service.isRecording) return;
    final maxSeconds = await _settingsStore.loadMaxRecordingSeconds();
    await service.startRecording(
      maxDuration: Duration(seconds: maxSeconds.round()),
      onAutoStopped: (_) {},
    );
  }

  void _handleAttemptFinished() {
    final engine = _game.engine;
    final result = engine.falseStart
        ? PlayerResult(player: _currentPlayer, dnf: true)
        : PlayerResult(player: _currentPlayer, reactionMs: engine.reactionMs);
    setState(() {
      _results.add(result);
      _lastResultIsNewBest = false;
      _game.overlays.add('attemptResult');
    });
    if (!result.dnf) _recordScore(result.reactionMs!);
  }

  Future<void> _recordScore(int reactionMs) async {
    await _leaderboardStore.addScore(_currentPlayer.name, reactionMs);
    final isNewBest = await _highScoreStore.saveIfBest(reactionMs);
    if (isNewBest && mounted) setState(() => _lastResultIsNewBest = true);
  }

  void _goToNext() {
    if (_isLastPlayer) {
      _handedOff = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MatchResultsScreen(
            players: widget.players,
            results: rankResults(_results),
            cameraService: widget.cameraService,
          ),
        ),
      );
      return;
    }
    setState(() {
      _playerIndex++;
      _game = _buildGame();
    });
  }

  @override
  void dispose() {
    // Only released here if the match is abandoned before the last player's
    // attempt (e.g. backing out) — MatchResultsScreen takes ownership and
    // disposes it otherwise.
    if (!_handedOff) widget.cameraService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = widget.cameraService;
    return Scaffold(
      backgroundColor: ComicColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            if (cameraService != null)
              Positioned.fill(
                child: CameraPreviewCover(controller: cameraService.controller),
              ),
            GameWidget(
              key: ValueKey(_playerIndex),
              game: _game,
              initialActiveOverlays: const ['passTurn'],
              overlayBuilderMap: {
                'passTurn': (context, game) => _PassTurnOverlay(
                      showCameraBackground: cameraService != null,
                      player: _currentPlayer,
                      playerNumber: _playerIndex + 1,
                      totalPlayers: widget.players.length,
                      onReady: () {
                        _game.overlays.remove('passTurn');
                        _game.startAttempt();
                      },
                    ),
                'attemptResult': (context, game) => _AttemptResultOverlay(
                      showCameraBackground: cameraService != null,
                      result: _results.last,
                      isNewBest: _lastResultIsNewBest,
                      isLastPlayer: _isLastPlayer,
                      onNext: _goToNext,
                    ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PassTurnOverlay extends StatelessWidget {
  const _PassTurnOverlay({
    required this.showCameraBackground,
    required this.player,
    required this.playerNumber,
    required this.totalPlayers,
    required this.onReady,
  });

  final bool showCameraBackground;
  final Player player;
  final int playerNumber;
  final int totalPlayers;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: showCameraBackground
          ? Colors.transparent
          : ComicColors.background.withValues(alpha: 0.92),
      alignment: Alignment.center,
      child: ComicPanel(
        children: [
          Text(
            'Player $playerNumber of $totalPlayers',
            style: kComicBodyStyle.copyWith(color: ComicColors.steelGrey),
          ),
          const SizedBox(height: 8),
          Text("Pass to ${player.name}", style: kComicTitleStyle),
          const SizedBox(height: 12),
          const Text(
            'Wait for red to turn green, then tap as fast as you can. '
            "Tap too soon and you're disqualified.",
            textAlign: TextAlign.center,
            style: kComicBodyStyle,
          ),
          const SizedBox(height: 28),
          ComicButton(
            label: "I'm Ready",
            fillColor: ComicColors.signalGreen,
            labelColor: Colors.white,
            onPressed: onReady,
          ),
        ],
      ),
    );
  }
}

class _AttemptResultOverlay extends StatelessWidget {
  const _AttemptResultOverlay({
    required this.showCameraBackground,
    required this.result,
    required this.isNewBest,
    required this.isLastPlayer,
    required this.onNext,
  });

  final bool showCameraBackground;
  final PlayerResult result;
  final bool isNewBest;
  final bool isLastPlayer;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: showCameraBackground
          ? Colors.transparent
          : ComicColors.background.withValues(alpha: 0.92),
      alignment: Alignment.center,
      child: ComicPanel(
        children: [
          Text(result.player.name, style: kComicBodyStyle.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          if (result.dnf) ...[
            const Text('TOO SOON!', style: kComicTitleStyle),
            const SizedBox(height: 8),
            const Text(
              "Disqualified this match — jumped the light.",
              textAlign: TextAlign.center,
              style: kComicBodyStyle,
            ),
          ] else ...[
            Text('${result.reactionMs}ms', style: kComicHighScoreStyle),
            if (isNewBest) ...[
              const SizedBox(height: 8),
              const Text(
                'NEW BEST ON THIS DEVICE!',
                style: TextStyle(
                  fontFamily: kComicFontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                  color: ComicColors.hotRed,
                ),
              ),
            ],
          ],
          const SizedBox(height: 28),
          ComicButton(
            label: isLastPlayer ? 'See Results' : 'Next Player',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
