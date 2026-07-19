import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/view/Pre_pregnancy_flow/aI_insights.dart';
import 'package:babyland/app/view/Pregnancy_Flow/community_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/fetal_development_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/pregnancy_home_view.dart';
import 'package:babyland/app/view/profile_screen/profile_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:babyland/app/view/shop/shop_screen.dart';

class NavBarProvider extends ChangeNotifier{


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
    'Shop',
    'Profile'
  ];

  final screens = [
    const PregnancyHomeView(),
    const FetalDevelopmentView(), // ✅ FIXED: Replaced subscription screen with tracker
    // PregnancySubScreen(backButton: false,), ⛔ REMOVED
    // Center(child: const Text("Tracker Screen")),
    // const FetalDevelopmentView(),
    const AiInsights(),
     CommunityView(backButton: false,),
    const ShopScreen(),
    ProfileScreen(stage: Stages.PREGRANCY),
  ];

List<String> imagesList = [
  ImageConstants.home,
  ImageConstants.tracker,
  ImageConstants.insights,
  ImageConstants.community,
];

}