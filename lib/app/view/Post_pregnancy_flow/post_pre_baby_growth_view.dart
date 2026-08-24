import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/core/constants/app_constants.dart';
import 'package:babyland/app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/widgets/gradient_checkbox.dart';
import 'package:babyland/features/post_pregnancy/widgets/recovery_insight_cards.dart';
import 'package:babyland/app/widgets/validation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/images.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../features/post_pregnancy/postpartum_dashboard_enrichment.dart';
import '../../../features/post_pregnancy/state/postpartum_dashboard_notifier.dart';
import '../../../features/post_pregnancy/widgets/postpartum_recovery_analytics_sheet.dart';
import '../../../features/post_pregnancy/widgets/postpartum_recovery_hero.dart';
import '../../../features/trackers/widgets/premium_trackers_section.dart';
import '../../../features/trackers/utils/tracker_math.dart';
import '../../widgets/button.dart';
import '../../widgets/container.dart';
import '../../widgets/custom_cont.dart';
import '../../widgets/custom_image.dart';
import '../../widgets/feeding_entry_dialog.dart';
import '../../widgets/feeding_details_dialog.dart';
import '../../common_profile_header/profile_header.dart';
import '../../controller/pre_pregenancy_flow/model/daily_logs_mentural_model.dart';

/// Resolves today's postpartum log (supports yyyy-MM-dd and legacy formats).
Data? _postpartumLogForToday(List<Data>? logs) {
  if (logs == null || logs.isEmpty) return null;
  final todayKey = TrackerMath.dayKey(DateTime.now());
  for (final log in logs) {
    final d = TrackerMath.parseDateAny(log.date);
    if (d != null && TrackerMath.dayKey(d) == todayKey) {
      return log;
    }
  }
  return null;
}

class PostPreBabyGrowthView extends StatefulWidget {
  const PostPreBabyGrowthView({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  State<PostPreBabyGrowthView> createState() => _PostPreBabyGrowthViewState();
}

class _PostPreBabyGrowthViewState extends State<PostPreBabyGrowthView> with RouteAware {
  bool isChecked1 = false;
  bool isChecked2 = false;
  bool isChecked3 = false;
  Future<DashboardData>? _enrichedDashboardFuture;
  int _trackersRefreshToken = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      PostPreBabyGrowthView.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    PostPreBabyGrowthView.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    final pp = context.read<PostpregnancyProvider>();
    await Future.wait([
      pp.getFeedingApi(),
      pp.getRecoveryTaskApi(),
      pp.getDashboardLogsApi(),
    ]);
    if (!mounted) return;
    await context.read<PostpartumDashboardNotifier>().refresh(
      recoveryTask: pp.getRecoveryApiData?.data,
      dashboardLogs: pp.dashboardLogsApiData?.data,
      force: true,
    );
    if (!mounted) return;
    _rebuildDashboardFuture(pp);
    setState(() => _trackersRefreshToken++);
  }

  void _rebuildDashboardFuture(PostpregnancyProvider pp) {
    setState(() {
      _enrichedDashboardFuture = enrichPostpartumDashboard(
        sl.dashboardService.refresh(),
        logs: pp.dashboardLogsApiData?.data?.data,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final pp = context.read<PostpregnancyProvider>();
      pp.getFeedingApi();
      pp.getDashboardLogsApi();
      await pp.getRecoveryTaskApi();
      if (!mounted) return;
      await context.read<PostpartumDashboardNotifier>().refresh(
        recoveryTask: pp.getRecoveryApiData?.data,
        dashboardLogs: pp.dashboardLogsApiData?.data,
      );
      if (mounted) _rebuildDashboardFuture(pp);
    });
  }

  Future<void> _openRecoveryAnalytics(
    BuildContext context,
    PostpregnancyProvider provider,
    String? userId,
  ) async {
    final dash = context.read<PostpartumDashboardNotifier>();
    if (dash.snapshot == null) {
      await dash.refresh(
        recoveryTask: provider.getRecoveryApiData?.data,
        dashboardLogs: provider.dashboardLogsApiData?.data,
      );
    }
    if (!context.mounted) return;
    final snap = dash.snapshot;
    if (snap == null) return;
    await PostpartumRecoveryAnalyticsSheet.show(
      context,
      snapshot: snap,
      taskProvider: provider,
      userId: userId,
    );
    if (context.mounted) _refreshDashboard();
  }

  Future<void> _logDailyProgress(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.postpartumJournal);
    if (context.mounted) _refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GetUserProvider>();

    final id = provider.userData?.data?.user?.user?.sId.toString();
    return Scaffold(
      appBar: ProfileHeader(
        subtitle: "Here is your post pregnancy journey." /*img: false,*/,
      ),
      body: Consumer<PostpregnancyProvider>(
        builder: (context, provider, _) {
          return AppContainer(
            color: AppColors.backgroundClr,
            gradient: AppColors.backGroundColor,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Dashboard",
                      style: AppFontStyle.text_16_400(
                        fontFamily: AppFontFamily.gilroySemiBold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<PostpartumDashboardNotifier>(
                    builder: (context, dash, _) {
                      return PostpartumRecoveryHero(
                        snapshot: dash.snapshot,
                        isLoading: dash.isLoading,
                        onViewAnalytics: () => _openRecoveryAnalytics(
                          context,
                          provider,
                          id,
                        ),
                        onLogProgress: () => _logDailyProgress(context),
                      );
                    },
                  ),
                  Consumer<PostpartumDashboardNotifier>(
                    builder: (context, dash, _) {
                      if (dash.snapshot == null || dash.snapshot!.insights.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RecoveryInsightCards(
                          insights: dash.snapshot!.insights.take(2).toList(),
                        ),
                      );
                    },
                  ),

                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Mood",
                                style: AppFontStyle.text_15_600(
                                  fontFamily: AppFontFamily.gilroyMedium,
                                  color: AppColors.textClr,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "How are you feeling?",
                                style: AppFontStyle.text_14_400(
                                  fontFamily: AppFontFamily.gilroyRegular,
                                  color: AppColors.textLightClr,
                                ),
                              ),
                            ],
                          ),
                          ),
                          Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Builder(
                                  builder: (context) {
                                    // Read mood from daily logs (correct source) with fallback to recovery tasks
                                    final logs = provider.dashboardLogsApiData?.data?.data;
                                    final todayLog = _postpartumLogForToday(logs);
                                    final moodFromLog = todayLog?.mood?.isNotEmpty == true
                                        ? todayLog?.mood
                                        : todayLog?.mentalHealth?.mood;
                                    final selectedMood = (moodFromLog?.isNotEmpty == true)
                                        ? moodFromLog
                                        : provider.getRecoveryApiData?.data?.tasks?.mood;
                                    String getMoodEmoji(String? mood) {
                                      const moodEmoji = {
                                        "great": "😄",
                                        "good": "🙂",
                                        "okay": "😐",
                                        "bad": "😞",
                                        "terrible": "😢",
                                      };
                                      return moodEmoji[mood?.toLowerCase() ?? ""] ?? "😐";
                                    }
                                    return Text(
                                      getMoodEmoji(selectedMood),
                                      style: const TextStyle(fontSize: 24),
                                    );
                                  }
                                ),
                                SizedBox(width: 5),
                                Builder(
                                  builder: (context) {
                                    final logs = provider.dashboardLogsApiData?.data?.data;
                                    final todayLog = _postpartumLogForToday(logs);
                                    final moodFromLog = todayLog?.mood?.isNotEmpty == true
                                        ? todayLog?.mood
                                        : todayLog?.mentalHealth?.mood;
                                    final mood = (moodFromLog?.isNotEmpty == true)
                                        ? moodFromLog
                                        : provider.getRecoveryApiData?.data?.tasks?.mood;
                                    if (mood == null || mood.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Flexible(
                                      child: Container(
                                        constraints: const BoxConstraints(maxWidth: 120),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(100),
                                          gradient: AppColors.backGroundColor,
                                        ),
                                        child: Text(
                                          mood,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFontStyle.text_12_600(
                                            fontFamily: AppFontFamily.gilroyRegular,
                                            color: AppColors.textClr,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Premium hydration + mental health (below existing dashboard content)
                  PremiumTrackersSection(
                    key: ValueKey('post_trackers_$_trackersRefreshToken'),
                    stageType: TrackerStageType.post,
                    sharedDashboardFuture: _enrichedDashboardFuture,
                    recoverySnapshot: context.watch<PostpartumDashboardNotifier>().snapshot,
                    refreshToken: _trackersRefreshToken,
                  ),

                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CustomImage(
                                    path: ImageConstants.feeding,
                                    scale: 5,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Feeding Today",
                                    style: AppFontStyle.text_15_600(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.textClr,
                                    ),
                                  ),
                                ],
                              ),
                              Button(
                                height: 36,
                                width: 84,
                                text: "+ Add",
                                padding: EdgeInsets.all(9),
                                textStyle: AppFontStyle.text_12_400(
                                  fontFamily: AppFontFamily.gilroyBold,
                                  color: AppColors.white,
                                ),
                                onTap: () async {
                                  final result = await showDialog(
                                    context: context,
                                    builder: (context) => FeedingEntryDialog(),
                                  );
                                  if (result == true && context.mounted) {
                                    await provider.getRecoveryTaskApi();
                                    await provider.getFeedingApi();
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          if (provider.getRecoveryApiData?.status ==
                              ApiStatus.LOADING) ...[
                            noLogsShimmer(),
                          ] else ...[
                            if (provider
                                    .getRecoveryApiData
                                    ?.data
                                    ?.tasks
                                    ?.feedings
                                    ?.isEmpty ??
                                false) ...[
                              AppContainer(
                                height: 53,
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                radius: 8,
                                color: AppColors.white,
                                isBordered: true,
                                child: Center(
                                  child: Text(
                                    "No Logs yet",
                                    style: AppFontStyle.text_12_400(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.textLightClr,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount:
                                  provider
                                      .getRecoveryApiData
                                      ?.data
                                      ?.tasks
                                      ?.feedings
                                      ?.length ??
                                  0,
                              itemBuilder: (context, index) {
                                final feeding = provider.getRecoveryApiData?.data?.tasks?.feedings?[index];
                                return AppContainer(
                                  onTap: () {
                                    if (feeding != null) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => FeedingDetailsDialog(feeding: feeding),
                                      );
                                    }
                                  },
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 13,
                                  ),
                                  radius: 8,
                                  gradient: AppColors.backGroundColor,
                                  child: Text(
                                    "${capitalizeFirstLetter(provider.getRecoveryApiData?.data?.tasks?.feedings?[index].notes ?? "")} (${capitalizeFirstLetter(provider.getRecoveryApiData?.data?.tasks?.feedings?[index].type ?? "")})",
                                    style: AppFontStyle.text_14_500(
                                      fontFamily: AppFontFamily.gilroyMedium,
                                      color: AppColors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.postAppointmentView);
                    },
                    child: CustomCont(
                      title: "Appointments",
                      path: ImageConstants.appointement,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.babyGrowthSummaryView);
                      // context.read<BabyGrowthProvider>().addBabyDataInitial();
                    },
                    child: CustomCont(
                      title: "Baby Growth Tracker",
                      path: ImageConstants.baby_growth,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppColors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 56,
                            child: InkWell(
                              onTap: () {
                                //  Navigator.pushNamed(context, AppRoutes.aiInsights);
                              },
                              child: Row(
                                children: [
                                  CustomImage(
                                    path: ImageConstants.postPreAiInsights,
                                    scale: 5,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "Postpartum Tips & ${AppConstants.aiAssistantDisplayName} Insights",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFontStyle.text_14_400(
                                        fontFamily: AppFontFamily.gilroySemiBold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 30,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppContainer(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 13,
                            ),
                            radius: 8,
                            gradient: AppColors.backGroundColor,
                            child: Text(
                              "Stay hydrated and eat nutritious meals."
                              " Your body is healing and needs proper fuel to recover effectively.",
                              maxLines: 3,
                              style: AppFontStyle.text_12_400(
                                fontFamily: AppFontFamily.gilroyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget customCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    double size = 30,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // AppContainer(
          //   width: size,
          //   height: size,
          //   border: Border.all(color: AppColors.greyStroke, width: 1),
          //   radius: 4,
          //   gradient: value ? AppColors.buttonClr : null,
          //   color: value ? null : Colors.transparent,
          //   child: value
          //       ? Icon(Icons.check, size: size * 0.7, color: Colors.white)
          //       : null,
          // ),
          GradientCheckbox(value: value, onChanged: onChanged, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppFontFamily.gilroySemiBold,
                    decoration: value ? TextDecoration.lineThrough : null,
                    color: value
                        ? AppColors.black.withAlpha(65)
                        : AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Text(
                //   subtitle,
                //   style: TextStyle(
                //     fontSize: 11,
                //     fontFamily: AppFontFamily.gilroyMedium,
                //     fontWeight: FontWeight.w400,
                //     color: AppColors.textLightClr,
                //   ),
                //   maxLines: 1,
                //   overflow: TextOverflow.ellipsis,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget noLogsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: AppContainer(
        height: 53,
        width: double.infinity,
        padding: EdgeInsets.all(16),
        radius: 8,
        color: AppColors.white,
        isBordered: true,
        child: Center(
          child: Container(
            height: 12,
            width: 80, // approx size of "No Logs yet"
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
