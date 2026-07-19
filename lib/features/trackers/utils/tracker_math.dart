import 'package:babyland/app/constants/images.dart';
import 'package:intl/intl.dart';

enum TrackerStageType { pre, pregnancy, post }

class TrackerMath {
  /// FIXED MOOD MAPPING - SINGLE SOURCE OF TRUTH
  static Map<String, ({int score, String emoji, String label, String iconPath})> get moodMap => {
    'great': (score: 10, emoji: '😄', label: 'Great', iconPath: ImageConstants.great),
    'good': (score: 8, emoji: '😊', label: 'Good', iconPath: ImageConstants.good),
    'okay': (score: 7, emoji: '😐', label: 'Okay', iconPath: ImageConstants.okay),
    'low': (score: 4, emoji: '😔', label: 'Low', iconPath: ImageConstants.low),
    'sad': (score: 2, emoji: '😣', label: 'Sad', iconPath: ImageConstants.sad),
  };

  /// Maps API mood strings to a mental-health score (1-10).
  static int moodToScore(String? mood) {
    final m = (mood ?? '').trim().toLowerCase();
    final direct = moodMap[m]?.score;
    if (direct != null) return direct;

    // Aliases used across postpartum / pregnancy / legacy APIs.
    const aliases = <String, String>{
      'bad': 'low',
      'terrible': 'sad',
      'poor': 'low',
      'happy': 'good',
      'great mood': 'great',
      'feeling good': 'good',
      'not great': 'low',
      'stressed': 'low',
      'anxious': 'low',
    };
    final mapped = aliases[m];
    if (mapped != null) return moodMap[mapped]?.score ?? 0;

    if (m.contains('great') || m.contains('excellent')) return 10;
    if (m.contains('good')) return 8;
    if (m.contains('okay') || m.contains('ok')) return 7;
    if (m.contains('low') || m.contains('bad')) return 4;
    if (m.contains('sad') || m.contains('terrible')) return 2;

    return 0;
  }

  static String dayKey(DateTime d) {
    final x = dateOnly(d);
    return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
  }

  /// Maps score back to the best fitting mood string.
  static String scoreToMood(int score) {
    if (score >= 9) return 'Great';
    if (score >= 7) return 'Good';
    if (score >= 5) return 'Okay';
    if (score >= 3) return 'Low';
    return 'Sad';
  }

  /// Maps mood string OR score to emoji.
  static String scoreToEmoji(int score) {
    final mood = scoreToMood(score).toLowerCase();
    return moodMap[mood]?.emoji ?? '😶';
  }

  static String moodToEmoji(String? mood) {
    final m = (mood ?? '').trim().toLowerCase();
    return moodMap[m]?.emoji ?? '😶';
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Returns last N dates including today, ascending.
  static List<DateTime> lastNDays(DateTime now, {int count = 7}) {
    final today = dateOnly(now);
    return List<DateTime>.generate(count, (i) {
      final daysAgo = count - 1 - i;
      return today.subtract(Duration(days: daysAgo));
    });
  }

  /// Formats a date as `dd-MM-yyyy` (used by existing menstrual endpoints).
  static String formatDdMmYyyy(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  /// Formats a date label for chart X axis.
  /// Example: "D-6", "D-1", "Today"
  static String chartDayLabel(DateTime now, DateTime d) {
    final diff = dateOnly(now).difference(dateOnly(d)).inDays;
    if (diff == 0) return 'Today';
    // If it's technically tomorrow, clamp to Today
    if (diff < 0) return 'Today';
    return 'D-$diff';
  }

  static DateTime? parseDateAny(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    DateTime? d = DateTime.tryParse(t);
    if (d != null) return d;
    try {
      d = DateFormat('dd-MM-yyyy').parse(t);
      return d;
    } catch (_) {}
    try {
      d = DateFormat('yyyy-MM-dd').parse(t);
      return d;
    } catch (_) {}
    return null;
  }

  /// Calculates pregnancy week from start date.
  /// If days < 0, returns 0. If 0-6 days, returns 1.
  static int calculatePregnancyWeek(DateTime startDate, DateTime today) {
    final diff = dateOnly(today).difference(dateOnly(startDate)).inDays;
    if (diff < 0) return 0;
    return (diff / 7).floor() + 1;
  }

  // --- POSTPARTUM RECOVERY SCORING ---

  /// 1. Physical Healing Score (0-100)
  /// Pain (0-10 scale) -> 25 pts (Inverted: 10 pain = 0 score, 0 pain = 25 score)
  /// Wound (Poor: 0, Okay: 12.5, Good: 25)
  /// Swelling (High: 0, Mild: 12.5, None: 25)
  /// Mobility (Limited: 0, Moderate: 12.5, Normal: 25)
  static int calculatePhysicalHealingScore({
    required int pain, // 0-10
    required String wound, // poor, okay, good
    required String swelling, // high, mild, none
    required String mobility, // limited, moderate, normal
  }) {
    double score = 0;
    // Pain: 0 is best (25pts), 10 is worst (0pts)
    score += (10 - pain.clamp(0, 10)) * 2.5;

    switch (wound.toLowerCase()) {
      case 'good': score += 25; break;
      case 'okay': score += 12.5; break;
    }

    switch (swelling.toLowerCase()) {
      case 'none': score += 25; break;
      case 'mild': score += 12.5; break;
    }

    switch (mobility.toLowerCase()) {
      case 'normal': score += 25; break;
      case 'moderate': score += 12.5; break;
    }

    return score.round();
  }

  /// 2. Uterine Recovery Score (0-100)
  /// Cramps (Severe: 0, Mild: 25, None: 50)
  /// Belly Reduction (No change: 0, Slow: 25, Good: 50)
  static int calculateUterineRecoveryScore({
    required String cramps, // severe, mild, none
    required String bellyReduction, // no change, slow, good
  }) {
    double score = 0;
    switch (cramps.toLowerCase()) {
      case 'none': score += 50; break;
      case 'mild': score += 25; break;
    }
    switch (bellyReduction.toLowerCase()) {
      case 'good progress':
      case 'good': score += 50; break;
      case 'slow': score += 25; break;
    }
    return score.round();
  }

  /// 3. Energy & Strength Score (0-100)
  /// Energy (Low: 0, Moderate: 17.5, High: 35)
  /// Fatigue (High: 0, Medium: 17.5, Low: 35)
  /// Activity (Limited: 0, Moderate: 15, Normal: 30)
  static int calculateEnergyScore({
    required String energy, // low, moderate, high
    required String fatigue, // high, medium, low
    required String activity, // limited, moderate, normal
  }) {
    double score = 0;
    switch (energy.toLowerCase()) {
      case 'high': score += 35; break;
      case 'moderate': score += 17.5; break;
    }
    switch (fatigue.toLowerCase()) {
      case 'low': score += 35; break;
      case 'medium': score += 17.5; break;
    }
    switch (activity.toLowerCase()) {
      case 'normal': score += 30; break;
      case 'moderate': score += 15; break;
    }
    return score.round();
  }
}

