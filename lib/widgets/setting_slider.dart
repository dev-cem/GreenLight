import 'package:flutter/material.dart';

import '../theme/comic_theme.dart';

/// Ink-bordered row pairing an icon/label with a [Slider] — shared by
/// [SettingsScreen] and [InfluencerModeScreen] so every tunable setting in
/// the app looks the same. [onChanged] applies live; [onChangeEnd] is where
/// callers persist, so dragging doesn't hammer storage with a write per
/// pixel.
class SettingSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const SettingSlider({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: ComicColors.ink, width: 3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: ComicColors.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: kComicBodyStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: ComicColors.ink,
              thumbColor: ComicColors.ink,
              inactiveColor: ComicColors.sunflowerYellow,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}
