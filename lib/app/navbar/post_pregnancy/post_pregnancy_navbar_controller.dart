import 'package:babyland/app/constants/images.dart';
import 'package:babyland/core/constants/app_constants.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/view/Post_pregnancy_flow/post_pre_baby_growth_view.dart';
import 'package:babyland/app/view/Pre_pregnancy_flow/aI_insights.dart';
import 'package:babyland/app/view/Pregnancy_Flow/community_view.dart';
import 'package:babyland/app/view/profile_screen/profile_screen.dart';
// import 'package:babyland/app/view/subscription_unlock_plans/post_pregnancy/post_sub_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:babyland/app/view/shop/shop_screen.dart';

class PostPregnancyNavBarProvider extends ChangeNotifier{


  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  setSelectedIndex(int index){
    _selectedIndex = index;
    notifyListeners();
  }

  final List<String> labels = [
    'Home',
    'Insights',
    'Community',
    'Shop',
    'Profile',
  ];

  final screens = [
    const PostPreBabyGrowthView(),
    AiInsights(
      title:
          "Postpartum Tips & ${AppConstants.aiAssistantDisplayName} Insights",
    ),
     CommunityView(backButton: false,),
    const ShopScreen(),
    ProfileScreen(stage: Stages.POSTPREGRANCY),
  ];

List<String> imagesList = [
  ImageConstants.home,
  ImageConstants.insights,
  ImageConstants.community,
];

}