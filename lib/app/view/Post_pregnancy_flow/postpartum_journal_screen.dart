import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/theme/font_family.dart';
import 'package:babyland/app/theme/font_style.dart';
import 'package:babyland/app/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PostpartumJournal extends StatefulWidget {
  const PostpartumJournal({super.key});

  @override
  State<PostpartumJournal> createState() => _PostpartumJournalState();
}

class _PostpartumJournalState extends State<PostpartumJournal> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: Text("Postpartum Journal", style: AppFontStyle.text_20_400(fontFamily: AppFontFamily.gilroyBold, color: AppColors.textClr))),
      body: Consumer<PostpregnancyProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDatePicker(context),
                const SizedBox(height: 30),
                Text(
                  "How are you feeling today?",
                  style: AppFontStyle.text_18_400(
                    fontFamily: AppFontFamily.gilroyBold,
                    color: AppColors.textClr,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Track your recovery progress daily. Logs are only editable on the same day.",
                  style: AppFontStyle.text_14_400(
                    fontFamily: AppFontFamily.gilroyMedium,
                    color: AppColors.textLightClr,
                  ),
                ),
                const SizedBox(height: 30),
                
                _RecoverySlider(
                  label: "Pain Level",
                  value: provider.journalPain,
                  onChanged: (v) => provider.updateJournal(pain: v),
                  minLabel: "None",
                  maxLabel: "Severe",
                  isInverted: true, // 1 is best, 5 is worst
                ),
                
                _RecoverySlider(
                  label: "Wound Healing",
                  value: provider.journalWound,
                  onChanged: (v) => provider.updateJournal(wound: v),
                  minLabel: "Poor",
                  maxLabel: "Good",
                ),
                
                _RecoverySlider(
                  label: "Swelling",
                  value: provider.journalSwelling,
                  onChanged: (v) => provider.updateJournal(swelling: v),
                  minLabel: "High",
                  maxLabel: "None",
                ),
                
                _RecoverySlider(
                  label: "Mobility",
                  value: provider.journalMobility,
                  onChanged: (v) => provider.updateJournal(mobility: v),
                  minLabel: "Limited",
                  maxLabel: "Normal",
                ),
                
                _RecoverySlider(
                  label: "Energy Level",
                  value: provider.journalEnergy,
                  onChanged: (v) => provider.updateJournal(energy: v),
                  minLabel: "Low",
                  maxLabel: "High",
                ),
                
                _RecoverySlider(
                  label: "Strength",
                  value: provider.journalStrength,
                  onChanged: (v) => provider.updateJournal(strength: v),
                  minLabel: "Weak",
                  maxLabel: "Strong",
                ),
                
                const SizedBox(height: 40),
                
                InkWell(
                  onTap: () {
                    provider.submitJournalLog(
                      date: DateFormat('dd-MM-yyyy').format(selectedDate),
                    );
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8BBD0), Color(0xFFFF8A65)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: provider.journalLogStatus?.status == ApiStatus.LOADING
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            "Finish & Save",
                            style: AppFontStyle.text_16_400(
                              fontFamily: AppFontFamily.gilroyBold,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: AppFontStyle.text_16_400(
                fontFamily: AppFontFamily.gilroyMedium,
                color: AppColors.textClr,
              ),
            ),
            const Icon(Icons.calendar_today, size: 20, color: AppColors.buttonClr1),
          ],
        ),
      ),
    );
  }
}

class _RecoverySlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String minLabel;
  final String maxLabel;
  final bool isInverted;

  const _RecoverySlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.minLabel,
    required this.maxLabel,
    this.isInverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: AppFontStyle.text_16_600(
                        fontFamily: AppFontFamily.gilroyBold,
                        color: AppColors.textClr,
                      ),
                    ),
                    Text(
                      value.toInt().toString(),
                      style: AppFontStyle.text_16_600(
                        fontFamily: AppFontFamily.gilroyBold,
                        color: const Color(0xFFFF8A65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: value,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: const Color(0xFFFF8A65),
                    inactiveColor: const Color(0xFFF8BBD0),
                    onChanged: onChanged,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      minLabel,
                      style: AppFontStyle.text_12_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                        color: AppColors.textLightClr,
                      ),
                    ),
                    Text(
                      maxLabel,
                      style: AppFontStyle.text_12_400(
                        fontFamily: AppFontFamily.gilroyMedium,
                        color: AppColors.textLightClr,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
