import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/constants/images.dart';
import 'package:babyland/core/constants/app_constants.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/mentural_ai_insights_model.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/widgets/custom_image.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:babyland/features/ai_insights/controllers/dynamic_ai_insights_controller.dart';
import 'package:babyland/features/ai_insights/widgets/dynamic_insight_card.dart';
import 'package:babyland/features/ai_insights/widgets/dynamic_insight_category_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/custom_appbar.dart';

Widget shimmerBox({
  double? width,
  double? height,
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
}) {
  return Shimmer.fromColors(
    baseColor: AppColors.buttonClr2.withAlpha(80),
    highlightColor: AppColors.buttonClr2.withAlpha(40),
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.buttonClr2.withAlpha(100),
        borderRadius: borderRadius,
      ),
    ),
  );
}

class AiInsights extends StatefulWidget {
  final String? title;
  const AiInsights({super.key, this.title});

  @override
  State<AiInsights> createState() => _AiInsightsState();
}

class _AiInsightsState extends State<AiInsights> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = context.read<DynamicAiInsightsController>();
      c.setPregnancyWeekResolver(() {
        if (!context.mounted) return null;
        return _pregnancyWeekForInsightsQuery(context);
      });
      c.onScreenOpened();
    });
  }

  /// Optional `week` query 1–42 for GET /api/v1/ai/insights (server defaults if omitted).
  int? _pregnancyWeekForInsightsQuery(BuildContext context) {
    final wrap = context.read<GetUserProvider>().userData?.data?.user;
    if (wrap == null) return null;
    final rawMap = wrap.pregnancyTracker;
    if (rawMap is! Map) return null;
    final m = Map<String, dynamic>.from(rawMap as Map);
    final raw = m['pregnancy_week'] ?? m['pregnancyWeek'];
    final w = int.tryParse(raw?.toString() ?? '');
    if (w == null || w < 1 || w > 42) return null;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isNavbarTab: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title ?? '${AppConstants.aiAssistantDisplayName} Insights',
              style: AppFontStyle.text_20_400(
                color: AppColors.textClr,
                fontFamily: AppFontFamily.gilroySemiBold,
              ),
            ),
            const SizedBox(width: 7),
            CustomImage(path: ImageConstants.star, scale: 3),
          ],
        ),
      ),
      body: Consumer<DynamicAiInsightsController>(
        builder: (context, ctrl, _) {
          if (ctrl.isLoading && ctrl.entries.isEmpty) {
            return _buildShimmerLoading();
          }

          if (ctrl.error != null && ctrl.entries.isEmpty) {
            return GeneralExceptionWidget(onPress: () => ctrl.refresh());
          }

          return _buildMainContent(context, ctrl);
        },
      ),
      floatingActionButton: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiAssistantView),
        child: AppContainer(
          color: AppColors.white,
          radius: 100,
          child: AppContainer(
            gradient: AppColors.backGroundColor,
            borderColor: AppColors.buttonClr1,
            radius: 100,
            height: 44,
            width: 107,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ask ${AppConstants.aiAssistantDisplayName}',
                    style: AppFontStyle.text_14_400(
                      color: AppColors.black,
                      fontFamily: AppFontFamily.gilroyMedium,
                    ),
                  ),
                  const SizedBox(width: 4),
                  CustomImage(path: ImageConstants.star, scale: 4),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildShimmerLoading() {
    return AppContainer(
      color: AppColors.backgroundClr,
      gradient: AppColors.backGroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ListView.separated(
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, index) => shimmerBox(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    DynamicAiInsightsController ctrl,
  ) {
    return AppContainer(
      color: AppColors.backgroundClr,
      gradient: AppColors.backGroundColor,
      child: RefreshIndicator(
        onRefresh: () => ctrl.refresh(),
        color: AppColors.buttonClr1,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildGreetingCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: DynamicInsightCategoryChips(
                selected: ctrl.selectedCategory,
                onSelected: ctrl.selectCategory,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (ctrl.isLoading && ctrl.entries.isNotEmpty)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.buttonClr1,
                  backgroundColor: AppColors.greyLight,
                ),
              ),
            if (!ctrl.isLoading && ctrl.entries.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 48,
                        color: AppColors.textLightClr.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No insights yet',
                        textAlign: TextAlign.center,
                        style: AppFontStyle.text_16_600(
                          fontFamily: AppFontFamily.gilroySemiBold,
                          color: AppColors.textClr,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We couldn\'t load tips for this category. Pull to refresh or try again later.',
                        textAlign: TextAlign.center,
                        style: AppFontStyle.text_13_400(
                          fontFamily: AppFontFamily.gilroyRegular,
                          color: AppColors.textLightClr,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (ctrl.entries.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ...ctrl.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DynamicInsightCard(entry: e),
                        ),
                      ),
                      if (ctrl.quickTip != null) ...[
                        _quickTipCard(ctrl.quickTip!),
                        const SizedBox(height: 100),
                      ] else
                        const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return AppContainer(
      height: 114,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      radius: 8,
      isBordered: true,
      color: AppColors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 20),
              const SizedBox(width: 10),
              Consumer<GetUserProvider>(
                builder: (context, provider, _) {
                  return Expanded(
                    child: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: AppFontStyle.text_15_400(
                          fontFamily: AppFontFamily.gilroySemiBold,
                        ),
                        children: [
                          TextSpan(
                            text:
                                "Hi ${provider.userData?.data?.user?.user?.name ?? ""}",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroySemiBold,
                            ),
                          ),
                          TextSpan(
                            text:
                                ", here's what's best for you to stay Healthy & Fit.",
                            style: AppFontStyle.text_15_400(
                              fontFamily: AppFontFamily.gilroyRegular,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.textLightClr,
                size: 20,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  "Tips are based on your cycle, daily logs, and selected category.",
                  style: AppFontStyle.text_11_400(
                    fontFamily: AppFontFamily.gilroyRegular,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickTipCard(QuickTip tip) {
    return AppContainer(
      margin: EdgeInsets.zero,
      radius: 8,
      border: Border.all(color: AppColors.borderColor),
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomImage(path: ImageConstants.bulb, scale: 5),
              const SizedBox(width: 10),
              Text(
                "Quick Tip",
                style: AppFontStyle.text_15_400(
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tip.emoji != null) ...[
                Text(tip.emoji!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  tip.text ?? "",
                  maxLines: 8,
                  style: AppFontStyle.text_12_400(
                    color: AppColors.textLightClr,
                    fontFamily: AppFontFamily.gilroyMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
