import 'package:shared_preferences/shared_preferences.dart';

/// A single leaderboard entry: one player's legal reaction time and when it
/// happened. DNFs never reach the leaderboard — there's no time to rank them
/// by (see [rankResults] for how a DNF is handled within a single match's
/// results instead).
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerName,
    required this.reactionMs,
    required this.playedAt,
  });

  final String playerName;
  final int reactionMs;
  final DateTime playedAt;

  String _encode() =>
      '$reactionMs|${playedAt.millisecondsSinceEpoch}|$playerName';

  /// Returns null if `raw` isn't a validly-encoded entry (e.g. corrupted),
  /// so one bad entry can't take down the whole leaderboard load.
  static LeaderboardEntry? _decode(String raw) {
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    final reactionMs = int.tryParse(parts[0]);
    final playedAtMillis = int.tryParse(parts[1]);
    if (reactionMs == null || playedAtMillis == null) return null;
    return LeaderboardEntry(
      reactionMs: reactionMs,
      playedAt: DateTime.fromMillisecondsSinceEpoch(playedAtMillis),
      // The name itself may contain '|' from a player free-typing one, so
      // rejoin everything after the first two fields rather than assuming
      // exactly 3 parts.
      playerName: parts.sublist(2).join('|'),
    );
  }
}

/// Persists the top local reaction times (lowest = best) for the
/// local-only Leaderboard screen — separate from [HighScoreStore], which
/// only tracks the single best value for the home-screen readout.
class LeaderboardStore {
  static const _key = 'local_leaderboard_reactions';
  static const maxEntries = 10;

  Future<List<LeaderboardEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map(LeaderboardEntry._decode)
        .whereType<LeaderboardEntry>()
        .toList();
  }

  Future<List<LeaderboardEntry>> addScore(
    String playerName,
    int reactionMs,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await load()
      ..add(LeaderboardEntry(
        playerName: playerName,
        reactionMs: reactionMs,
        playedAt: DateTime.now(),
      ));

    entries.sort((a, b) => a.reactionMs.compareTo(b.reactionMs));
    final trimmed = entries.take(maxEntries).toList();

    await prefs.setStringList(_key, trimmed.map((e) => e._encode()).toList());
    return trimmed;
  }
}
