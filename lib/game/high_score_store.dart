import 'package:shared_preferences/shared_preferences.dart';

/// Persists the single best (lowest) reaction time ever recorded on this
/// device across app launches — the home screen's "always the biggest [best]
/// number on screen" readout, mirroring Retrace's HighScoreStore. Unlike
/// Retrace there's no difficulty mode to key by — every legal attempt is
/// directly comparable.
class HighScoreStore {
  static const _key = 'best_reaction_ms';

  /// Returns null if no legal attempt has ever been recorded.
  Future<int?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key);
  }

  Future<void> save(int reactionMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, reactionMs);
  }

  /// Saves [reactionMs] only if it beats (or there is no) existing best,
  /// returning true if it's now the new best.
  Future<bool> saveIfBest(int reactionMs) async {
    final current = await load();
    if (current != null && current <= reactionMs) return false;
    await save(reactionMs);
    return true;
  }
}
