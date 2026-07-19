import 'package:babyland/app/navbar/pregnancy/navbar_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/widgets/app_popup.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:babyland/core/di/service_locator.dart';
import 'package:babyland/core/services/dashboard_service.dart';
import 'package:babyland/features/dashboard/dashboard_data_enrichment.dart';
import 'package:babyland/features/dashboard/dashboard_theme.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_recommendations_section.dart';
import 'package:babyland/features/dashboard/widgets/dashboard_soft_card.dart';
import 'package:babyland/features/dashboard/widgets/pregnancy_stage_hero.dart';
import 'package:babyland/features/dashboard/widgets/today_summary_section.dart';
import 'package:babyland/features/dashboard/widgets/tracker_category_section.dart';
import 'package:babyland/features/trackers/utils/tracker_math.dart';
import 'package:babyland/features/trackers/widgets/premium_trackers_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/images.dart';
import '../../controller/pregnancy_flow/pregnancy_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/container.dart';
import '../../widgets/custom_cont.dart';
import '../../common_profile_header/profile_header.dart';

class PregnancyHomeView extends StatefulWidget {
  const PregnancyHomeView({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

  @override
  State<PregnancyHomeView> createState() => _PregnancyHomeViewState();
}

class _PregnancyHomeViewState extends State<PregnancyHomeView> with RouteAware {
  /// Shared with tracker cards & charts to avoid duplicate dashboard fetches.
  Future<DashboardData>? _dashboardFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      PregnancyHomeView.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    PregnancyHomeView.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    final controller = context.read<PregnancyController>();
    controller.getPregnancyApiData();
    controller.getAppointmentApi();
    setState(() {
      _dashboardFuture = enrichDashboardData(
        sl.dashboardService.refresh(),
        pregnancyController: context.read<PregnancyController>(),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _dashboardFuture = enrichDashboardData(
      sl.dashboardService.refresh(),
      pregnancyController: null,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<PregnancyController>(context, listen: false);
      await controller.getPregnancyApiData();

      final response = controller.pregnancyApiData;
      final data = response?.data?.data?.data;

      if (data == null && mounted) {
        AppPopUp.showToast(message: "Session error: Please sign in again.");
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.signInView,
          (route) => false,
        );
        return;
      }
      if (mounted) {
        setState(() {
          _dashboardFuture = enrichDashboardData(
            sl.dashboardService.refresh(),
            pregnancyController: controller,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTheme.canvas,
      appBar: ProfileHeader(
        subtitle: "Welcome to your pregnancy journey",
      ),
      body: AppContainer(
        color: DashboardTheme.canvas,
        gradient: AppColors.backGroundColor,
        child: Consumer<PregnancyController>(
          builder: (context, provider, child) {
            if (provider.isLoadingPreg) {
              return _buildShimmer();
            }

            if (provider.pregnancyApiData?.status == ApiStatus.ERROR) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    provider.pregnancyApiData?.message ?? "Something went wrong!",
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final data = provider.pregnancyApiData?.data?.data?.data;

            if (data == null) {
              return const Center(child: Text("No pregnancy data available."));
            }

            final currentWeek = data.currentWeek ?? "0";
            final trimester = data.trimester ?? "0";
            final expectedDueDate = data.expectedDueDate ?? "";
            final fetalGrowthStage = data.fetalGrowthStage ?? "";
            final predictions = data.predictions;
            
            // ─── DEBUG LOGS ──────────────────────────────────────
            pt("Pregnancy Dashboard Debug:");
            pt("  Current Week (from API): $currentWeek");
            pt("  Trimester: $trimester");
            pt("  Expected Due Date: $expectedDueDate");
            pt("  Days Since Start: ${data.daysSinceStart}");
            pt("  Fetal Growth Stage: $fetalGrowthStage");
            if (data.tracker != null) {
              pt("  Tracker Start Date: ${data.tracker!.pregnancyStartDate}");
              final startDate = TrackerMath.parseDateAny(data.tracker!.pregnancyStartDate);
              if (startDate != null) {
                final calcWeek = TrackerMath.calculatePregnancyWeek(startDate, DateTime.now());
                pt("  Calculated Week (Client): $calcWeek");
                if (currentWeek == "3" && calcWeek != 3) {
                  pt("  WARNING: API returned Week 3 but calculated week is $calcWeek");
                }
              }
              pt("  Tracker Current Week: ${data.tracker!.currentWeek}");
            }
            // ────────────────────────────────────────────────────
            final progress = double.tryParse(data.percentage.toString()) ?? 0.0;

            return RefreshIndicator(
              color: DashboardTheme.accentRose,
              onRefresh: () async {
                await provider.getPregnancyApiData();
                setState(() {
                  _dashboardFuture = enrichDashboardData(
                    sl.dashboardService.refresh(),
                    pregnancyController: provider,
                  );
                });
                await _dashboardFuture;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Dashboard',
                        style: AppFontStyle.text_18_400(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: DashboardTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.fetalDevelopmentView),
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
                        child: PregnancyStageHero(
                          currentWeek: currentWeek,
                          trimester: trimester,
                          expectedDueDate: expectedDueDate,
                          fetalGrowthStage: fetalGrowthStage,
                          fetalSizeLine: predictions?.fetalSize,
                          progressPercent: progress,
                        ),
                      ),
                    ),
                    if ((data.mood ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DashboardSoftCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.sentiment_satisfied_alt_outlined, color: DashboardTheme.accentRose.withValues(alpha: 0.95)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Today’s mood: ${data.mood}',
                                  style: AppFontStyle.text_14_400(
                                    fontFamily: AppFontFamily.gilroyMedium,
                                    color: DashboardTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: DashboardTheme.sectionGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TodaySummarySection(dashboardFuture: _dashboardFuture),
                    ),
                    SizedBox(height: DashboardTheme.sectionGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TrackerCategorySection(dashboardFuture: _dashboardFuture),
                    ),
                    const SizedBox(height: 16),
                    PremiumTrackersSection(
                      stageType: TrackerStageType.pregnancy,
                      sharedDashboardFuture: _dashboardFuture,
                    ),
                    SizedBox(height: DashboardTheme.sectionGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.appointmentView),
                            borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                            child: CustomCont(
                              title: "Appointments",
                              path: ImageConstants.appointement,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              context.read<NavBarProvider>().setSelectedIndex(3);
                            },
                            borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                            child: CustomCont(
                              title: "Community",
                              path: ImageConstants.community_clr,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => context.read<NavBarProvider>().setSelectedIndex(2),
                            borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                            child: DashboardSoftCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.insights_outlined, color: DashboardTheme.textPrimary.withValues(alpha: 0.75)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Full AI insights',
                                      style: AppFontStyle.text_15_400(
                                        fontFamily: AppFontFamily.gilroySemiBold,
                                        color: DashboardTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: DashboardTheme.textSecondary.withValues(alpha: 0.6)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: DashboardTheme.sectionGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DashboardRecommendationsSection(
                        pregnancyInsights: data.tracker?.aiInsights,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 120,
              height: 20,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
            ),
          ),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
