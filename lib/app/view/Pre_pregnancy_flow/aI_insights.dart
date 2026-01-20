import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/cycle_celender_controller/cycle_celender_controller.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/widgets/container.dart';
import 'package:babyland/app/controller/pre_pregenancy_flow/model/mentural_ai_insights_model.dart';
import 'package:babyland/app/widgets/custom_no_data_found.dart';
import 'package:babyland/app/widgets/general_exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/images.dart';
import '../../theme/app_colors.dart';
import '../../theme/font_family.dart';
import '../../theme/font_style.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_image.dart';

/// 🔹 Reusable shimmer box for loading effect
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
      final provider = context.read<CycleCalenderProvider>();
      provider.dashboardData();
      provider.aiInsightsApi("nutrition");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title ?? "AI Insights",
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
      body: Consumer<CycleCalenderProvider>(
        builder: (context, provider, _) {
          final status = provider.menturalAiInsights?.status;

          switch (status) {
            case ApiStatus.LOADING:
              return _buildShimmerLoading();

            case ApiStatus.ERROR:
              return GeneralExceptionWidget(onPress: ()=> provider.aiInsightsApi("nutrition"),);

            case ApiStatus.COMPLETED:
              return _buildMainContent(context, provider);

            default:
              return const SizedBox.shrink();
          }
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
                    "Ask AI",
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

  /// 🔹 Shimmer loading state
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

  /// 🔹 Main content with greeting + insights
  Widget _buildMainContent(
      BuildContext context, CycleCalenderProvider provider) {
    return AppContainer(
      color: AppColors.backgroundClr,
      gradient: AppColors.backGroundColor,
      child: RefreshIndicator(
        onRefresh: () => provider.aiInsightsApi("nutrition"),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              _buildGreetingCard(),
              const SizedBox(height: 20),
              _buildTabSection(provider),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Greeting Card
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
              const CircleAvatar(
                radius: 20,
                // backgroundImage: AssetImage(ImageConstants.girl),
              ),
              const SizedBox(width: 10),
              Consumer<GetUserProvider>(
                builder: (context,provider,_) {
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
                            text: "Hi ${provider.userData?.data?.user?.user?.name ?? ""}",
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
                }
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(Icons.error_outline,
                  color: AppColors.textLightClr, size: 20),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  "Tips are based on your Menstrual cycle & daily logs.",
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

  Widget _buildTabSection(CycleCalenderProvider provider) {
    final status = provider.menturalAiInsights?.status;
    final insights = provider.menturalAiInsights?.data?.data ?? [];

    /// 🔥 Show shimmer when loading

    if(provider.menturalAiInsights?.status == ApiStatus.LOADING){
      return _tabSectionShimmer();
    }

    if (insights.isEmpty) {
      return CustomNoDataFound(isClr: false,heightBox: SizedBox(height: 0),);
    }

    final types = insights.map((e) => e.type ?? "General").toSet().toList();
    final allTabs = ["All", ...types];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: DefaultTabController(
        initialIndex: 0,
        length: allTabs.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Left-align tabs using alignment and wrap
            Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                tabAlignment:TabAlignment.start,
                isScrollable: true,
                labelColor: AppColors.black,
                unselectedLabelColor: AppColors.lightGrey,
                tabs: allTabs.map((type) => Tab(child: textCard(type))).toList(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                indicatorColor: AppColors.black,
                indicatorPadding: const EdgeInsets.only(left: 8, right: 8),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 9),
                labelStyle: AppFontStyle.text_15_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
                unselectedLabelStyle: AppFontStyle.text_15_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color: AppColors.textLightClr,
                ),
              ),
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: allTabs.map((type) {
                  List<Data> filtered = [];

                  if (type == "All") {
                    filtered = insights;
                  } else {
                    filtered = insights.where((e) => e.type == type).toList();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _insightList(filtered),
                        const SizedBox(height: 20),
                        quickTips(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppContainer quickTips() {
    return AppContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      radius: 8,
      border: Border.all(color: AppColors.borderColor),
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomImage(
                path: ImageConstants.bulb,
                scale: 5,
              ),
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
          Text(
            "At week 16, your baby's hearing is developing rapidly. "
                "Try talking or playing gentle music - they can hear you!",
            maxLines: 3,
            style: AppFontStyle.text_12_400(
              color: AppColors.textLightClr,
              fontFamily: AppFontFamily.gilroyMedium,
            ),
          ),
        ],
      ),
    );
  }


  Widget aiInsightShimmer() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 Fake Tab Bar Shimmer
            SizedBox(
              height: 45,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                separatorBuilder: (_, __) => SizedBox(width: 12),
                itemBuilder: (_, __) => Container(
                  width: 90,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 Fake Insight Cards
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (_, __) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _tabSectionShimmer() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Shimmer Tabs
            SizedBox(
              height: 45,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => Container(
                  width: 90,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 Shimmer Insight List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Different image for each card + All tab support
  Widget _insightList(List<Data> items) {
    // 🔹 Use 3 repeating images
    final List<String> images = [
      ImageConstants.Frame,
      ImageConstants.cup,
      ImageConstants.fish,
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        final imagePath = images[index % images.length]; // 🔹 Repeat images cyclically

        return NutritionCard(
          imagePath: imagePath,
          title: item.type ?? 'Insight',
          description: item.message ?? '',
        );
      },
    );
  }

  /// 🔹 Reusable tab text
  Widget textCard(String title) {
    return Text(
      title,
      style: AppFontStyle.text_14_400(
        fontFamily: AppFontFamily.gilroySemiBold,
      ),
    );
  }
}

/// 🔹 Reusable Card for Insight Items
class NutritionCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const NutritionCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomImage(path: imagePath, scale: 4),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppFontStyle.text_15_400(
              fontFamily: AppFontFamily.gilroySemiBold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            maxLines: 5,
            style: AppFontStyle.text_13_400(
              color: AppColors.lightGrey,
              fontFamily: AppFontFamily.gilroyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
