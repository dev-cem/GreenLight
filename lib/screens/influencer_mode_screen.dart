import 'package:flutter/material.dart';

import '../camera/influencer_clip_library.dart';
import '../game/settings_store.dart';
import '../theme/comic_theme.dart';
import '../widgets/comic_back_button.dart';
import '../widgets/comic_panel.dart';
import '../widgets/setting_slider.dart';
import 'video_preview_screen.dart';

/// Reached from the home screen's header (see home_screen.dart): everything
/// about *how* Influencer Mode records and what it's already recorded.
/// Turning the feature on/off itself stays on SettingsScreen — this screen
/// only covers the recording-length setting and the last 24 hours of clips
/// (see InfluencerClipLibrary for the retention policy).
class InfluencerModeScreen extends StatefulWidget {
  const InfluencerModeScreen({super.key});

  @override
  State<InfluencerModeScreen> createState() => _InfluencerModeScreenState();
}

class _InfluencerModeScreenState extends State<InfluencerModeScreen> {
  final SettingsStore _settingsStore = SettingsStore();
  final InfluencerClipLibrary _clipLibrary = InfluencerClipLibrary();

  double _maxRecordingSeconds = 10.0;
  List<InfluencerClip>? _clips;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final maxRecordingSeconds = await _settingsStore.loadMaxRecordingSeconds();
    final clips = await _clipLibrary.listClips();
    if (!mounted) return;
    setState(() {
      _maxRecordingSeconds = maxRecordingSeconds;
      _clips = clips;
      _loaded = true;
    });
  }

  void _setMaxRecordingSeconds(double value) {
    setState(() => _maxRecordingSeconds = value);
  }

  Future<void> _saveMaxRecordingSeconds(double value) =>
      _settingsStore.saveMaxRecordingSeconds(value);

  Future<void> _deleteClip(InfluencerClip clip) async {
    await _clipLibrary.delete(clip);
    if (!mounted) return;
    setState(() => _clips?.remove(clip));
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
                    const Text('Influencer Mode', style: kComicTitleStyle),
                    const SizedBox(height: 24),
                    if (!_loaded)
                      const CircularProgressIndicator(color: ComicColors.ink)
                    else ...[
                      SettingSlider(
                        icon: Icons.timer,
                        label: 'Max Recording Length',
                        value: _maxRecordingSeconds,
                        min: SettingsStore.minRecordingSeconds,
                        max: SettingsStore.maxRecordingSeconds,
                        divisions: (SettingsStore.maxRecordingSeconds -
                                SettingsStore.minRecordingSeconds)
                            .round(),
                        onChanged: _setMaxRecordingSeconds,
                        onChangeEnd: _saveMaxRecordingSeconds,
                      ),
                      const SizedBox(height: 28),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Previous Clips', style: kComicBodyStyle),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Kept on this phone for 24 hours.',
                          style: TextStyle(
                            fontFamily: kComicFontFamily,
                            fontSize: 12,
                            color: ComicColors.steelGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_clips!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No clips yet — play a run in Influencer Mode '
                            'to record one.',
                            style: kComicBodyStyle,
                          ),
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final clip in _clips!)
                              _ClipRow(
                                clip: clip,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => VideoPreviewScreen(
                                      videoPath: clip.path,
                                    ),
                                  ),
                                ),
                                onDelete: () => _deleteClip(clip),
                              ),
                          ],
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

class _ClipRow extends StatelessWidget {
  const _ClipRow({
    required this.clip,
    required this.onTap,
    required this.onDelete,
  });

  final InfluencerClip clip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _formatRecordedAt(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} · $hour:$minute';
  }

  String _formatTimeLeft(DateTime recordedAt) {
    final left = InfluencerClipLibrary.retention -
        DateTime.now().difference(recordedAt);
    if (left.inHours >= 1) return '${left.inHours}h left';
    if (left.inMinutes >= 1) return '${left.inMinutes}m left';
    return 'expiring';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: ComicColors.ink, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.movie, color: ComicColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatRecordedAt(clip.recordedAt),
                      style: kComicBodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatTimeLeft(clip.recordedAt),
                      style: kComicBodyStyle.copyWith(
                        fontSize: 12,
                        color: ComicColors.ink.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: ComicColors.hotRed),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
