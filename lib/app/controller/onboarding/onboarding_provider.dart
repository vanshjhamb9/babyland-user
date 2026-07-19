import 'package:babyland/app/constants/images.dart';
import 'package:babyland/core/constants/app_constants.dart';
import 'package:flutter/cupertino.dart';

class OnboardingProvider extends ChangeNotifier{

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  void updateIndex(int value){
    _currentIndex = value;
    notifyListeners();
  }

  bool _isFirstTime = false;
  bool get isFirstTime => _isFirstTime;
  setFirstTime(bool isFirstTime){
    _isFirstTime = isFirstTime;
    notifyListeners();
  }

  final List<Map<String, String>> onboardingData = [
    {
      "title": "BabyLand! Your Personal Health Tracker",
      "description": "Take control of your health with BabyLand. Track your period, monitor ovulation, and gain insights into your body’s natural rhythms.",
      "image": ImageConstants.onboarding_11,
    },
    {
      "title": "Track and Record with Ease in One Place",
      "description": "Effortlessly log your daily symptoms, moods, and activities. Use the intuitive calendar to keep track of your cycle and monitor.",
      "image": ImageConstants.onboarding_2,
    },
    {
      "title": "${AppConstants.aiAssistantDisplayName} — your wellness companion",
      "description": "Personalized care and guidance for you and your baby’s journey.",
      "image": ImageConstants.onboarding_3
    },{
      "title": "Community Support",
      "description": "Celebrate your highs, offer support, and share incredible experience of bringing new lives.",
      "image": ImageConstants.communitySupport
    },{
      "title": "Instant Expert Medical Support",
      "description": "Get trusted medical advice tailored to your needs—right from your phone.",
      "image": ImageConstants.onboarding_4
    },
  ];
}