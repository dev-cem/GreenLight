import 'package:flutter/material.dart';

import '../theme/comic_theme.dart';

/// The comic-panel card used behind overlays and home-screen content: an
/// opaque comic-paper fill (a translucent one would let the doubled hard
/// shadow underneath bleed through the whole panel instead of just peeking
/// out past its edges), thick ink border, and the doubled hard shadow itself
/// (spec §6 — "thick rounded comic-panel-style borders with an offset drop
/// shadow").
class ComicPanel extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const ComicPanel({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: ComicColors.paper,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ComicColors.ink, width: 4),
        boxShadow: comicHardShadow(
          far: ComicColors.sunflowerYellow,
          nearOffset: 6,
          farOffset: 12,
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
