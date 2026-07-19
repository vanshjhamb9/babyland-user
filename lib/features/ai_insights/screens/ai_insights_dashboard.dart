import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../app/widgets/custom_appbar.dart';
import '../../../app/widgets/text.dart';
import '../../../core/constants/app_constants.dart';
import '../controllers/ai_insights_controller.dart';
import '../widgets/daily_guidance_widget.dart';
import '../widgets/insight_card.dart';
import '../widgets/insight_filter_chips.dart';

/// AI Pregnancy Insights Dashboard screen.
///
/// Displays:
/// - Baby growth insights
/// - Weekly development information
/// - Recommended nutrition
/// - Recommended exercises
/// - Medical reminders
/// - Daily AI guidance
class AiInsightsDashboard extends StatefulWidget {
  const AiInsightsDashboard({super.key});

  @override
  State<AiInsightsDashboard> createState() => _AiInsightsDashboardState();
}

class _AiInsightsDashboardState extends State<AiInsightsDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AiInsightsController>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        toolbarHeight: 70,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.buttonClr2, size: 22),
            const SizedBox(width: 8),
            GradientText(
              '${AppConstants.aiAssistantDisplayName} Pregnancy Insights',
              gradient: AppColors.buttonClr,
              style: AppFontStyle.text_20_400(
                fontFamily: AppFontFamily.gilroyBold,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<AiInsightsController>(
        builder: (context, controller, _) {
          return RefreshIndicator(
            onRefresh: () => controller.refreshAll(),
            color: AppColors.buttonClr2,
            child: AppContainer(
              gradient: AppColors.backGroundColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ─── Daily Guidance Section ────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: DailyGuidanceWidget(
                        guidance: controller.dailyGuidance,
                        isLoading: controller.isGuidanceLoading,
                      ),
                    ),
                  ),

                  // ─── Section Header ────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.buttonClr2.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.insights,
                              color: AppColors.buttonClr2,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Health Insights',
                            style: AppFontStyle.text_18_600(
                              fontFamily: AppFontFamily.gilroyBold,
                              color: AppColors.textClr,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Filter Chips ──────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InsightFilterChips(
                        selectedFilter: controller.selectedFilter,
                        onFilterChanged: controller.setFilter,
                      ),
                    ),
                  ),

                  // ─── Insights List ─────────────────────
                  if (controller.isLoading)
                    SliverToBoxAdapter(child: _buildInsightsShimmer())
                  else if (controller.error != null &&
                      controller.insights.isEmpty)
                    SliverToBoxAdapter(child: _buildError(controller))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final insight =
                                controller.filteredInsights[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InsightCard(insight: insight),
                            );
                          },
                          childCount: controller.filteredInsights.length,
                        ),
                      ),
                    ),

                  // Bottom spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(AiInsightsController controller) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(
            controller.error ?? 'Something went wrong',
            style: AppFontStyle.text_14_400(
              fontFamily: AppFontFamily.gilroyMedium,
              color: AppColors.textLightClr,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.refreshAll(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonClr2,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
