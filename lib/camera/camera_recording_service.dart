import 'dart:async';

import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thrown by [CameraRecordingService.initialize] when the camera/microphone
/// permission is denied or no front camera is available — callers show a
/// message and can still let the player continue without recording.
class CameraSetupException implements Exception {
  CameraSetupException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Owns one Influencer Mode recording session: a front-camera
/// [CameraController] plus a safety-net timer that force-stops recording
/// once [startRecording]'s `maxDuration` elapses, in case the match doesn't
/// finish before then. Scoped to a single play session — created by
/// [PreGameCameraScreen] and handed to [MatchScreen], not a global singleton
/// like [MusicService]/[SfxService].
class CameraRecordingService {
  CameraController? _controller;
  Timer? _autoStopTimer;
  bool _isRecording = false;

  CameraController get controller {
    final controller = _controller;
    if (controller == null) {
      throw StateError('CameraRecordingService not initialized.');
    }
    return controller;
  }

  bool get isRecording => _isRecording;

  Future<void> initialize() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      throw CameraSetupException(
        'Camera and microphone permission are needed for Influencer Mode.',
      );
    }

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.isNotEmpty
          ? cameras.first
          : throw CameraSetupException('No camera available on this device.'),
    );

    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: true,
    );
    await controller.initialize();
    _controller = controller;
  }

  /// Starts recording if not already recording; a no-op otherwise (so both
  /// the manual "Start Recording" button and the automatic game-start hook
  /// can call this without checking state first). [maxDuration] is the
  /// configured safety-net ceiling — if nothing else stops the recording
  /// first, it's force-stopped and [onAutoStopped] is called with the file
  /// path.
  Future<void> startRecording({
    required Duration maxDuration,
    required void Function(String path) onAutoStopped,
  }) async {
    if (_isRecording) return;
    await controller.startVideoRecording();
    _isRecording = true;
    _autoStopTimer = Timer(maxDuration, () async {
      final path = await stopRecording();
      if (path != null) onAutoStopped(path);
    });
  }

  /// Stops recording and returns the resulting file path, or `null` if
  /// nothing was recording — callers can call this unconditionally.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _isRecording = false;
    final file = await controller.stopVideoRecording();
    return file.path;
  }

  void dispose() {
    _autoStopTimer?.cancel();
    _controller?.dispose();
  }
}
