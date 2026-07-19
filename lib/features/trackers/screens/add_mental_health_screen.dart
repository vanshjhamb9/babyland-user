import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/data/repository/repository.dart';
import 'package:babyland/features/post_pregnancy/state/postpartum_dashboard_notifier.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:babyland/core/utils/error_ui_handler.dart';
import 'package:babyland/core/theme/premium_app_theme.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddMentalHealthScreen extends StatefulWidget {
  const AddMentalHealthScreen({super.key});

  @override
  State<AddMentalHealthScreen> createState() => _AddMentalHealthScreenState();
}

class _AddMentalHealthScreenState extends State<AddMentalHealthScreen> {
  late TrackerStageType _stageType;
  bool _isSaving = false;

  int _score = 7;
  String _mood = TrackerMath.scoreToMood(7);
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mood = TrackerMath.scoreToMood(_score);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final stageName = args?['stage']?.toString();
    _stageType = _parseStage(stageName);
  }

  TrackerStageType _parseStage(String? stageName) {
    switch ((stageName ?? '').toLowerCase()) {
      case 'pre':
        return TrackerStageType.pre;
      case 'pregnancy':
        return TrackerStageType.pregnancy;
      case 'post':
        return TrackerStageType.post;
      default:
        return TrackerStageType.pre;
    }
  }

  void _setScore(int newScore) {
    setState(() {
      _score = newScore.clamp(1, 10);
      _mood = TrackerMath.scoreToMood(_score);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundClr,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: const Text('How are you feeling today?'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'How are you feeling today?',
                  style: AppTextStylesPremium.h2(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select a mood and score your day.',
                  style: AppTextStylesPremium.caption(),
                ),
                const SizedBox(height: 14),
                _MoodSelector(selectedScore: _score, onPick: _setScore),
                const SizedBox(height: 16),
                Text(
                  'Your score: $_score/10',
                  style: AppTextStylesPremium.body(),
                ),
                Slider(
                  value: _score.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_score',
                  onChanged: (v) => _setScore(v.round()),
                  activeColor: AppColorsPremium.primary,
                  inactiveColor: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Text('Mood: $_mood', style: AppTextStylesPremium.caption()),
                const SizedBox(height: 16),
                Text('Notes (optional)', style: AppTextStylesPremium.caption()),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppRadiusPremium.buttons,
                      ),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Write a short note...',
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _SaveButton(isSaving: _isSaving, onPressed: _save),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final notes = _notesController.text.trim();
    final now = DateTime.now();

    // Convert score (1-10) into stress/anxiety levels (0-5).
    final stressLevel = (((10 - _score) * 5.0) / 9.0).clamp(0.0, 5.0);
    final anxietyLevel = stressLevel;

    final repo = context.read<Repository>();

    setState(() => _isSaving = true);
    try {
      if (_stageType == TrackerStageType.pre) {
        final dateStr =
            '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
        final apiDate = formatDateForApi(dateStr);

        final data = {
          'date': apiDate,
          'mood': _mood,
          'symptoms': <String>[],
          'stressLevel': stressLevel,
          'anxietyLevel': anxietyLevel,
          'notes': notes,
        };

        final res = await repo.addDailyLogsMentural(data);
        if (res.success == true) {
          if (!context.mounted) return;
          Navigator.pop(context, true);
          ErrorUIHandler.showSnackBar(
            context,
            'Mood saved successfully!',
            isError: false,
          );
          return;
        }

        ErrorUIHandler.showSnackBar(
          context,
          res.message ?? 'Failed to save mood.',
        );
        return;
      }

      if (_stageType == TrackerStageType.pregnancy) {
        final dateStr =
            '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
        final apiDate = formatDateForApi(dateStr);

        final data = {
          'date': apiDate,
          'mood': _mood,
          'symptoms': <String>[],
          'stressLevel': stressLevel,
          'anxietyLevel': anxietyLevel,
          'notes': notes,
        };

        final res = await repo.postPregnancyDataApi(data: data);
        if (res.success == true) {
          if (!context.mounted) return;
          Navigator.pop(context, true);
          ErrorUIHandler.showSnackBar(
            context,
            'Mood saved successfully!',
            isError: false,
          );
          return;
        }

        ErrorUIHandler.showSnackBar(
          context,
          res.message ?? 'Failed to save mood.',
        );
        return;
      }

      // Post stage (uses POST /postpartums/logs via legacy repository).
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      final apiDate = formatDateForApi(dateStr);

      final data = {
        'date': apiDate,
        'mood': _mood,
        'symptoms': <String>[],
        'stressLevel': stressLevel,
        'anxietyLevel': anxietyLevel,
        'notes': notes,
      };

      final res = await repo.postpartumsLogsAdd(data);
      if (res.success == true) {
        // Cache for charting in the absence of a POST "GET logs" endpoint.
        await UserPreference.savePostMentalHealthLog(
          date: DateTime(now.year, now.month, now.day),
          score: _score,
          mood: _mood,
        );
        if (context.mounted) {
          try {
            final pp = context.read<PostpregnancyProvider>();
            await pp.getDashboardLogsApi();
            await context.read<PostpartumDashboardNotifier>().refresh(
              recoveryTask: pp.getRecoveryApiData?.data,
              dashboardLogs: pp.dashboardLogsApiData?.data,
              force: true,
            );
          } catch (_) {}
        }
        if (!context.mounted) return;
        Navigator.pop(context, true);
        ErrorUIHandler.showSnackBar(
          context,
          'Mood saved successfully!',
          isError: false,
        );
        return;
      }

      ErrorUIHandler.showSnackBar(
        context,
        res.message ?? 'Failed to save mood.',
      );
    } catch (e) {
      if (!context.mounted) return;
      ErrorUIHandler.showSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MoodSelector extends StatelessWidget {
  final int selectedScore;
  final ValueChanged<int> onPick;

  const _MoodSelector({
    required this.selectedScore,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    // FIXED: Use ordered list instead of moodMap.values to ensure consistent emoji-mood pairing
    final options = [
      TrackerMath.moodMap['great']!,
      TrackerMath.moodMap['good']!,
      TrackerMath.moodMap['okay']!,
      TrackerMath.moodMap['low']!,
      TrackerMath.moodMap['sad']!,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options
          .map(
            (o) => GestureDetector(
              onTap: () => onPick(o.score),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 52,
                width: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadiusPremium.buttons),
                  gradient: o.score == selectedScore
                      ? AppColorsPremium.mentalGradient
                      : null,
                  color: o.score == selectedScore ? null : Colors.white,
                  border: Border.all(
                    color: o.score == selectedScore
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                  boxShadow: o.score == selectedScore
                      ? [AppShadowPremium.softShadow()]
                      : [],
                ),
                child: Center(
                  child: Text(
                    o.emoji,
                    style: TextStyle(
                      fontSize: 26,
                      color: o.score == selectedScore
                          ? Colors.white
                          : AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MoodOption {
  final int score;
  final String emoji;
  const _MoodOption({required this.score, required this.emoji});
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: Colors.grey.shade300,
        backgroundColor: AppColorsPremium.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadiusPremium.buttons),
        ),
      ),
      child: isSaving
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
