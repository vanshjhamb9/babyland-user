import 'package:babyland/app/constants/images.dart';
import 'package:babyland/core/constants/app_constants.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/cycle_celender_controller/cycle_celender_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/dashboard/dashboard_data_enrichment.dart';
import 'package:babyland/features/dashboard/widgets/today_summary_section.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/app/widgets/gradientprogressBar.dart';
import 'package:babyland/app/common_profile_header/profile_header.dart';
import 'package:babyland/app/widgets/sizedbox.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../../features/trackers/widgets/premium_trackers_section.dart';
import '../../../features/trackers/utils/tracker_math.dart';

class MentrualCycle extends StatefulWidget {
  const MentrualCycle({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  State<MentrualCycle> createState() => _MentrualCycleState();
}

class _MentrualCycleState extends State<MentrualCycle> with RouteAware {
  Future<DashboardData>? _dashboardFuture;

  void _syncPreDashboard(CycleCalenderProvider provider) {
    if (!mounted) return;
    final n = _todayMenstrualSymptomCount(provider);
    final sleepQ = _todayMenstrualSleepQuality(provider);
    setState(() {
      _dashboardFuture = enrichDashboardData(
        sl.dashboardService.refresh(),
        pregnancyController: null,
        preMenstrualSymptomsToday: n,
        preMenstrualSleepQualityToday: sleepQ,
      );
    });
  }

  /// Symptoms from today's menstrual mood log (dashboard API), if [logDate] is today.
  int _todayMenstrualSymptomCount(CycleCalenderProvider provider) {
    final mood = provider.dashboardMoodApiData?.data?.data;
    if (mood == null) return 0;
    final logDate = mood.logDate;
    if (logDate == null || logDate.isEmpty) return 0;
    final parsed = TrackerMath.parseDateAny(logDate);
    if (parsed == null) return 0;
    final today = DateTime.now();
    if (DateTime(parsed.year, parsed.month, parsed.day) !=
        DateTime(today.year, today.month, today.day)) {
      return 0;
    }
    return mood.symptoms?.length ?? 0;
  }

  int? _todayMenstrualSleepQuality(CycleCalenderProvider provider) {
    final mood = provider.dashboardMoodApiData?.data?.data;
    if (mood == null) return null;
    final logDate = mood.logDate;
    if (logDate == null || logDate.isEmpty) return null;
    final parsed = TrackerMath.parseDateAny(logDate);
    if (parsed == null) return null;
    final today = DateTime.now();
    if (DateTime(parsed.year, parsed.month, parsed.day) !=
        DateTime(today.year, today.month, today.day)) {
      return null;
    }
    return mood.sleepQuality;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      MentrualCycle.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    MentrualCycle.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Refresh home data when user returns to this screen (e.g. after adding daily log)
    final provider = context.read<CycleCalenderProvider>();
    provider.dashboardData();
    provider.getDashBoardAiInsights();
    provider.dashboardMoodData().then((_) {
      if (mounted) _syncPreDashboard(provider);
    });
  }

  @override
  void initState() {
    super.initState();
    _dashboardFuture = enrichDashboardData(
      sl.dashboardService.refresh(),
      pregnancyController: null,
      preMenstrualSymptomsToday: null,
      preMenstrualSleepQualityToday: null,
    );
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final now = DateTime.now();
      final p = context.read<CycleCalenderProvider>();
      await p.dashboardData();
      await p.cycleCalender(year: now.year, month: now.month);
      p.getDashBoardAiInsights();
      await p.dashboardMoodData();
      if (!mounted) return;
      _syncPreDashboard(p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProfileHeader(
        subtitle: "Track your cycle and stay healthy",
      ),
      body: Consumer<CycleCalenderProvider>(
        builder: (context, provider, _) {
          final status = provider.dashboardApiData?.status;

          switch (status) {
            case ApiStatus.LOADING:
              return AppContainer(
                  gradient: AppColors.backGroundColor,
                  child: menstrualDashboardShimmer());

            case ApiStatus.ERROR:
              return GeneralExceptionWidget(onPress: (){
                provider.dashboardData();
                provider.aiInsightsApi('nutrition');
                provider.dashboardMoodData().then((_) {
                  if (mounted) _syncPreDashboard(provider);
                });
              },);

            case ApiStatus.COMPLETED:
              return buildAppContainerData(context,provider);

            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  AppContainer buildAppContainerData(BuildContext context,CycleCalenderProvider provider) {
    return AppContainer(
      height: mediaQueryH(context),
      color: AppColors.backgroundClr,
      gradient: AppColors.backGroundColor,
      child: RefreshIndicator(
        onRefresh: () async {
          provider.aiInsightsApi('nutrition');
          await provider.dashboardData();
          await provider.dashboardMoodData();
          if (mounted) _syncPreDashboard(provider);
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 18),
              AppContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                color: AppColors.white,
                radius: 8,
                isBordered: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            CustomImage(path: ImageConstants.calender, scale: 4.7),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Menstrual cycle",
                                  style: AppFontStyle.text_14_400(
                                    fontFamily: AppFontFamily.gilroySemiBold,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  "Day ${provider.dashboardApiData?.data?.data?.daysSinceCreation ?? "0"} of cycle",
                                  style: AppFontStyle.text_12_400(
                                    fontFamily: AppFontFamily.gilroyRegular,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.cycleCalendarView,
                          ),
                          child: Text(
                            "View Calendar",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: AppFontFamily.gilroyRegular,
                              decoration: TextDecoration.underline,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GradientProgressBar(progress: double.tryParse(provider.dashboardApiData?.data?.data?.percentage ?? "0.0") ?? 0.0, height: 7),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "${provider.dashboardApiData?.data?.data?.percentage ?? "0"}%",
                          style: AppFontStyle.text_12_400(
                            fontFamily: AppFontFamily.gilroySemiBold,
                            color: AppColors.buttonClr1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Builder(
                      builder: (context) {
                        final dashboardNextPeriod = provider.dashboardApiData?.data?.data?.nextPeriodDate;
                        final data = provider.calendarApi?.data?.data;

                        // Use the old model's dedicated nextPeriod fields
                        final calendarStart = data?.nextPeriod?.start;
                        final calendarEnd = data?.nextPeriod?.end;
                        
                        // Formulate the display string (Range if possible, otherwise start date)
                        String nextPeriodDisplay = "-";
                        if (calendarStart != null && calendarStart.isNotEmpty && calendarStart != "-") {
                          final start = formatDateToDayMonth(calendarStart);
                          if (calendarEnd != null && calendarEnd.isNotEmpty && calendarEnd != "-" && calendarEnd != calendarStart) {
                            final end = formatDateToDayMonth(calendarEnd);
                            nextPeriodDisplay = "$start - $end";
                          } else {
                            nextPeriodDisplay = start;
                          }
                        } else if (dashboardNextPeriod != null && dashboardNextPeriod.isNotEmpty && dashboardNextPeriod != "-") {
                          nextPeriodDisplay = formatDateToDayMonth(dashboardNextPeriod);
                        }

                        final nextPeriodStr = (calendarStart ?? dashboardNextPeriod);

                        bool isMissed = false;
                        if (nextPeriodStr != null && nextPeriodStr.isNotEmpty && nextPeriodStr != "-") {
                          try {
                            final nextDate = DateTime.parse(nextPeriodStr);
                            final today = DateTime.now();
                            final todayDate = DateTime(today.year, today.month, today.day);
                            if (nextDate.isBefore(todayDate)) {
                              isMissed = true;
                            }
                          } catch (_) {}
                        }

                        return AppContainer(
                          radius: 8,
                          gradient: isMissed ? null : AppColors.backGroundColor,
                          color: isMissed ? Colors.red.shade50 : null,
                          borderColor: isMissed ? Colors.red : null,
                          isBordered: isMissed,
                          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMissed ? "Period Late" : "Predicted Period",
                                style: AppFontStyle.text_13_400(
                                  fontFamily: AppFontFamily.gilroySemiBold,
                                  color: isMissed ? Colors.red : AppColors.buttonClr1,
                                ),
                              ),
                              Text(
                                nextPeriodDisplay,
                                style: AppFontStyle.text_14_400(
                                  fontFamily: AppFontFamily.gilroyBold,
                                  color: isMissed ? Colors.red : AppColors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TodaySummarySection(dashboardFuture: _dashboardFuture),
              ),

              const SizedBox(height: 18),

              // Mood Section
              GestureDetector(
                onTap: () {
                  // ✅ FIXED: Navigate to Daily Logs instead of Paywall
                  Navigator.pushNamed(
                    context, 
                    AppRoutes.dailyLogs,
                    arguments: {"prePregnancyFlow": true},
                  );
                },
                child: AppContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  color: AppColors.white,
                  radius: 8,
                  isBordered: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Mood",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "How are you feeling?",
                            style: AppFontStyle.text_13_400(
                              fontFamily: AppFontFamily.gilroyRegular,
                              color: AppColors.lightGrey,
                            ),
                          ),
                        ],
                      ),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                final selectedMood = provider.dashboardMoodApiData?.data?.data?.mood;
                                String getMoodEmoji(String? mood) {
                                  Map<String, String> moodEmoji = {
                                    "great": "😄",
                                    "good": "🙂",
                                    "okay": "😐",
                                    "bad": "😞",
                                    "terrible": "😢"
                                  };
                                  final lowerMood = mood?.toLowerCase() ?? "";
                                  final emoji = moodEmoji[lowerMood] ?? "😐";
                                  print("Mood: $selectedMood → Emoji: $emoji");
                                  return emoji;
                                }
                                return Text(
                                  getMoodEmoji(selectedMood),
                                  style: TextStyle(fontSize: 24),
                                );
                              }
                            ),
                            SizedBox(width: 5),
                            (provider.dashboardMoodApiData?.data?.data?.mood?.isNotEmpty ?? false) ? AppContainer(
                              height: 26,
                              width: 58,
                              radius: 100,
                              gradient: AppColors.backGroundColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Center(
                                child: Text(
                                  provider.dashboardMoodApiData?.data?.data?.mood ?? "",
                                  style: AppFontStyle.text_13_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ) : SizedBox.shrink(),
                            if (provider.dashboardMoodApiData?.data?.data?.sleepQuality != null) ...[
                              SizedBox(width: 6),
                              AppContainer(
                                height: 26,
                                radius: 100,
                                color: AppColors.white,
                                borderColor: AppColors.borderColor,
                                isBordered: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Center(
                                  child: Text(
                                    "Sleep ${provider.dashboardMoodApiData?.data?.data?.sleepQuality}/5",
                                    style: AppFontStyle.text_12_400(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Premium hydration + mental health (below existing dashboard content)
              PremiumTrackersSection(
                stageType: TrackerStageType.pre,
                sharedDashboardFuture: _dashboardFuture,
              ),

              const SizedBox(height: 18),

              AppContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                color: AppColors.white,
                radius: 8,
                isBordered: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 56,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.aiInsights);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CustomImage(path: ImageConstants.bulb, scale: 4),

                                const SizedBox(width: 12),
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(
                                    "${AppConstants.aiAssistantDisplayName} Insights & Tips",
                                    style: AppFontStyle.text_15_400(
                                      fontFamily: AppFontFamily.gilroySemiBold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.chevron_right, size: 30),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    (provider.menstrualAiInsightsDash?.data?.dataexit?.items?.isEmpty ?? false) ?
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Center(
                        child: Text("No insights available!",
                        style: AppFontStyle.text_16_400(fontFamily: AppFontFamily.gilroyRegular),
                        ),
                      ),
                    )  :
                    ListView.separated(
                      itemCount: provider.menstrualAiInsightsDash?.data?.dataexit?.items?.length ?? 0,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        List<String> images = [ImageConstants.moon,ImageConstants.walk,ImageConstants.water];
                        final item = provider.menstrualAiInsightsDash?.data?.dataexit?.items?[index];
                      return Tile(
                        path: images[index % images.length],
                        text: item?.description ?? "",
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 0),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100,)
            ],
          ),
        ),
      ),
    );
  }


  Widget menstrualDashboardShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          shimmerBox(height: 120, width: double.infinity),
          const SizedBox(height: 12),
          shimmerBox(height: 80, width: double.infinity),
          const SizedBox(height: 12),
          shimmerBox(height: 160, width: double.infinity),
          const SizedBox(height: 12),
          shimmerBox(height: 180, width: double.infinity),
        ],
      ),
    );
  }

  /// Generic shimmer for any rectangular placeholder
  Widget shimmerBox({
    double? width,
    double? height,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey,
      highlightColor: AppColors.grey,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.grey.withAlpha(100),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class Tile extends StatelessWidget {
  final String path;
  final String text;

  const Tile({super.key, required this.path, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: AppColors.backGroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppContainer(
            height: 25,
            width: 25,
            radius: 100,
            color: Colors.white,
            child: Center(child: CustomImage(path: path, scale: 4)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              style: AppFontStyle.text_12_400(
                fontFamily: AppFontFamily.gilroyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
