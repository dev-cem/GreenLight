import 'package:flutter/material.dart';

import '../theme/comic_theme.dart';

/// Top-left back control shared by the secondary screens (Leaderboard,
/// Tutorial, Settings) — an ink-outlined circle so it reads as comic chrome
/// rather than a bare Material [IconButton].
class ComicBackButton extends StatelessWidget {
  const ComicBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ComicColors.paper,
              shape: BoxShape.circle,
              border: Border.all(color: ComicColors.ink, width: 3),
              boxShadow: comicHardShadow(nearOffset: 3, farOffset: 6),
            ),
            child: const Icon(Icons.arrow_back, color: ComicColors.ink),
          ),
        ),
      ),
    );
  }
}
