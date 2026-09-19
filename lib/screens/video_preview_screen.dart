import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../app_info.dart';
import '../theme/comic_theme.dart';
import '../widgets/comic_back_button.dart';
import '../widgets/comic_button.dart';

/// Shown after an Influencer Mode recording stops (reached via "View Clip"
/// on the match results panel — see match_results_screen.dart): previews the
/// clip, then lets the player share it or save it to their phone. [videoPath]
/// already has the branding caption burned into its pixels by
/// [VideoOverlayBurner] before this screen is ever reached, so there's no
/// separate live overlay drawn here — what plays back is exactly what's in
/// the file.
class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({super.key, required this.videoPath});

  final String videoPath;

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Anchors the share sheet to this screen's own (always-laid-out, full
  /// size) render box — required on iPad, where `UIActivityViewController`
  /// needs a non-zero popover source rect or the share call throws a
  /// `PlatformException`. Anchoring to this screen rather than the tapped
  /// icon avoids depending on that icon's specific render object already
  /// being attached at tap time.
  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    await Share.shareXFiles(
      [XFile(widget.videoPath)],
      text: 'Play $kGameName! Made by $kStudioName',
      sharePositionOrigin: origin,
    );
  }

  Future<void> _saveToPhone() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Gal.putVideo(widget.videoPath);
      messenger.showSnackBar(const SnackBar(content: Text('Saved to phone')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ComicColors.background,
      body: Column(
        children: [
          const ComicBackButton(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: ComicColors.ink),
                    if (_controller.value.isInitialized)
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    else
                      const CircularProgressIndicator(
                        color: ComicColors.paper,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareIconButton(
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  onTap: _share,
                ),
                _ShareIconButton(
                  icon: Icons.music_note,
                  label: 'TikTok',
                  onTap: _share,
                ),
                _ShareIconButton(
                  icon: Icons.bolt,
                  label: 'Snapchat',
                  onTap: _share,
                ),
                _ShareIconButton(
                  icon: Icons.more_horiz,
                  label: 'More',
                  onTap: _share,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ComicButton(
              label: 'Save to Phone',
              fillColor: ComicColors.sunflowerYellow,
              onPressed: _saveToPhone,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareIconButton extends StatelessWidget {
  const _ShareIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ComicColors.paper,
              shape: BoxShape.circle,
              border: Border.all(color: ComicColors.ink, width: 3),
              boxShadow: comicHardShadow(nearOffset: 3, farOffset: 6),
            ),
            child: Icon(icon, color: ComicColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: kComicBodyStyle.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
