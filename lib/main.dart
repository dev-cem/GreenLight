import 'package:flutter/material.dart';

import 'app_info.dart';
import 'audio/music_service.dart';
import 'audio/sfx_service.dart';
import 'camera/influencer_clip_library.dart';
import 'game/settings_store.dart';
import 'screens/loading_screen.dart';
import 'theme/comic_theme.dart';

void main() {
  runApp(const GreenlightApp());
  SettingsStore().loadMusicVolume().then(MusicService.instance.setVolume);
  // Warms up the SFX players during the loading-screen splash, well before
  // the first attempt can finish — see SfxService.preload.
  SfxService.instance.preload();
  // Clips past their 24-hour retention should disappear even if the player
  // never opens the Influencer Mode screen again to trigger the cleanup
  // that listing clips there does — listClips() deletes expired ones as a
  // side effect, so calling it here (and discarding the result) is enough.
  InfluencerClipLibrary().listClips();
}

class GreenlightApp extends StatelessWidget {
  const GreenlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kGameName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ComicColors.background),
        fontFamily: kComicFontFamily,
      ),
      home: const LoadingScreen(),
    );
  }
}
