import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/music_service.dart';
import '../game/settings_store.dart';
import '../theme/comic_theme.dart';
import '../widgets/comic_back_button.dart';
import '../widgets/comic_panel.dart';
import '../widgets/setting_slider.dart';
import '../widgets/setting_toggle.dart';

/// General app settings. Influencer Mode only gets its on/off switch here —
/// how the recording itself behaves (max length) and its previously
/// recorded clips live on InfluencerModeScreen instead, reached from the
/// home screen's header.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsStore _store = SettingsStore();

  bool _vibrationEnabled = true;
  double _musicVolume = 0.7;
  bool _influencerModeEnabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vibration = await _store.loadVibrationEnabled();
    final musicVolume = await _store.loadMusicVolume();
    final influencerModeEnabled = await _store.loadInfluencerModeEnabled();
    if (!mounted) return;
    setState(() {
      _vibrationEnabled = vibration;
      _musicVolume = musicVolume;
      _influencerModeEnabled = influencerModeEnabled;
      _loaded = true;
    });
  }

  Future<void> _setVibrationEnabled(bool value) async {
    setState(() => _vibrationEnabled = value);
    await _store.saveVibrationEnabled(value);
    if (value) HapticFeedback.mediumImpact();
  }

  /// Applied live as the slider is dragged, so volume changes are heard
  /// immediately — persistence is deferred to [_saveMusicVolume] so dragging
  /// doesn't hammer shared_preferences with a write per pixel.
  void _setMusicVolume(double value) {
    setState(() => _musicVolume = value);
    MusicService.instance.setVolume(value);
  }

  Future<void> _saveMusicVolume(double value) => _store.saveMusicVolume(value);

  Future<void> _setInfluencerModeEnabled(bool value) async {
    setState(() => _influencerModeEnabled = value);
    await _store.saveInfluencerModeEnabled(value);
    if (value) HapticFeedback.mediumImpact();
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
                    const Text('Settings', style: kComicTitleStyle),
                    const SizedBox(height: 24),
                    if (!_loaded)
                      const CircularProgressIndicator(color: ComicColors.ink)
                    else ...[
                      SettingToggle(
                        icon: Icons.vibration,
                        label: 'Vibration',
                        value: _vibrationEnabled,
                        onChanged: _setVibrationEnabled,
                      ),
                      const SizedBox(height: 16),
                      SettingSlider(
                        icon: Icons.music_note,
                        label: 'Music',
                        value: _musicVolume,
                        onChanged: _setMusicVolume,
                        onChangeEnd: _saveMusicVolume,
                      ),
                      const SizedBox(height: 16),
                      SettingToggle(
                        icon: Icons.videocam,
                        label: 'Influencer Mode',
                        value: _influencerModeEnabled,
                        onChanged: _setInfluencerModeEnabled,
                      ),
                    ],
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
