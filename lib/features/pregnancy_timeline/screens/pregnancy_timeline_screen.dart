import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../app/widgets/custom_appbar.dart';
import '../../../app/widgets/text.dart';
import '../models/timeline_week_model.dart';
import '../widgets/timeline_card.dart';

/// AI Pregnancy Timeline screen.
///
/// Displays Week 1 → Week 40 with baby size, body changes,
/// checkups, and recommended activities.
class PregnancyTimelineScreen extends StatefulWidget {
  const PregnancyTimelineScreen({super.key});

  @override
  State<PregnancyTimelineScreen> createState() =>
      _PregnancyTimelineScreenState();
}

class _PregnancyTimelineScreenState extends State<PregnancyTimelineScreen> {
  final List<TimelineWeekModel> _weeks =
      TimelineWeekModel.getDefaultTimeline();

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        toolbarHeight: 70,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline, color: AppColors.buttonClr2, size: 22),
            const SizedBox(width: 8),
            GradientText(
              'Pregnancy Timeline',
              gradient: AppColors.buttonClr,
              style: AppFontStyle.text_20_400(
                fontFamily: AppFontFamily.gilroyBold,
              ),
            ),
          ],
        ),
      ),
      body: AppContainer(
        gradient: AppColors.backGroundColor,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: _weeks.length,
          itemBuilder: (context, index) {
            final week = _weeks[index];
            final isExpanded = _expandedIndex == index;
            final isFirst = index == 0;
            final isLast = index == _weeks.length - 1;

            return TimelineCard(
              week: week,
              isExpanded: isExpanded,
              isFirst: isFirst,
              isLast: isLast,
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
            );
          },
        ),
      ),
    );
  }
}
