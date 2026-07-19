import 'package:babyland/features/trackers/utils/tracker_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackerMath Mood Mapping Tests', () {
    test('moodToScore should map correct scores for valid moods', () {
      expect(TrackerMath.moodToScore('Great'), 10);
      expect(TrackerMath.moodToScore('Good'), 8);
      expect(TrackerMath.moodToScore('Okay'), 7);
      expect(TrackerMath.moodToScore('Low'), 4);
      expect(TrackerMath.moodToScore('Sad'), 2);
    });

    test('moodToScore should be case-insensitive and handle whitespace', () {
      expect(TrackerMath.moodToScore('  great  '), 10);
      expect(TrackerMath.moodToScore('GOOD'), 8);
    });

    test('moodToScore should return 0 for unknown moods', () {
      expect(TrackerMath.moodToScore('Unknown'), 0);
      expect(TrackerMath.moodToScore(null), 0);
    });

    test('scoreToMood should map scores back to correct mood labels', () {
      expect(TrackerMath.scoreToMood(10), 'Great');
      expect(TrackerMath.scoreToMood(9), 'Great');
      expect(TrackerMath.scoreToMood(8), 'Good');
      expect(TrackerMath.scoreToMood(7), 'Good');
      expect(TrackerMath.scoreToMood(6), 'Okay');
      expect(TrackerMath.scoreToMood(5), 'Okay');
      expect(TrackerMath.scoreToMood(4), 'Low');
      expect(TrackerMath.scoreToMood(3), 'Low');
      expect(TrackerMath.scoreToMood(2), 'Sad');
      expect(TrackerMath.scoreToMood(1), 'Sad');
    });

    test('moodToEmoji should return correct emoji for mood string', () {
      expect(TrackerMath.moodToEmoji('Great'), '😄');
      expect(TrackerMath.moodToEmoji('Sad'), '😣');
      expect(TrackerMath.moodToEmoji('Invalid'), '😶');
    });

    test('scoreToEmoji should return correct emoji for score', () {
      expect(TrackerMath.scoreToEmoji(10), '😄');
      expect(TrackerMath.scoreToEmoji(2), '😣');
    });

    test('moodMap should contain all 5 core moods', () {
      expect(TrackerMath.moodMap.length, 5);
      expect(TrackerMath.moodMap.containsKey('great'), true);
      expect(TrackerMath.moodMap.containsKey('good'), true);
      expect(TrackerMath.moodMap.containsKey('okay'), true);
      expect(TrackerMath.moodMap.containsKey('low'), true);
      expect(TrackerMath.moodMap.containsKey('sad'), true);
    });
  });
}
