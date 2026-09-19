import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// One stored Influencer Mode recording. [recordedAt] is parsed from the
/// file's own name (not filesystem mtime) so it survives being copied or
/// backed up without losing track of its age.
class InfluencerClip {
  const InfluencerClip({required this.path, required this.recordedAt});

  final String path;
  final DateTime recordedAt;
}

/// Keeps finished Influencer Mode recordings on the phone for a fixed
/// 24-hour window — this retention period isn't a player-configurable
/// setting (only the recording length is, via SettingsStore), so it's a
/// plain constant here rather than anything persisted.
///
/// Clips are moved out of the OS temp dir (where [VideoOverlayBurner] leaves
/// its output) into the app's documents directory, since the temp dir can be
/// purged by the OS at any time and isn't meant for anything the player
/// should still be able to open hours later.
class InfluencerClipLibrary {
  static const retention = Duration(hours: 24);
  static const _dirName = 'influencer_clips';
  static const _fileNamePattern = r'^clip_(\d+)\.mp4$';

  Future<Directory> _clipsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Moves [sourcePath] into durable storage under a timestamped name and
  /// returns the new path. The source file is best-effort deleted
  /// afterwards — failing to clean up the temp copy doesn't matter enough
  /// to fail the whole operation over.
  Future<String> store(String sourcePath) async {
    final dir = await _clipsDir();
    final recordedAt = DateTime.now();
    final destPath = '${dir.path}/clip_${recordedAt.millisecondsSinceEpoch}.mp4';
    await File(sourcePath).copy(destPath);
    unawaited(File(sourcePath).delete().catchError((_) => File(sourcePath)));
    return destPath;
  }

  /// Deletes any clip older than [retention], then returns what's left,
  /// newest first.
  Future<List<InfluencerClip>> listClips() async {
    final dir = await _clipsDir();
    final now = DateTime.now();
    final pattern = RegExp(_fileNamePattern);
    final clips = <InfluencerClip>[];

    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final match = pattern.firstMatch(name);
      if (match == null) continue;

      final millis = int.tryParse(match.group(1)!);
      if (millis == null) continue;
      final recordedAt = DateTime.fromMillisecondsSinceEpoch(millis);

      if (now.difference(recordedAt) > retention) {
        await entity.delete();
        continue;
      }
      clips.add(InfluencerClip(path: entity.path, recordedAt: recordedAt));
    }

    clips.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return clips;
  }

  Future<void> delete(InfluencerClip clip) async {
    final file = File(clip.path);
    if (await file.exists()) await file.delete();
  }
}
