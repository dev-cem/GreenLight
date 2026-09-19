import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../widgets/brand_caption_overlay.dart';

/// Burns the branding caption into a recorded clip's actual pixels. It's
/// drawn live during gameplay as an ordinary Flutter widget, but the
/// `camera` plugin only ever records the raw sensor feed underneath it —
/// getting it into the *exported* file needs this separate post-processing
/// pass instead.
///
/// Renders the same widget shown live in-app to a PNG off-screen (via
/// [ScreenshotController.captureFromWidget] — this never actually appears on
/// the device's display) so the exported file matches what the player saw,
/// then composites it onto the video with FFmpeg's `overlay` filter.
class VideoOverlayBurner {
  Future<String> burnOverlays({
    required String rawVideoPath,
    required BuildContext context,
  }) async {
    // Anything in here — off-screen widget capture, FFmpeg itself — can
    // throw for reasons outside this app's control (a missing native plugin
    // registration, an unsupported encoder on this particular device, a
    // corrupt intermediate file). None of that should cost the player their
    // actual recording, so any failure here just falls back to the
    // unmodified raw clip instead of propagating.
    try {
      return await _burnOverlays(rawVideoPath: rawVideoPath, context: context);
    } catch (_) {
      return rawVideoPath;
    }
  }

  Future<String> _burnOverlays({
    required String rawVideoPath,
    required BuildContext context,
  }) async {
    final tempDir = await getTemporaryDirectory();
    if (!context.mounted) return rawVideoPath;
    final stamp = rawVideoPath.hashCode;
    final controller = ScreenshotController();

    final captionPath = '${tempDir.path}/greenlight_caption_$stamp.png';
    await File(captionPath).writeAsBytes(
      await controller.captureFromWidget(
        const Padding(
          padding: EdgeInsets.all(12),
          child: BrandCaptionOverlay(),
        ),
        context: context,
        pixelRatio: 3,
      ),
    );

    final outputPath = '${tempDir.path}/greenlight_clip_$stamp.mp4';
    // No GPL codecs in this app's ffmpeg build (see pubspec.yaml), so the
    // H.264 encoder has to come from the OS's own hardware encoder instead
    // of libx264.
    final encoder = Platform.isIOS ? 'h264_videotoolbox' : 'h264_mediacodec';

    final command = '-y -i "$rawVideoPath" -i "$captionPath" '
        '-filter_complex "[0:v][1:v]overlay=W-w-24:H-h-24" '
        '-c:a copy -c:v $encoder -pix_fmt yuv420p "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode) && await File(outputPath).exists()) {
      return outputPath;
    }
    return rawVideoPath;
  }
}
