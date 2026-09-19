import 'package:flutter/material.dart';

import '../app_info.dart';
import '../game/high_score_store.dart';
import '../theme/comic_theme.dart';
import '../widgets/comic_button.dart';
import '../widgets/comic_icon_button.dart';
import '../widgets/comic_panel.dart';
import '../widgets/suite_badge.dart';
import 'influencer_mode_screen.dart';
import 'leaderboard_screen.dart';
import 'player_setup_screen.dart';
import 'settings_screen.dart';
import 'tutorial_screen.dart';

/// The app's main/home page: a top row of icon-only shortcuts (Leaderboard,
/// Tuto, and Influencer Mode on the left, Settings on the right), then a
/// panel with the rules and the best reaction time on this device, then the
/// single "Start Match" button that leads into player setup.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HighScoreStore _highScoreStore = HighScoreStore();
  int? _bestReactionMs;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final value = await _highScoreStore.load();
    if (mounted) setState(() => _bestReactionMs = value);
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    _loadHighScore();
  }

  @override
  Widget build(BuildContext context) {
    final best = _bestReactionMs;
    return Scaffold(
      backgroundColor: ComicColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ComicIconButton(
                            icon: Icons.emoji_events,
                            semanticLabel: 'Leaderboard',
                            onPressed: () => _push(const LeaderboardScreen()),
                          ),
                          const SizedBox(width: 12),
                          ComicIconButton(
                            icon: Icons.menu_book,
                            semanticLabel: 'How to play',
                            onPressed: () => _push(const TutorialScreen()),
                          ),
                          const SizedBox(width: 12),
                          ComicIconButton(
                            icon: Icons.videocam,
                            semanticLabel: 'Influencer Mode',
                            onPressed: () =>
                                _push(const InfluencerModeScreen()),
                          ),
                        ],
                      ),
                      ComicIconButton(
                        icon: Icons.settings,
                        semanticLabel: 'Settings',
                        onPressed: () => _push(const SettingsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kGameName,
                    style: kComicTitleStyle.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  ComicPanel(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      const Text(
                        'Pick your players. Pass the phone. Wait for red to '
                        'turn green, then tap — fastest legal reaction wins. '
                        "Tap too soon and you're out.",
                        textAlign: TextAlign.center,
                        style: kComicBodyStyle,
                      ),
                      const SizedBox(height: 20),
                      const Text('BEST REACTION', style: kComicBodyStyle),
                      Text(
                        best == null ? '—' : '${best}ms',
                        style: kComicHighScoreStyle,
                      ),
                    ],
                  ),
                  ComicButton(
                    label: 'Start Match',
                    fillColor: ComicColors.signalGreen,
                    labelColor: Colors.white,
                    onPressed: () => _push(const PlayerSetupScreen()),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'A GAME BY ${kStudioName.toUpperCase()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: kComicFontFamily,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SuiteBadge(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
