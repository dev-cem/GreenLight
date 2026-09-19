import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Fills its parent with [controller]'s live preview, cropping to cover
/// instead of stretching. [CameraController.value.previewSize] always
/// reports the sensor's native (landscape) orientation regardless of how the
/// device is actually held — feeding that size straight into an [AspectRatio]
/// in a portrait layout is what stretches the image, so this widget swaps
/// width/height for portrait and lets [FittedBox.cover] crop to fill instead.
class CameraPreviewCover extends StatelessWidget {
  const CameraPreviewCover({super.key, required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final sensorSize = controller.value.previewSize;
    if (sensorSize == null) return const SizedBox.shrink();

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final previewSize = isPortrait
        ? Size(sensorSize.height, sensorSize.width)
        : sensorSize;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox.fromSize(
          size: previewSize,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
