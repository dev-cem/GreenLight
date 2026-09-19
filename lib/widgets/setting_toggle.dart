import 'package:flutter/material.dart';

import '../theme/comic_theme.dart';

/// Ink-bordered row pairing an icon/label with a [Switch] — shared by
/// [SettingsScreen] and [InfluencerModeScreen] so every on/off setting in
/// the app looks the same.
class SettingToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
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
          Switch(
            value: value,
            activeThumbColor: ComicColors.ink,
            activeTrackColor: ComicColors.sunflowerYellow,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
