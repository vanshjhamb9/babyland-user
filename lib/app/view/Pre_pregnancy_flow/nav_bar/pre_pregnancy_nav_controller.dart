import 'package:babyland/app/constants/images.dart';
import 'package:babyland/app/data/response/status.dart';
import 'package:babyland/app/view/Pre_pregnancy_flow/aI_insights.dart';
import 'package:babyland/app/view/Pregnancy_Flow/community_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/pregnancy_home_view.dart';
import 'package:babyland/app/view/subscription_unlock_plans/pregnancy/pregnancy_sub_screen.dart';
import 'package:flutter/cupertino.dart';

import '../../profile_screen/profile_screen.dart';
import '../Mentrual_cycle.dart';
import '../cycle_calendar/cycle_calendar_view.dart';

class PrePregancyNavBarProvider extends ChangeNotifier{


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
    const MentrualCycle(),
    CycleCalendarView(),
    const AiInsights(),
     CommunityView(backButton: false,),
    ProfileScreen(stage: Stages.PREPREGRANCY),
  ];

  List<String> imagesList = [
    ImageConstants.home,
    ImageConstants.tracker,
    ImageConstants.insights,
    ImageConstants.community,
  ];

}