import 'package:babyland/app/controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';

/// Merges API postpartum logs with local mood cache (Hive) so dashboard scores update immediately.
List<Data> mergePostpartumLogsWithLocalMood(List<Data> apiLogs) {
  final byKey = <String, Data>{};

  for (final log in apiLogs) {
    final parsed = TrackerMath.parseDateAny(log.date);
    if (parsed == null) continue;
    byKey[TrackerMath.dayKey(parsed)] = log;
  }

  for (final entry in UserPreference.getPostMentalHealthLogs()) {
    final parsed = TrackerMath.parseDateAny(entry['date']?.toString());
    if (parsed == null) continue;
    final key = TrackerMath.dayKey(parsed);
    final mood = entry['mood']?.toString();
    final scoreRaw = entry['score'];
    final score = scoreRaw is num
        ? scoreRaw.toInt()
        : int.tryParse(scoreRaw?.toString() ?? '') ?? TrackerMath.moodToScore(mood);

    final existing = byKey[key];
    if (existing != null) {
      final mergedMood = (existing.mood != null && existing.mood!.trim().isNotEmpty)
          ? existing.mood
          : mood;
      final mh = existing.mentalHealth;
      final mergedScore = (mh?.score != null && mh!.score! > 0) ? mh.score : score;
      final mergedMhMood = (mh?.mood != null && mh!.mood!.trim().isNotEmpty) ? mh.mood : mood;
      byKey[key] = Data(
        date: existing.date ?? key,
        mood: mergedMood,
        stressLevel: existing.stressLevel,
        anxietyLevel: existing.anxietyLevel,
        symptoms: existing.symptoms,
        notes: existing.notes,
        id: existing.id,
        sleepQuality: existing.sleepQuality,
        mentalHealth: MentalHealth(mood: mergedMhMood, score: mergedScore, notes: mh?.notes),
        hydration: existing.hydration,
      );
    } else {
      byKey[key] = Data(
        date: key,
        mood: mood,
        mentalHealth: MentalHealth(mood: mood, score: score),
      );
    }
  }

  return byKey.values.toList();
}

/// Resolves mood score from a daily log row (API shape varies).
int moodScoreFromLog(Data? log) {
  if (log == null) return 0;
  final fromMood = TrackerMath.moodToScore(log.mood);
  if (fromMood > 0) return fromMood;
  final mh = log.mentalHealth;
  if (mh?.score != null && mh!.score! > 0) {
    return mh.score!.clamp(1, 10);
  }
  return TrackerMath.moodToScore(mh?.mood);
}
