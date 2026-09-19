import 'package:flutter/material.dart';

import '../theme/comic_theme.dart';

/// Small icon-only comic-chrome button — same ink-outlined-circle language
/// as [ComicBackButton], but for actions other than "go back" (the home
/// screen's Leaderboard/Tuto/Settings row).
class ComicIconButton extends StatelessWidget {
  const ComicIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ComicColors.paper,
            shape: BoxShape.circle,
            border: Border.all(color: ComicColors.ink, width: 3),
            boxShadow: comicHardShadow(nearOffset: 3, farOffset: 6),
          ),
          child: Icon(icon, color: ComicColors.ink, size: 24),
        ),
      ),
    );
  }
}
