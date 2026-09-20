import 'package:flutter/material.dart';

/// Comic-book visual language shared with Retrace (spec: bold ink outlines,
/// saturated primaries, offset panel shadows) — same palette/font so the two
/// games in the RGB suite read as one family instead of duplicating hex
/// values with drift between them.
const kComicFontFamily = 'Comic';

class ComicColors {
  ComicColors._();

  /// Electric blue — the chrome background (menus, panels), same value as
  /// Retrace's. The gameplay canvas itself overrides to [signalRed]/
  /// [signalGreen] during a live attempt.
  static const background = Color(0xFF1D5CFF);

  /// Blue-hued extremes used by gradients on top of [background] — a deep
  /// navy well below its brightness and a near-white well above it.
  static const backgroundRingLow = Color(0xFF0A2266);
  static const backgroundRingHigh = Color(0xFFF3F7FF);

  static const ink = Color(0xFF14141F);
  static const paper = Color(0xFFFFF7E8);

  static const hotRed = Color(0xFFFF2D3B);
  static const sunflowerYellow = Color(0xFFFFC914);

  /// Neutral grey for secondary home-screen buttons (Leaderboard/Tuto/
  /// Settings) — flat like the rest of the palette, not a muted tint.
  static const steelGrey = Color(0xFFB0B3B8);

  /// The two gameplay states the whole screen flashes to — kept visually
  /// distinct at a glance from [hotRed]'s brief flash use elsewhere (a false
  /// start reads as a sustained fill, not a quick pop). Accessibility per
  /// spec: color is never the only signal — see SignalShapeComponent for the
  /// paired icon.
  static const signalRed = Color(0xFFE8102B);
  static const signalGreen = Color(0xFF1EC46B);

  /// Retrace's identity color within the RGB suite mark (see
  /// widgets/suite_badge.dart) — distinct from Retrace's own in-game
  /// [background], which stays blue; this is purely the suite-badge
  /// convention.
  static const suiteRed = hotRed;
  static const suiteGreen = signalGreen;
  static const suiteBlue = Color(0xFF2D6CFF);
}

/// Classic pop-art "stepped" shadow: two hard-edged (no blur, no spread)
/// offset shadows stacked behind a panel/button, instead of a single soft
/// material shadow.
List<BoxShadow> comicHardShadow({
  Color near = ComicColors.ink,
  Color far = ComicColors.hotRed,
  double nearOffset = 4,
  double farOffset = 8,
}) {
  return [
    BoxShadow(
      color: near,
      offset: Offset(nearOffset, nearOffset),
      blurRadius: 0,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: far,
      offset: Offset(farOffset, farOffset),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];
}

const kComicTitleStyle = TextStyle(
  fontFamily: kComicFontFamily,
  fontSize: 34,
  fontWeight: FontWeight.bold,
  color: ComicColors.ink,
);

const kComicBodyStyle = TextStyle(
  fontFamily: kComicFontFamily,
  fontSize: 16,
  color: ComicColors.ink,
);

/// Bigger than [kComicBodyStyle] — used for the high-score readout so it
/// reads as the panel's headline number, not just another line of body text.
const kComicHighScoreStyle = TextStyle(
  fontFamily: kComicFontFamily,
  fontSize: 26,
  fontWeight: FontWeight.bold,
  color: ComicColors.ink,
);

/// Splash-screen studio name — "Kroma" stacked over "Games", same
/// ink-on-background treatment as the home screen title (kComicTitleStyle)
/// but larger since it's the only thing on screen.
const kStudioNameStyle = TextStyle(
  fontFamily: kComicFontFamily,
  fontSize: 48,
  fontWeight: FontWeight.bold,
  color: ComicColors.ink,
  letterSpacing: 1.5,
);

/// The "Games" line under [kStudioNameStyle]'s "Kroma".
const kStudioTaglineStyle = TextStyle(
  fontFamily: kComicFontFamily,
  fontSize: 22,
  fontWeight: FontWeight.bold,
  color: ComicColors.ink,
  letterSpacing: 6,
);
