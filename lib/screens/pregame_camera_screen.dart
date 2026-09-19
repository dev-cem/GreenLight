import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../camera/camera_recording_service.dart';
import '../game/player.dart';
import '../game/settings_store.dart';
import '../theme/comic_theme.dart';
import '../widgets/camera_preview_cover.dart';
import '../widgets/comic_button.dart';
import 'match_screen.dart';

/// Shown between player setup and [MatchScreen] when Influencer Mode is on
/// (settings_screen.dart): a live front-camera preview with an optional
/// manual "Start Recording" button, plus the "Start" button that launches
/// the match. If recording wasn't started manually here, [MatchScreen]
/// starts it automatically once the first player's attempt arms.
class PreGameCameraScreen extends StatefulWidget {
  const PreGameCameraScreen({super.key, required this.players});

  final List<Player> players;

  @override
  State<PreGameCameraScreen> createState() => _PreGameCameraScreenState();
}

class _PreGameCameraScreenState extends State<PreGameCameraScreen> {
  final CameraRecordingService _service = CameraRecordingService();
  final SettingsStore _settingsStore = SettingsStore();

  bool _loading = true;
  String? _error;
  bool _recordingStarted = false;

  /// True once ownership of [_service] has passed to [MatchScreen] — guards
  /// [dispose] from releasing a controller the next screen still needs.
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await _service.initialize();
      if (!mounted) return;
      setState(() => _loading = false);
    } on CameraSetupException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _startRecording() async {
    final maxSeconds = await _settingsStore.loadMaxRecordingSeconds();
    if (!mounted) return;
    setState(() => _recordingStarted = true);
    await _service.startRecording(
      maxDuration: Duration(seconds: maxSeconds.round()),
      onAutoStopped: (_) {},
    );
  }

  void _startMatch({required bool withCamera}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MatchScreen(
          players: widget.players,
          cameraService: withCamera ? _service : null,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Only released here if the player leaves without ever reaching
    // MatchScreen (e.g. backing out) — MatchScreen takes ownership and
    // disposes it otherwise.
    if (!_handedOff) _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ComicColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: ComicColors.paper),
              )
            : _error != null
                ? _PermissionError(
                    message: _error!,
                    onContinueWithoutRecording: () {
                      _handedOff = true;
                      _startMatch(withCamera: false);
                    },
                  )
                : _CameraReady(
                    controller: _service.controller,
                    recordingStarted: _recordingStarted,
                    onStartRecording: _startRecording,
                    onStart: () {
                      _handedOff = true;
                      _startMatch(withCamera: true);
                    },
                  ),
      ),
    );
  }
}

class _PermissionError extends StatelessWidget {
  const _PermissionError({
    required this.message,
    required this.onContinueWithoutRecording,
  });

  final String message;
  final VoidCallback onContinueWithoutRecording;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: kComicBodyStyle.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ComicButton(
              label: 'Continue without recording',
              onPressed: onContinueWithoutRecording,
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraReady extends StatelessWidget {
  const _CameraReady({
    required this.controller,
    required this.recordingStarted,
    required this.onStartRecording,
    required this.onStart,
  });

  final CameraController controller;
  final bool recordingStarted;
  final VoidCallback onStartRecording;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreviewCover(controller: controller),
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ComicButton(
                label: recordingStarted ? 'Recording…' : 'Start Recording',
                fillColor: ComicColors.hotRed,
                onPressed: recordingStarted ? () {} : onStartRecording,
              ),
              const SizedBox(height: 16),
              ComicButton(label: 'Start', onPressed: onStart),
            ],
          ),
        ),
      ],
    );
  }
}
