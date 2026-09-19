import 'package:flutter/material.dart';

import '../app_info.dart';
import '../theme/comic_theme.dart';
import 'home_screen.dart';

/// Cold-start splash: studio name plus a fake loading bar (there's nothing
/// real to preload yet) before handing off to [HomeScreen].
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// [kStudioName] is a single "Word Word" string but this splash renders it
  /// as two stacked lines — split on the first space rather than hardcoding
  /// each line separately.
  String get _studioFirstWord => kStudioName.split(' ').first;
  String get _studioRest => kStudioName.split(' ').skip(1).join(' ');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goHome();
      })
      ..forward();
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ComicColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_studioFirstWord, style: kStudioNameStyle),
            Text(_studioRest, style: kStudioTaglineStyle),
            const SizedBox(height: 56),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _LoadingBar(progress: _controller.value),
            ),
          ],
        ),
      ),
    );
  }
}

/// Comic-styled progress bar: ink-bordered track with a hard shadow, filled
/// by a flat sunflower-yellow bar that grows with [progress] (0..1).
class _LoadingBar extends StatelessWidget {
  final double progress;

  const _LoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 22,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ComicColors.paper,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ComicColors.ink, width: 3),
        boxShadow: comicHardShadow(nearOffset: 4, farOffset: 8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: ComicColors.sunflowerYellow),
          ),
        ),
      ),
    );
  }
}
