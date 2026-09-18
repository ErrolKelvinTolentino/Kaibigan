import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/core/services/ui_sound_service.dart';
import 'package:kaibigan_flutter/core/widgets/kaibigan_sound_scope.dart';

void main() {
  group('sound levels', () {
    test('off is the only silent level, and volume rises with each step', () {
      expect(UiSoundLevel.off.isSilent, isTrue);
      for (final level in UiSoundLevel.values.where((l) => !l.isSilent)) {
        expect(level.volume, greaterThan(0));
      }
      expect(
        UiSoundLevel.soft.volume,
        lessThan(UiSoundLevel.balanced.volume),
      );
      expect(
        UiSoundLevel.balanced.volume,
        lessThan(UiSoundLevel.full.volume),
      );
    });

    test('an unknown stored value falls back to soft, not off', () {
      expect(UiSoundLevelX.fromStorage('nonsense'), UiSoundLevel.soft);
      expect(UiSoundLevelX.fromStorage(null), UiSoundLevel.soft);
      expect(UiSoundLevelX.fromStorage('full'), UiSoundLevel.full);
    });

    test('every cue maps to a real asset path and a repeat guard', () {
      final paths = <String>{};
      for (final sound in UiSound.values) {
        expect(sound.assetPath, startsWith('ui sounds/'));
        expect(sound.assetPath, endsWith('.wav'));
        expect(paths.add(sound.assetPath), isTrue);
        expect(sound.minimumGap.inMilliseconds, greaterThan(0));
      }
      // The tap is heard constantly, so it must be the least restricted.
      expect(
        UiSound.tap.minimumGap,
        lessThan(UiSound.complete.minimumGap),
      );
    });

    test('a silent controller records nothing while sound is off', () async {
      final controller = SilentUiSoundController(level: UiSoundLevel.off);
      controller.play(UiSound.tap);
      expect(controller.played, isEmpty);

      await controller.setLevel(UiSoundLevel.balanced);
      controller.play(UiSound.tap);
      expect(controller.played, [UiSound.tap]);
    });
  });

  group('the global tap cue', () {
    late SilentUiSoundController sound;

    setUp(() => sound = SilentUiSoundController());

    Widget appWith(Widget child) => MaterialApp(
          home: KaibiganSoundScope(
            controller: sound,
            child: Scaffold(body: child),
          ),
        );

    testWidgets('a press on a button is heard', (tester) async {
      await tester.pumpWidget(
        appWith(
          Center(
            child: FilledButton(
              key: const ValueKey('probe'),
              onPressed: () {},
              child: const Text('Save'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('probe')));
      await tester.pumpAndSettle();
      expect(sound.played, contains(UiSound.tap));
    });

    testWidgets('a press on plain text is not', (tester) async {
      await tester.pumpWidget(
        appWith(
          const Center(
            child: Text('Just a paragraph', key: ValueKey('probe')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('probe')));
      await tester.pumpAndSettle();
      expect(sound.played, isEmpty);
    });

    testWidgets('scrolling a list stays silent', (tester) async {
      await tester.pumpWidget(
        appWith(
          ListView.builder(
            key: const ValueKey('probe'),
            itemCount: 40,
            itemBuilder: (_, index) => SizedBox(
              height: 60,
              child: Text('Row $index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('probe')),
        const Offset(0, -320),
      );
      await tester.pumpAndSettle();
      expect(
        sound.played,
        isEmpty,
        reason: 'a scroll gesture is not a tap',
      );
    });

    testWidgets('a drag that starts on a tappable row stays silent',
        (tester) async {
      await tester.pumpWidget(
        appWith(
          ListView(
            key: const ValueKey('probe'),
            children: [
              for (var i = 0; i < 30; i++)
                ListTile(title: Text('Row $i'), onTap: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Row 2'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(sound.played, isEmpty);
    });

    testWidgets('a disabled control stays silent', (tester) async {
      await tester.pumpWidget(
        appWith(
          const Center(
            child: FilledButton(
              key: ValueKey('probe'),
              onPressed: null,
              child: Text('Save'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('probe')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(
        sound.played,
        isEmpty,
        reason: 'a greyed-out button should not answer back',
      );
    });

    testWidgets('turning sound off silences the global cue too',
        (tester) async {
      await sound.setLevel(UiSoundLevel.off);
      await tester.pumpWidget(
        appWith(
          Center(
            child: FilledButton(
              key: const ValueKey('probe'),
              onPressed: () {},
              child: const Text('Save'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('probe')));
      await tester.pumpAndSettle();
      expect(sound.played, isEmpty);
    });
  });

  group('meaningful cues', () {
    testWidgets('a widget inside the scope can play one', (tester) async {
      final sound = SilentUiSoundController();
      await tester.pumpWidget(
        MaterialApp(
          home: KaibiganSoundScope(
            controller: sound,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const ValueKey('save'),
                    onPressed: () =>
                        KaibiganSoundScope.play(context, UiSound.success),
                    child: const Text('Save'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('save')));
      await tester.pumpAndSettle();
      expect(sound.played, contains(UiSound.success));
    });

    testWidgets('playing outside a scope is a no-op, not a crash',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const ValueKey('save'),
                  onPressed: () =>
                      KaibiganSoundScope.play(context, UiSound.success),
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('save')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(KaibiganSoundScope.maybeOf(
        tester.element(find.byKey(const ValueKey('save'))),
      ), isNull);
    });
  });

  group('route cues', () {
    testWidgets('a pushed screen announces itself, the first one does not',
        (tester) async {
      final sound = SilentUiSoundController();
      final observer = KaibiganSoundNavigatorObserver(sound);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const ValueKey('go'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('Next')),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        sound.played,
        isEmpty,
        reason: 'the app opening is not a navigation cue',
      );

      await tester.tap(find.byKey(const ValueKey('go')));
      await tester.pumpAndSettle();
      expect(sound.played, contains(UiSound.open));
    });
  });

  group('what counts as a tap', () {
    const origin = Offset(100, 100);

    bool isTap({
      Offset up = origin,
      Duration held = const Duration(milliseconds: 80),
      bool scrolled = false,
    }) =>
        KaibiganSoundScope.isTapGesture(
          downPosition: origin,
          upPosition: up,
          held: held,
          scrolled: scrolled,
        );

    test('a quick press in one place is a tap', () {
      expect(isTap(), isTrue);
      // A little wobble is still a tap; fingers are not styluses.
      expect(isTap(up: const Offset(108, 104)), isTrue);
    });

    test('a pointer that travelled is a drag, not a tap', () {
      expect(isTap(up: const Offset(100, 160)), isFalse);
      expect(isTap(up: const Offset(140, 100)), isFalse);
    });

    test('a press held to the long-press threshold is not a tap', () {
      expect(isTap(held: kLongPressTimeout), isFalse);
      expect(
        isTap(held: kLongPressTimeout - const Duration(milliseconds: 1)),
        isTrue,
      );
    });

    test('anything that scrolled is never a tap', () {
      expect(isTap(scrolled: true), isFalse);
    });
  });
}
