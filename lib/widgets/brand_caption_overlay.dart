import 'package:flutter/material.dart';

import '../app_info.dart';
import '../theme/comic_theme.dart';

/// "Play: `<game>` / Made by `<studio>`" caption drawn over a recording —
/// shared by [VideoOverlayBurner] (rendered off-screen to a PNG that gets
/// burned into the exported clip) so the pixels the player sees in preview
/// match exactly what's actually in the file. [kGameName]/[kStudioName]
/// (app_info.dart) are never hardcoded here.
class BrandCaptionOverlay extends StatelessWidget {
  const BrandCaptionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Colors.black, blurRadius: 6)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Play: $kGameName',
          textAlign: TextAlign.right,
          style: kComicBodyStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: shadow,
          ),
        ),
        Text(
          'Made by $kStudioName',
          textAlign: TextAlign.right,
          style: kComicBodyStyle.copyWith(
            color: Colors.white,
            fontSize: 13,
            shadows: shadow,
          ),
        ),
      ],
    );
  }
}
