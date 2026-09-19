import 'player.dart';

/// One player's outcome for a single match attempt — either a clean
/// [reactionMs], or [dnf] from tapping during red (spec: instant DNF, no
/// retry). Exactly one of the two is meaningful at a time.
class PlayerResult {
  const PlayerResult({
    required this.player,
    this.reactionMs,
    this.dnf = false,
  }) : assert(
          dnf != (reactionMs != null),
          'A result is either a DNF or has a reaction time, never both/neither.',
        );

  final Player player;
  final int? reactionMs;
  final bool dnf;
}

/// Ranks a completed match's results fastest-to-slowest, with every DNF
/// sorted to the bottom regardless of the field's order.
List<PlayerResult> rankResults(List<PlayerResult> results) {
  final ranked = [...results];
  ranked.sort((a, b) {
    if (a.dnf && b.dnf) return 0;
    if (a.dnf) return 1;
    if (b.dnf) return -1;
    return a.reactionMs!.compareTo(b.reactionMs!);
  });
  return ranked;
}
