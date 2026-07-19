/// Model for a single pregnancy timeline week.
class TimelineWeekModel {
  final int week;
  final String babySize;
  final String babySizeComparison;
  final String bodyChanges;
  final List<String> medicalCheckups;
  final List<String> recommendedActivities;
  final String? aiInsight;

  const TimelineWeekModel({
    required this.week,
    required this.babySize,
    required this.babySizeComparison,
    required this.bodyChanges,
    this.medicalCheckups = const [],
    this.recommendedActivities = const [],
    this.aiInsight,
  });

  /// Provides default pregnancy timeline data.
  static List<TimelineWeekModel> getDefaultTimeline() {
    return [
      const TimelineWeekModel(
        week: 1,
        babySize: '< 1mm',
        babySizeComparison: 'Poppy seed',
        bodyChanges: 'Fertilization occurs. You may not notice any changes yet.',
        medicalCheckups: ['Start taking folic acid supplements'],
        recommendedActivities: ['Maintain healthy diet', 'Reduce caffeine intake'],
      ),
      const TimelineWeekModel(
        week: 4,
        babySize: '1mm',
        babySizeComparison: 'Poppy seed',
        bodyChanges: 'Missed period. Implantation may cause light spotting.',
        medicalCheckups: ['Take home pregnancy test', 'Schedule first prenatal visit'],
        recommendedActivities: ['Begin prenatal vitamins', 'Avoid alcohol and smoking'],
      ),
      const TimelineWeekModel(
        week: 6,
        babySize: '6mm',
        babySizeComparison: 'Sweet pea',
        bodyChanges: 'Morning sickness may begin. Breasts become tender.',
        medicalCheckups: ['First prenatal appointment', 'Blood tests'],
        recommendedActivities: ['Eat small frequent meals', 'Stay hydrated'],
      ),
      const TimelineWeekModel(
        week: 8,
        babySize: '1.6cm',
        babySizeComparison: 'Raspberry',
        bodyChanges: 'Nausea peaks. Fatigue is common. Uterus is growing.',
        medicalCheckups: ['Ultrasound possible', 'Hear heartbeat'],
        recommendedActivities: ['Light walking', 'Get plenty of rest'],
      ),
      const TimelineWeekModel(
        week: 10,
        babySize: '3cm',
        babySizeComparison: 'Prune',
        bodyChanges: 'Visible veins. Belly may start to show slightly.',
        medicalCheckups: ['Nuchal translucency screening option'],
        recommendedActivities: ['Prenatal yoga', 'Kegel exercises'],
      ),
      const TimelineWeekModel(
        week: 12,
        babySize: '5.5cm',
        babySizeComparison: 'Lime',
        bodyChanges: 'End of first trimester. Nausea may decrease. More energy.',
        medicalCheckups: ['First trimester screening', 'NT scan'],
        recommendedActivities: ['Light exercise', 'Balanced iron-rich diet'],
      ),
      const TimelineWeekModel(
        week: 16,
        babySize: '12cm',
        babySizeComparison: 'Avocado',
        bodyChanges: 'Baby bump visible. May feel first flutters.',
        medicalCheckups: ['AFP blood test option', 'Regular checkup'],
        recommendedActivities: ['Swimming', 'Prenatal classes'],
      ),
      const TimelineWeekModel(
        week: 20,
        babySize: '26cm',
        babySizeComparison: 'Banana',
        bodyChanges: 'Halfway there! Baby movements felt. Skin changes.',
        medicalCheckups: ['Anatomy ultrasound (20-week scan)', 'Gender reveal possible'],
        recommendedActivities: ['Moderate exercise', 'Side sleeping'],
      ),
      const TimelineWeekModel(
        week: 24,
        babySize: '30cm',
        babySizeComparison: 'Corn ear',
        bodyChanges: 'Back pain common. Braxton Hicks may start.',
        medicalCheckups: ['Glucose screening test', 'Blood pressure check'],
        recommendedActivities: ['Stretching', 'Comfortable shoes', 'Proper posture'],
      ),
      const TimelineWeekModel(
        week: 28,
        babySize: '37cm',
        babySizeComparison: 'Eggplant',
        bodyChanges: 'Third trimester begins. Shortness of breath.',
        medicalCheckups: ['Rh antibody test', 'Start biweekly visits'],
        recommendedActivities: ['Birth plan preparation', 'Hospital bag'],
      ),
      const TimelineWeekModel(
        week: 32,
        babySize: '42cm',
        babySizeComparison: 'Squash',
        bodyChanges: 'Baby is head-down. Frequent urination increases.',
        medicalCheckups: ['Growth ultrasound', 'Group B strep test soon'],
        recommendedActivities: ['Perineal massage', 'Breathing exercises'],
      ),
      const TimelineWeekModel(
        week: 36,
        babySize: '47cm',
        babySizeComparison: 'Honeydew melon',
        bodyChanges: 'Baby drops lower. Breathing may ease. Pelvic pressure.',
        medicalCheckups: ['Weekly visits begin', 'Group B strep test', 'Cervix check'],
        recommendedActivities: ['Rest frequently', 'Final birth preparations'],
      ),
      const TimelineWeekModel(
        week: 38,
        babySize: '49cm',
        babySizeComparison: 'Pumpkin',
        bodyChanges: 'Nesting instinct. Increased Braxton Hicks.',
        medicalCheckups: ['Weekly monitoring', 'NST if needed'],
        recommendedActivities: ['Walk gently', 'Pack hospital bag'],
      ),
      const TimelineWeekModel(
        week: 40,
        babySize: '51cm',
        babySizeComparison: 'Watermelon',
        bodyChanges: 'Full term! Baby is ready. Watch for labor signs.',
        medicalCheckups: ['Induction discussion if overdue', 'Final monitoring'],
        recommendedActivities: ['Rest', 'Monitor contractions', 'Stay calm and ready'],
      ),
    ];
  }
}
