import 'package:flutter/material.dart';

import '../game/leaderboard_store.dart';
import '../theme/comic_theme.dart';
import '../widgets/comic_back_button.dart';
import '../widgets/comic_panel.dart';

/// Local-only leaderboard: the fastest legal reaction times recorded on this
/// device, saved by [LeaderboardStore] after every non-DNF attempt. There's
/// no server backing this — every entry is this device's own history.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardStore _store = LeaderboardStore();
  List<LeaderboardEntry>? _entries;
  bool _loadFailed = false;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatPlayedAt(DateTime dt) {
    final month = _months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, ${dt.year} · $hour:$minute';
  }

  @override
  void initState() {
    super.initState();
    _store.load().then((entries) {
      if (mounted) {
        setState(() {
          entries.sort((a, b) => a.reactionMs.compareTo(b.reactionMs));
          _entries = entries;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _loadFailed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
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
                    const Text('Leaderboard', style: kComicTitleStyle),
                    const SizedBox(height: 4),
                    const Text(
                      'Fastest legal reactions on this device',
                      style: kComicBodyStyle,
                    ),
                    const SizedBox(height: 20),
                    if (_loadFailed)
                      const Text(
                        'Could not load your scores.',
                        textAlign: TextAlign.center,
                        style: kComicBodyStyle,
                      )
                    else if (entries == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                          color: ComicColors.ink,
                        ),
                      )
                    else if (entries.isEmpty)
                      const Text(
                        'No reactions yet — play a match to set your first '
                        'time!',
                        textAlign: TextAlign.center,
                        style: kComicBodyStyle,
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < entries.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${i + 1}.',
                                    style: kComicBodyStyle.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${entries[i].reactionMs}ms — '
                                        '${entries[i].playerName}',
                                        style: i == 0
                                            ? kComicHighScoreStyle.copyWith(
                                                fontSize: 20,
                                              )
                                            : kComicBodyStyle,
                                      ),
                                      Text(
                                        _formatPlayedAt(entries[i].playedAt),
                                        style: kComicBodyStyle.copyWith(
                                          fontSize: 12,
                                          color: ComicColors.ink
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
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
