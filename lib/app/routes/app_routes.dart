import 'package:babyland/app/view/Post_pregnancy_flow/post_pre_addAppointment.dart';
import 'package:babyland/app/view/Post_pregnancy_flow/post_pre_baby_growth_view.dart';
import 'package:babyland/app/view/Post_pregnancy_flow/post_pregnancy_pageview.dart';
import 'package:babyland/app/view/Pregnancy_Flow/addreminder_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/appointment_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/pregnancy_home_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/savelog_view.dart';
import 'package:babyland/app/view/expert_consultation/records/records_view.dart';
import 'package:babyland/app/view/expert_consultation/report/report_view.dart';
import 'package:babyland/app/navbar/pregnancy/navbar.dart';
import 'package:babyland/app/view/Post_pregnancy_flow/baby_detail_view.dart';
import 'package:babyland/app/view/Post_pregnancy_flow/post_pregnancy_view.dart';
import 'package:babyland/app/view/Pre_pregnancy_flow/Daily_Logs.dart';
import 'package:babyland/app/view/Pre_pregnancy_flow/Mentrual_cycle.dart';
import 'package:babyland/app/view/Pre_pregnancy_flow/cycle_calendar/cycle_calendar_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/fetal_development_view.dart';
import 'package:babyland/app/view/Pregnancy_Flow/pregnancy_view.dart';
import 'package:babyland/app/view/ai_assistant/ai_assistant_view.dart';
import 'package:babyland/app/view/baby_growth/baby_growth_view/baby_growth_summary_view.dart';
import 'package:babyland/app/view/baby_growth/baby_growth_view/baby_growth_view.dart';
import 'package:babyland/app/view/baby_growth/milestones/add_mild_stones.dart';
import 'package:babyland/app/view/baby_growth/milestones/mild_stones_view.dart';
import 'package:babyland/app/view/baby_growth/photo/add_new_photo_view.dart';
import 'package:babyland/app/view/baby_growth/photo/photo_view.dart';
import 'package:babyland/app/view/baby_growth/vaccianations/vaccination_view.dart';
import 'package:babyland/app/view/basic_information/basic_info_view.dart';
import 'package:babyland/app/view/basic_information/processing_details_view.dart';
import 'package:babyland/app/view/basic_information/stages_view.dart';
import 'package:babyland/app/view/create_account/account_created_successfully_view.dart';
import 'package:babyland/app/view/create_account/add_email_view.dart';
import 'package:babyland/app/view/create_account/create_new_account_view.dart';
import 'package:babyland/app/view/create_new_password/all_set_view.dart';
import 'package:babyland/app/view/create_new_password/create_new_password.dart';
import 'package:babyland/app/view/expert_consultation/all_doctor_view.dart';
import 'package:babyland/app/view/expert_consultation/doctor_profile_view.dart';
import 'package:babyland/app/view/expert_consultation/my_bookings/bookings_view.dart';
import 'package:babyland/app/view/expert_consultation/my_bookings/my_bookings_view.dart';
import 'package:babyland/app/view/expert_consultation/select_slot_time_view.dart';
import 'package:babyland/app/view/forgot_password/forgot_password_view.dart';
import 'package:babyland/app/view/lets_get_started/lets_get_started_view.dart';
import 'package:babyland/app/view/onboarding/onboarding_view.dart';
import 'package:babyland/app/view/profile_screen/subscreens/reffund_policy.dart';
import 'package:babyland/app/view/profile_screen/subscreens/shipping_policy.dart';
import 'package:babyland/app/view/profile_screen/subscreens/term_of_services.dart';
import 'package:babyland/app/view/sign_in/sign_in.dart';
import 'package:babyland/app/view/splash/splash_view.dart';
import 'package:babyland/app/view/subscription_unlock_plans/baby_child/baby_child_sub_screen.dart';
import 'package:babyland/app/view/subscription_unlock_plans/post_pregnancy/post_sub_screen.dart';
import 'package:babyland/app/view/subscription_unlock_plans/pre_pregnancy/pre_subscription_screen.dart';
import 'package:babyland/app/view/subscription_unlock_plans/pregnancy/pregnancy_sub_screen.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/bigquery/v2.dart';

import '../navbar/post_pregnancy/post_pregnancy_navbar.dart';
import '../view/Post_pregnancy_flow/post_add_reminderview.dart';
import '../view/Pre_pregnancy_flow/aI_insights.dart';
import '../view/Pre_pregnancy_flow/nav_bar/pre_pregnancy_navbar.dart';
import '../view/forgot_password/forgot_password_otp_verify_view.dart';
import '../view/profile_screen/profile_screen.dart';
import '../view/profile_screen/profile_update_screen.dart';
import '../view/profile_screen/subscreens/privacy_policy.dart';

class AppRoutes{
  static const String splashView ='/splashView';
  static const String onboardingView ='/onboardingView';
  static const String letsGetStartedView ='/letsGetStartedView';
  static const String createNewAccountView ='/createNewAccountView';
  static const String addEmailView ='/addEmailView';
  static const String accountCreatedSuccessfullyView ='/accountCreatedSuccessfullyView';
  static const String basicInfoView ='/basicInfoView';
  static const String stagesView ='/stagesView';
  static const String processingDetailsView ='/processingDetailsView';
  static const String signInView ='/signInView';
  static const String forgotPasswordView ='/forgotPasswordView';
  static const String forgotPasswordOtpVerifyView ='/forgotPasswordOtpVerifyView';
  static const String createNewPasswordView ='/createNewPasswordView';
  static const String allSetView ='/allSetView';
  static const String navbarView ='navbarView';
  static const String mentrualCycle ='mentrualCycle';
  static const String dailyLogs ='dailyLogs';
  static const String babyGrowthView ='babyGrowthView';
  static const String babyGrowthSummaryView ='babyGrowthSummaryView';
  static const String mildStonesView ='mildStonesView';
  static const String addMildStones ='addMildStones';
  static const String photoView ='photoView';
  static const String addNewPhotoView ='addNewPhotoView';
  static const String vaccinationView ='vaccinationView';
  static const String aiAssistantView ='aiAssistantView';
  static const String allDoctorView ='allDoctorView';
  static const String doctorProfileView ='doctorProfileView';
  static const String selectSlotTimeView ='selectSlotTimeView';
  static const String bookingsView ='bookingsView';
  static const String myBookingsView ='myBookingsView';
  static const String recordsView ='recordsView';
  static const String reportView ='reportView';
  static const String cycleCalendarView ='cycleCalendarView';
  static const String aiInsights ='aiInsights';
  static const String pregnancyView ='pregnancyView';
  static const String fetalDevelopmentView ='fetalDevelopmentView';
  static const String postPregnancyView ='postPregnancyView';
  static const String babyDetailView ='babyDetailView';
  static const String pregnancyHomeView ='pregnancyHomeView';
  static const String appointmentView ='appointmentView';
  static const String postAppointmentView ='postAppointmentView';
  static const String addReminderView ='addReminderView';
  static const String saveLogView ='saveLogView';
  static const String combinedBabyDetailScreen ='combinedBabyDetailScreen';
  static const String postPreBabyGrowthView ='postPreBabyGrowthView';
  static const String postPregnancyNavbarView ='postPregnancyNavbarView';
  static const String prePreSubscriptionView ='prePreSubscriptionView';
  static const String babyChildSubscriptionView ='babyChildSubscriptionView';
  static const String postPreSubscriptionView ='postPreSubscriptionView';
  static const String preSubscriptionView ='preSubscriptionView';
  static const String navbarPrePregancyView ='navbarPrePregancyView';
  static const String profileScreen ='profileScreen';
  static const String profileUpdateScreen ='profileUpdateScreen';
  static const String privacyPolicy ='privacyPolicy';
  static const String termOfServicesScreen ='termOfServicesScreen';
  static const String refundPolicyScreen ='refundPolicyScreen';
  static const String shippingPolicyScreen ='shippingPolicyScreen';
  static const String postAddReminderView ='postAddReminderView';

  static Route<dynamic> generateRoute(RouteSettings settings){
    pt(settings.name.toString(),name: "Routes--------------->>>>>>>>");
    switch(settings.name){
      case splashView :
        return MaterialPageRoute(builder: (_) => const SplashView());

      case onboardingView:
        return MaterialPageRoute(builder: (_)=> OnboardingScreen());

      case letsGetStartedView:
        return MaterialPageRoute(builder: (_)=> LetsGetStartedView());

      case createNewAccountView:
        return MaterialPageRoute(builder: (_)=> CreateNewAccountView());

    case addEmailView:
        return MaterialPageRoute(builder: (_)=> AddEmailView());

    case accountCreatedSuccessfullyView:
        return MaterialPageRoute(builder: (_)=> AccountCreatedSuccessfullyView());

    case stagesView:
        return MaterialPageRoute(builder: (_)=> StagesView(),settings: settings);

    case basicInfoView:
        return MaterialPageRoute(builder: (_)=> BasicInfoView());

    case processingDetailsView:
    return MaterialPageRoute(builder: (_)=> ProcessingDetailsView(),settings: settings);

    case signInView:
    return MaterialPageRoute(builder: (_)=> SignInView(),settings: settings);

    case forgotPasswordView:
    return MaterialPageRoute(builder: (_)=> ForgotPasswordView());

    case forgotPasswordOtpVerifyView:
    return MaterialPageRoute(builder: (_)=> ForgotPasswordOtpVerifyView());

    case createNewPasswordView:
    return MaterialPageRoute(builder: (_)=> CreateNewPasswordView());

    case allSetView:
    return MaterialPageRoute(builder: (_)=> AllSetView());

    case navbarView:
    return MaterialPageRoute(builder: (_)=> NavbarView(),settings: settings);

    case mentrualCycle:
    return MaterialPageRoute(builder: (_)=> MentrualCycle());

    case dailyLogs:
    return MaterialPageRoute(builder: (_)=> DailyLogs(),settings: settings);

    case babyGrowthView:
    return MaterialPageRoute(builder: (_)=> BabyGrowthView());

   case babyGrowthSummaryView:
    return MaterialPageRoute(builder: (_)=> BabyGrowthSummaryView());

   case mildStonesView:
    return MaterialPageRoute(builder: (_)=> MildStonesView());

   case addMildStones:
    return MaterialPageRoute(builder: (_)=> AddMildStones());

    case photoView:
      return MaterialPageRoute(builder: (_)=> PhotoView());

    case addNewPhotoView:
      return MaterialPageRoute(builder: (_)=> AddNewPhotoView());

    case vaccinationView:
      return MaterialPageRoute(builder: (_)=> VaccinationView());

    case aiAssistantView:
      return MaterialPageRoute(builder: (_)=> AiAssistantView());

    case allDoctorView:
      return MaterialPageRoute(builder: (_)=> AllDoctorView());

    case doctorProfileView:
      return MaterialPageRoute(builder: (_)=> DoctorProfileView(),settings: settings);

    case selectSlotTimeView:
      return MaterialPageRoute(builder: (_)=> SelectSlotTimeView(),settings: settings);

    case bookingsView:
      return MaterialPageRoute(builder: (_)=> BookingsView(),settings: settings);

    case myBookingsView:
      return MaterialPageRoute(builder: (_)=> MyBookingsView());

    case recordsView:
      return MaterialPageRoute(builder: (_)=> RecordsView());

    case reportView:
      return MaterialPageRoute(builder: (_)=> ReportView());

    case cycleCalendarView:
      return MaterialPageRoute(builder: (_)=> CycleCalendarView());

    case aiInsights:
      return MaterialPageRoute(builder: (_)=> AiInsights());

     case pregnancyView:
      return MaterialPageRoute(builder: (_)=> PregnancyView());

     case fetalDevelopmentView:
      return MaterialPageRoute(builder: (_)=> FetalDevelopmentView());

     case postPregnancyView:
      return MaterialPageRoute(builder: (_)=> PostPregnancyView());

     case babyDetailView:
      return MaterialPageRoute(builder: (_)=> BabyDetailView());

     case pregnancyHomeView:
      return MaterialPageRoute(builder: (_)=> PregnancyHomeView());

     case appointmentView:
      return MaterialPageRoute(builder: (_)=> AppointmentView());

    case postAppointmentView:
          return MaterialPageRoute(builder: (_)=> PostPreAppointmentView());

    case postAddReminderView:
          return MaterialPageRoute(builder: (_)=> PostAddReminderView());

     case addReminderView:
      return MaterialPageRoute(builder: (_)=> AddReminderView());

     case saveLogView:
      return MaterialPageRoute(builder: (_)=> SaveLogView(),settings: settings);

     case combinedBabyDetailScreen:
      return MaterialPageRoute(builder: (_)=> CombinedBabyDetailScreen());

    case postPreBabyGrowthView:
      return MaterialPageRoute(builder: (_)=> PostPreBabyGrowthView());


    case postPregnancyNavbarView:
      return MaterialPageRoute(builder: (_)=> PostPregnancyNavbarView());

    case prePreSubscriptionView:
      return MaterialPageRoute(builder: (_)=> PreSubscriptionScreen());

     case babyChildSubscriptionView:
      return MaterialPageRoute(builder: (_)=> BabyChildSubScreen());

     case postPreSubscriptionView:
      return MaterialPageRoute(builder: (_)=> PostSubScreen());

     case preSubscriptionView:
      return MaterialPageRoute(builder: (_)=> PregnancySubScreen());

    case navbarPrePregancyView:
      return MaterialPageRoute(builder: (_)=> NavbarPrePregancyView());

    case profileUpdateScreen:
          return MaterialPageRoute(builder: (_)=> ProfileUpdateScreen());

   case profileScreen:
        return MaterialPageRoute(builder: (_)=> ProfileScreen(),settings: settings);

   case privacyPolicy:
        return MaterialPageRoute(builder: (_)=> PrivacyPolicyView());

     case termOfServicesScreen:
        return MaterialPageRoute(builder: (_)=> TermOfServicesScreen());

     case refundPolicyScreen:
        return MaterialPageRoute(builder: (_)=> RefundPolicyScreen());

     case shippingPolicyScreen:
        return MaterialPageRoute(builder: (_)=> ShippingPolicyScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }

  }
}