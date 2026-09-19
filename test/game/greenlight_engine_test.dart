import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:greenlight/game/greenlight_engine.dart';

void main() {
  group('GreenlightEngine', () {
    test('start arms the engine with no result yet', () {
      final engine = GreenlightEngine(random: Random(1));
      engine.start();

      expect(engine.phase, GreenlightPhase.armed);
      expect(engine.reactionMs, isNull);
      expect(engine.falseStart, isFalse);
    });

    test('a tap during armed is an instant false start', () {
      final engine = GreenlightEngine(random: Random(1));
      engine.start();

      engine.submitTap();

      expect(engine.phase, GreenlightPhase.result);
      expect(engine.falseStart, isTrue);
      expect(engine.reactionMs, isNull);
    });

    test('a tap during a bait flash still counts as a false start', () {
      final engine = GreenlightEngine(random: Random(2));
      var sawFakeFlash = false;
      engine.onFakeFlashStart = () => sawFakeFlash = true;
      engine.start();

      _advanceUntil(engine, () => sawFakeFlash);
      engine.submitTap();

      expect(sawFakeFlash, isTrue);
      expect(engine.falseStart, isTrue);
    });

    test('waiting out the full armed window flips to green', () {
      final engine = GreenlightEngine(random: Random(1));
      engine.start();

      _advanceUntil(engine, () => engine.phase == GreenlightPhase.green);

      expect(engine.phase, GreenlightPhase.green);
      expect(engine.falseStart, isFalse);
    });

    test('a legal tap during green records a non-negative reaction time', () {
      final engine = GreenlightEngine(random: Random(1));
      engine.start();
      _advanceUntil(engine, () => engine.phase == GreenlightPhase.green);

      engine.submitTap();

      expect(engine.phase, GreenlightPhase.result);
      expect(engine.falseStart, isFalse);
      expect(engine.reactionMs, isNotNull);
      expect(engine.reactionMs, greaterThanOrEqualTo(0));
    });

    test('onGreen fires exactly once per attempt', () {
      final engine = GreenlightEngine(random: Random(4));
      var greenFires = 0;
      engine.onGreen = () => greenFires++;
      engine.start();

      _advanceUntil(engine, () => engine.phase == GreenlightPhase.green);
      // Keep ticking past the flip — onGreen must not fire again.
      for (var i = 0; i < 10; i++) {
        engine.update(0.016);
      }

      expect(greenFires, 1);
    });

    test('a second tap after result is ignored', () {
      final engine = GreenlightEngine(random: Random(1));
      engine.start();
      engine.submitTap(); // false start
      final firstReactionMs = engine.reactionMs;
      final firstFalseStart = engine.falseStart;

      engine.submitTap();

      expect(engine.falseStart, firstFalseStart);
      expect(engine.reactionMs, firstReactionMs);
    });
  });
}

/// Ticks the engine in fixed frame-sized steps until [condition] holds, or
/// gives up after a generous number of steps so a broken condition fails
/// fast instead of hanging.
void _advanceUntil(GreenlightEngine engine, bool Function() condition) {
  const stepSeconds = 0.016;
  const maxSteps = 10000;
  for (var i = 0; i < maxSteps && !condition(); i++) {
    engine.update(stepSeconds);
  }
}
