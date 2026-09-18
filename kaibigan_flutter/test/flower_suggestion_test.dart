import 'package:flutter_test/flutter_test.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/flower_suggestion.dart';
import 'package:kaibigan_flutter/features/gratitude_garden/gratitude_model.dart';

void main() {
  group('FlowerMatcher', () {
    test('only recommends blooms the garden can actually plant', () {
      const notes = [
        'My best friend made me laugh until I cried today.',
        'I finally slept a full night and woke up calm.',
        'She checked on me when I went quiet, and stayed on the call.',
        'Thank you to my mom for everything she does.',
        'A stranger helped me carry my bags, that was so kind.',
        'I learned that I do not have to answer right away.',
        'I am looking forward to the trip we are planning next week.',
        'I got through the hardest week and I am healing.',
        'The sunlight this morning made me smile.',
        'A simple home cooked meal was enough today.',
      ];
      for (final note in notes) {
        final suggestion = FlowerMatcher.suggestFor(note);
        expect(
          GratitudeEntry.availableFlowerTypes,
          contains(suggestion.flowerType),
          reason: 'note "$note" resolved to ${suggestion.flowerType}',
        );
      }
    });

    test('reads the essence of a note rather than its length', () {
      expect(
        FlowerMatcher.suggestFor(
          'My barkada and I had kwentuhan all night and I could not stop '
          'laughing.',
        ).flowerType,
        'chrysanthemum',
      );
      expect(
        FlowerMatcher.suggestFor(
          'A very quiet, peaceful evening at home. I finally rested.',
        ).flowerType,
        'lavender',
      );
      expect(
        FlowerMatcher.suggestFor(
          'I am excited and hopeful about what is coming tomorrow.',
        ).flowerType,
        'anemone',
      );
      expect(
        FlowerMatcher.suggestFor(
          'Salamat sa pagmamahal mo, mahal na mahal kita.',
        ).flowerType,
        'rose',
      );
    });

    test('is a pure function, so a saved note keeps its badge', () {
      const note = 'She stayed with me and just listened. I felt comforted.';
      final first = FlowerMatcher.suggestFor(note);
      final second = FlowerMatcher.suggestFor(note);
      expect(first.flowerType, second.flowerType);
      expect(first.confidence, second.confidence);
      expect(FlowerMatcher.isSuggestedFor(note, first.flowerType), isTrue);
    });

    test('a note with no clear essence falls back without claiming a read', () {
      final suggestion = FlowerMatcher.suggestFor('Okay.');
      expect(suggestion.flowerType, FlowerMatcher.neutralFlower);
      expect(suggestion.isConfident, isFalse);
      expect(
        FlowerMatcher.isSuggestedFor('Okay.', FlowerMatcher.neutralFlower),
        isFalse,
        reason: 'a low-confidence default must not earn the matched badge',
      );
    });

    test('an empty note never claims a match', () {
      expect(FlowerMatcher.suggestFor('   ').isConfident, isFalse);
      expect(FlowerMatcher.suggestFor('').confidence, 0);
    });

    test('word boundaries keep "rest" out of "restless"', () {
      final restless = FlowerMatcher.suggestFor('I felt restless all night.');
      expect(restless.flowerType, isNot('lavender'));
    });

    test('a chosen flower that was not the match carries no badge', () {
      const note = 'My barkada and I laughed all night.';
      expect(FlowerMatcher.isSuggestedFor(note, 'chrysanthemum'), isTrue);
      expect(FlowerMatcher.isSuggestedFor(note, 'lavender'), isFalse);
    });
  });
}
