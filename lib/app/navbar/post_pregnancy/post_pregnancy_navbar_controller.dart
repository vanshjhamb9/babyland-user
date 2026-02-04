import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/view/Post_pregnancy_flow/post_pre_baby_growth_view.dart';
import 'package:babyland/app/view/Pre_pregnancy_flow/aI_insights.dart';
import 'package:babyland/app/view/Pre_pregnancy_flow/mentrual_cycle.dart';
import 'package:babyland/app/view/Pregnancy_Flow/community_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/fetal_development_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/pregnancy_home_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/pregnancy_view.dart';
import 'package:babyland/app/view/profile_screen/profile_screen.dart';
// import 'package:babyland/app/view/subscription_unlock_plans/post_pregnancy/post_sub_screen.dart';
import 'package:flutter/cupertino.dart';

class PostPregnancyNavBarProvider extends ChangeNotifier{


  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  setSelectedIndex(int index){
    _selectedIndex = index;
    notifyListeners();
  }

  final List<String> labels = [
    'Home',
    'Tracker',
    'Insights',
    'Community',
    'Profile'
  ];

  final screens = [
    const PostPreBabyGrowthView(),
    const MentrualCycle(), // ✅ FIXED: Tracker now shows menstrual cycle tracker instead of subscription
    // PostSubScreen(), // ⛔ REMOVED: Subscription screen no longer in navbar
    // Center(child: const Text("Tracker Screen")),
    // const FetalDevelopmentView(),
    const AiInsights(title: "Postpartum Tips & Insights",),
     CommunityView(backButton: false,),
    ProfileScreen(stage: Stages.POSTPREGRANCY),
  ];

List<String> imagesList = [
  ImageConstants.home,
  ImageConstants.tracker,
  ImageConstants.insights,
  ImageConstants.community,
];

}