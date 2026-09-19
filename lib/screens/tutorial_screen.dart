import 'package:flutter/material.dart';

import '../theme/comic_theme.dart';
import '../widgets/comic_back_button.dart';
import '../widgets/comic_panel.dart';

/// Explains the core loop and what each on-screen element means — for
/// players who want it spelled out, even though the game itself is meant to
/// be learnable without a tutorial.
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  static const _elements = [
    (
      Icons.block,
      'Red — wait',
      "The screen is red and shows a block icon. Don't tap yet — tapping "
          "now is an instant disqualification for this match.",
    ),
    (
      Icons.check_circle,
      'Green — tap!',
      'The screen flips to green with a checkmark, at a random moment. Tap '
          'the instant you see it — your reaction time is measured from '
          'this exact frame.',
    ),
    (
      Icons.flash_on,
      'Bait flash',
      "Red sometimes flashes brighter for a split second before turning "
          "green for real — the icon never changes, only the color. It's a "
          "trap for anyone reacting to color instead of the icon.",
    ),
    (
      Icons.close,
      'DNF',
      "Tap during red — bait flash or not — and you're disqualified for "
          "this match. No retry, no penalty time, just no score.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ComicColors.background,
      body: Column(
        children: [
          const ComicBackButton(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ComicPanel(
                  children: [
                    const Text('How to play', style: kComicTitleStyle),
                    const SizedBox(height: 12),
                    const Text(
                      'Pick 2 or more players, then pass the phone. Each '
                      'player gets one attempt: watch the screen, wait for '
                      'green, tap as fast as you can. Fastest legal reaction '
                      'wins the match.',
                      textAlign: TextAlign.center,
                      style: kComicBodyStyle,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('What you\'ll see on screen'),
                    const SizedBox(height: 12),
                    for (final (icon, title, description) in _elements)
                      _TutorialRow(
                        icon: icon,
                        title: title,
                        description: description,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: kComicFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ComicColors.ink,
        ),
      ),
    );
  }
}

class _TutorialRow extends StatelessWidget {
  const _TutorialRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ComicColors.ink, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kComicBodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(description, style: kComicBodyStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
