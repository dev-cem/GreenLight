import 'package:flutter/material.dart';

import '../app_info.dart';
import '../theme/comic_theme.dart';

/// Shared "part of the RGB suite" mark: three ink-outlined dots — Retrace is
/// Red, Greenlight is Green, a future game completes the set as Blue — with
/// this game's own dot solid-filled and the others left hollow, so it doubles
/// as a "more games coming" teaser rather than claiming a finished trio.
/// Meant to sit under the studio credit line on the home screen.
class SuiteBadge extends StatelessWidget {
  const SuiteBadge({super.key});

  static const _letters = ['R', 'G', 'B'];
  static const _colors = [
    ComicColors.suiteRed,
    ComicColors.suiteGreen,
    ComicColors.suiteBlue,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _letters.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _SuiteDot(
                letter: _letters[i],
                color: _colors[i],
                filled: _letters[i] == kSuiteLetter,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'PART OF THE RGB SUITE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kComicFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SuiteDot extends StatelessWidget {
  const _SuiteDot({
    required this.letter,
    required this.color,
    required this.filled,
  });

  final String letter;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: filled ? ComicColors.ink : color, width: 2),
      ),
      child: filled
          ? null
          : Text(
              letter,
              style: TextStyle(
                fontFamily: kComicFontFamily,
                fontWeight: FontWeight.bold,
                fontSize: 9,
                color: color,
              ),
            ),
    );
  }
}
