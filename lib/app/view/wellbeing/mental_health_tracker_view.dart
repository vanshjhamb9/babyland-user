import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

/// Simple mental wellbeing check-in UI (log mood / note locally; extend with API when ready).
class MentalHealthTrackerView extends StatefulWidget {
  const MentalHealthTrackerView({super.key});

  @override
  State<MentalHealthTrackerView> createState() => _MentalHealthTrackerViewState();
}

class _MentalHealthTrackerViewState extends State<MentalHealthTrackerView> {
  int _mood = 3;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        centerTitle: true,
        title: Text(
          'Mental Wellbeing',
          style: AppFontStyle.text_20_400(
            fontFamily: AppFontFamily.gilroySemiBold,
            color: AppColors.black,
          ),
        ),
      ),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'How are you feeling today?',
              style: AppFontStyle.text_18_400(
                fontFamily: AppFontFamily.gilroySemiBold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final selected = _mood == i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _mood = i + 1),
                  child: CircleAvatar(
                    radius: selected ? 26 : 22,
                    backgroundColor: selected
                        ? AppColors.buttonClr1
                        : AppColors.white,
                    child: Text(
                      '${i + 1}',
                      style: AppFontStyle.text_14_600(
                        fontFamily: AppFontFamily.gilroySemiBold,
                        color: selected ? AppColors.white : AppColors.textClr,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              '1 = low   —   5 = great',
              style: AppFontStyle.text_13_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.textLightClr,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Notes (optional)',
              style: AppFontStyle.text_16_400(
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                hintText: 'Anything on your mind?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saved locally. Sync with server can be added next.'),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.buttonClr1,
              ),
              child: const Text('Save check-in'),
            ),
          ],
        ),
      ),
    );
  }
}
