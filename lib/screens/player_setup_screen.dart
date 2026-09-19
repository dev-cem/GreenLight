import 'package:flutter/material.dart';

import '../game/player.dart';
import '../game/settings_store.dart';
import '../theme/comic_theme.dart';
import '../widgets/comic_back_button.dart';
import '../widgets/comic_button.dart';
import '../widgets/comic_icon_button.dart';
import '../widgets/comic_panel.dart';
import 'match_screen.dart';
import 'pregame_camera_screen.dart';

/// Reached from the home screen: picks how many players are in this match
/// (2-[maxPlayers]) and their names, pass-and-play style, before the first
/// attempt ever starts. Each player then takes their single attempt in the
/// order set here (see match_screen.dart).
class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  static const minPlayers = 2;
  static const maxPlayers = 8;

  @override
  State<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final SettingsStore _settingsStore = SettingsStore();
  final List<TextEditingController> _controllers = [
    TextEditingController(text: 'Player 1'),
    TextEditingController(text: 'Player 2'),
  ];

  void _addPlayer() {
    if (_controllers.length >= PlayerSetupScreen.maxPlayers) return;
    setState(() {
      _controllers.add(
        TextEditingController(text: 'Player ${_controllers.length + 1}'),
      );
    });
  }

  void _removePlayer() {
    if (_controllers.length <= PlayerSetupScreen.minPlayers) return;
    setState(() => _controllers.removeLast().dispose());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Player> get _players => [
        for (var i = 0; i < _controllers.length; i++)
          Player(
            name: _controllers[i].text.trim().isEmpty
                ? 'Player ${i + 1}'
                : _controllers[i].text.trim(),
          ),
      ];

  Future<void> _startMatch() async {
    final players = _players;
    final influencerModeEnabled =
        await _settingsStore.loadInfluencerModeEnabled();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => influencerModeEnabled
            ? PreGameCameraScreen(players: players)
            : MatchScreen(players: players),
      ),
    );
  }

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
                    const Text("Who's Playing?", style: kComicTitleStyle),
                    const SizedBox(height: 8),
                    const Text(
                      'Pass the phone to each player in turn.',
                      textAlign: TextAlign.center,
                      style: kComicBodyStyle,
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < _controllers.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _PlayerNameField(
                          index: i,
                          controller: _controllers[i],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: _controllers.length >
                                  PlayerSetupScreen.minPlayers
                              ? 1
                              : 0.35,
                          child: ComicIconButton(
                            icon: Icons.remove,
                            semanticLabel: 'Remove player',
                            onPressed: _removePlayer,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          '${_controllers.length} players',
                          style: kComicBodyStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Opacity(
                          opacity: _controllers.length <
                                  PlayerSetupScreen.maxPlayers
                              ? 1
                              : 0.35,
                          child: ComicIconButton(
                            icon: Icons.add,
                            semanticLabel: 'Add player',
                            onPressed: _addPlayer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    ComicButton(
                      label: 'Start Match',
                      fillColor: ComicColors.signalGreen,
                      labelColor: Colors.white,
                      onPressed: _startMatch,
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

class _PlayerNameField extends StatelessWidget {
  const _PlayerNameField({required this.index, required this.controller});

  final int index;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: ComicColors.ink, width: 3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text('${index + 1}.', style: kComicBodyStyle.copyWith(
            fontWeight: FontWeight.bold,
          )),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              style: kComicBodyStyle,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
