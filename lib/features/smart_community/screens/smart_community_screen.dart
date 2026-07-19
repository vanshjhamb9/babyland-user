import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/font_family.dart';
import '../../../app/theme/font_style.dart';
import '../../../app/widgets/container.dart';
import '../../../app/widgets/custom_appbar.dart';
import '../../../app/widgets/text.dart';
import '../models/smart_post_model.dart';
import '../widgets/smart_post_card.dart';

/// AI Smart Community Feed with personalized recommendations.
class SmartCommunityScreen extends StatefulWidget {
  const SmartCommunityScreen({super.key});

  @override
  State<SmartCommunityScreen> createState() => _SmartCommunityScreenState();
}

class _SmartCommunityScreenState extends State<SmartCommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  final List<SmartPostModel> _recommendedPosts = [];
  final List<SmartPostModel> _trendingPosts = [];
  final List<SmartPostModel> _weeklyPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    // Simulated posts — will be fetched from API in production
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _recommendedPosts.addAll([
        SmartPostModel(
          id: '1',
          title: 'Managing Morning Sickness',
          content:
              'What really helped me was eating small frequent meals and staying hydrated.',
          authorName: 'Sarah M.',
          likes: 42,
          comments: 15,
          isRecommended: true,
          tags: ['first-trimester', 'nausea'],
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        SmartPostModel(
          id: '2',
          title: 'Best Prenatal Yoga Poses',
          content:
              'Cat-cow stretch and child\'s pose are my go-to for back relief!',
          authorName: 'Dr. Emma K.',
          likes: 89,
          comments: 23,
          isRecommended: true,
          tags: ['exercise', 'yoga'],
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        SmartPostModel(
          id: '3',
          title: 'Iron-Rich Foods for Pregnancy',
          content:
              'Spinach, lentils, chickpeas, and lean red meat are excellent sources.',
          authorName: 'Nutrition Expert',
          likes: 67,
          comments: 8,
          isRecommended: true,
          tags: ['nutrition', 'iron'],
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);
      _trendingPosts.addAll([
        SmartPostModel(
          id: '4',
          title: 'Hospital Bag Essentials Checklist',
          content:
              'Here\'s my complete hospital bag checklist that saved me!',
          authorName: 'Lisa T.',
          likes: 156,
          comments: 45,
          isTrending: true,
          tags: ['third-trimester', 'preparation'],
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        SmartPostModel(
          id: '5',
          title: 'Dealing with Pregnancy Insomnia',
          content: 'Pregnancy pillows and warm milk before bed have been game changers.',
          authorName: 'Amy R.',
          likes: 98,
          comments: 32,
          isTrending: true,
          tags: ['sleep', 'tips'],
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ]);
      _weeklyPosts.addAll([
        SmartPostModel(
          id: '6',
          title: 'Week 12 - End of First Trimester!',
          content:
              'Finally feeling less nauseous. Baby is the size of a lime now! 🍋',
          authorName: 'Mia L.',
          likes: 34,
          comments: 12,
          relevantWeek: 12,
          tags: ['week-12', 'milestone'],
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        SmartPostModel(
          id: '7',
          title: 'Gender Reveal at Week 20!',
          content: 'Had my anatomy scan today! Everything looks perfect.',
          authorName: 'Jen K.',
          likes: 73,
          comments: 28,
          relevantWeek: 20,
          tags: ['week-20', 'ultrasound'],
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            const Icon(Icons.people_outline, color: AppColors.buttonClr2, size: 22),
            const SizedBox(width: 8),
            GradientText(
              'Smart Community',
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
        child: Column(
          children: [
            // Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppColors.buttonClr,
                  borderRadius: BorderRadius.circular(100),
                ),
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.textLightClr,
                labelStyle: AppFontStyle.text_13_600(
                  fontFamily: AppFontFamily.gilroySemiBold,
                ),
                unselectedLabelStyle: AppFontStyle.text_13_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                ),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'For You'),
                  Tab(text: 'Trending'),
                  Tab(text: 'Weekly'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildShimmer()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostList(
                          _recommendedPosts,
                          'Recommended For You',
                          'Posts curated based on your pregnancy journey',
                        ),
                        _buildPostList(
                          _trendingPosts,
                          'Trending Discussions',
                          'Most popular posts in the community',
                        ),
                        _buildPostList(
                          _weeklyPosts,
                          'Relevant to Your Week',
                          'Posts from moms at a similar stage',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostList(
    List<SmartPostModel> posts,
    String sectionTitle,
    String subtitle,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.buttonClr2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.buttonClr2,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionTitle,
                    style: AppFontStyle.text_16_600(
                      fontFamily: AppFontFamily.gilroySemiBold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppFontStyle.text_12_400(
                      fontFamily: AppFontFamily.gilroyMedium,
                      color: AppColors.textLightClr,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Posts
        ...posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SmartPostCard(post: post),
          ),
        ),

        if (posts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No posts yet. Check back soon!',
                style: AppFontStyle.text_14_400(
                  fontFamily: AppFontFamily.gilroyMedium,
                  color: AppColors.textLightClr,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
