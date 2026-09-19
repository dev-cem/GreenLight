import 'package:flutter/material.dart';

import '../camera/camera_recording_service.dart';
import '../camera/influencer_clip_library.dart';
import '../camera/video_overlay_burner.dart';
import '../game/match_result.dart';
import '../game/player.dart';
import '../theme/comic_theme.dart';
import '../widgets/camera_preview_cover.dart';
import '../widgets/comic_button.dart';
import '../widgets/comic_panel.dart';
import 'match_screen.dart';
import 'video_preview_screen.dart';

/// Shown once every player has taken their attempt: the final ranking
/// (fastest legal reaction first, every DNF at the bottom), plus a rematch
/// with the same players in the same order. Owns whatever
/// [CameraRecordingService] the match was recording with — the "Stop
/// Recording"/"View Clip" flow here mirrors Retrace's game-over panel, just
/// promoted to its own screen since a match spans every player's attempt
/// rather than one player's single run.
class MatchResultsScreen extends StatefulWidget {
  const MatchResultsScreen({
    super.key,
    required this.players,
    required this.results,
    this.cameraService,
  });

  /// Original setup order — reused as-is for [_rematch] so a rematch keeps
  /// everyone's turn slot instead of reordering by how the last match ended.
  final List<Player> players;

  /// Already ranked (see [rankResults]) fastest-to-slowest, DNFs last.
  final List<PlayerResult> results;

  final CameraRecordingService? cameraService;

  @override
  State<MatchResultsScreen> createState() => _MatchResultsScreenState();
}

class _MatchResultsScreenState extends State<MatchResultsScreen> {
  final VideoOverlayBurner _overlayBurner = VideoOverlayBurner();
  final InfluencerClipLibrary _clipLibrary = InfluencerClipLibrary();

  String? _recordedVideoPath;
  bool _isRecording = false;
  bool _processingClip = false;

  @override
  void initState() {
    super.initState();
    _isRecording = widget.cameraService?.isRecording ?? false;
  }

  Future<void> _stopRecording() async {
    final path = await widget.cameraService?.stopRecording();
    if (path == null) return;
    await _finishRecording(path);
  }

  Future<void> _finishRecording(String rawPath) async {
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _processingClip = true;
    });
    final burnedPath = await _overlayBurner.burnOverlays(
      rawVideoPath: rawPath,
      context: context,
    );
    final storedPath = await _clipLibrary.store(burnedPath);
    if (!mounted) return;
    setState(() {
      _recordedVideoPath = storedPath;
      _processingClip = false;
    });
  }

  void _rematch() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MatchScreen(players: widget.players),
      ),
    );
  }

  @override
  void dispose() {
    widget.cameraService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = widget.cameraService;
    return Scaffold(
      backgroundColor: ComicColors.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cameraService != null)
              CameraPreviewCover(controller: cameraService.controller),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ComicPanel(
                  children: [
                    const Text('Results', style: kComicTitleStyle),
                    const SizedBox(height: 20),
                    for (var i = 0; i < widget.results.length; i++)
                      _ResultRow(rank: i + 1, result: widget.results[i]),
                    const SizedBox(height: 28),
                    ComicButton(
                      label: 'Rematch',
                      fillColor: ComicColors.signalGreen,
                      labelColor: Colors.white,
                      onPressed: _rematch,
                    ),
                    const SizedBox(height: 16),
                    ComicButton(
                      label: 'Home',
                      fillColor: ComicColors.sunflowerYellow,
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                    if (_isRecording) ...[
                      const SizedBox(height: 16),
                      ComicButton(
                        label: 'Stop Recording',
                        fillColor: ComicColors.hotRed,
                        labelColor: Colors.white,
                        onPressed: _stopRecording,
                      ),
                    ] else if (_processingClip) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: ComicColors.ink),
                      const SizedBox(height: 8),
                      const Text('Processing clip…', style: kComicBodyStyle),
                    ] else if (_recordedVideoPath != null) ...[
                      const SizedBox(height: 16),
                      ComicButton(
                        label: 'View Clip',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VideoPreviewScreen(
                              videoPath: _recordedVideoPath!,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.rank, required this.result});

  final int rank;
  final PlayerResult result;

  @override
  Widget build(BuildContext context) {
    final isWinner = rank == 1 && !result.dnf;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: isWinner
                ? const Icon(Icons.emoji_events, color: ComicColors.sunflowerYellow)
                : Text(
                    '$rank.',
                    style: kComicBodyStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.player.name,
              style: kComicBodyStyle.copyWith(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            result.dnf ? 'DNF' : '${result.reactionMs}ms',
            style: isWinner
                ? kComicHighScoreStyle.copyWith(fontSize: 18)
                : kComicBodyStyle.copyWith(
                    color: result.dnf
                        ? ComicColors.hotRed
                        : ComicColors.ink,
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ],
      ),
    );
  }
}
