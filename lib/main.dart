import 'package:babyland/app/agora/video_call_controller.dart';
import 'package:babyland/app/common_profile_header/get_user_controller.dart';
import 'package:babyland/app/controller/experts_consultation/booking/booking_controller.dart';
import 'package:babyland/app/controller/experts_consultation/experts_consultation_controller.dart';
import 'package:babyland/app/controller/experts_consultation/records/records_controller.dart';
import 'package:babyland/app/controller/photo/photo_controller.dart';
import 'package:babyland/app/controller/pregnancy_flow/pregnancy_controller.dart';
import 'package:babyland/app/navbar/post_pregnancy/post_pregnancy_navbar_controller.dart';
import 'package:babyland/app/routes/app_routes.dart';
import 'package:babyland/app/services/user_preference/user_preference.dart';
import 'package:babyland/app/theme/app_colors.dart';
import 'package:babyland/app/view/subscription_unlock_plans/controller/subscription_controller.dart';
import 'package:babyland/app/widgets/print.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app/controller/ai_assistant/ai_assistant_controller.dart';
import 'app/controller/baby_growth/baby_growth_controller.dart';
import 'app/controller/forgot_password/forgot_pass_controller.dart';
import 'app/controller/policies/policies_controller.dart';
import 'app/controller/post_pregenancy/post_pregenancy_controller.dart';
import 'app/controller/pre_pregenancy_flow/cycle_celender_controller/cycle_celender_controller.dart';
import 'app/data/network/network_api_services.dart';
import 'app/data/repository/repository.dart';
import 'app/navbar/pregnancy/navbar_controller.dart';
import 'app/view/Post_pregnancy_flow/controller/post_appoitment_controller.dart';
import 'app/view/Pre_pregnancy_flow/nav_bar/pre_pregnancy_nav_controller.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final networkApi = NetworkApiServices();
final repository = Repository(apiService: networkApi);
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreference.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try{
    await dotenv.load(fileName: "assets/.env");
  }catch(e){
    pt("failed to load env");
  }

  try{
    String token =await FirebaseMessaging.instance.getToken() ?? "";
    pt(name: "Firebase token",token);
  }catch(e){
    pt(name: "Failed to get firebase token", e.toString());
  }

  runApp(const Babyland());
  // runApp(DevicePreview(enabled: !kReleaseMode,builder: (context) => const Babyland(),));

}

class Babyland extends StatelessWidget {
  const Babyland({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: AppColors.transparent,
        statusBarBrightness: Brightness.light));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<Repository>.value(value: repository),
        ChangeNotifierProvider(create: (context) => NavBarProvider()),
        ChangeNotifierProvider(create: (context) => ExpertConsultationProvider()),
        ChangeNotifierProvider(create: (context) => BookingController()),
        ChangeNotifierProvider(create: (context) => PostPregnancyNavBarProvider()),
        ChangeNotifierProvider(create: (context) => PhotoProvider()),
        ChangeNotifierProvider(create: (context) => PregnancyController()),
        ChangeNotifierProvider(create: (context) => PostpregnancyProvider()),
        ChangeNotifierProvider(create: (context) => CycleCalenderProvider()),
        ChangeNotifierProvider(create: (context) => ForgotPassController()),
        ChangeNotifierProvider(create: (context) => GetUserProvider()),
        ChangeNotifierProvider(create: (context) => BabyGrowthProvider()),
        ChangeNotifierProvider(create: (context) => BookingController()),
        ChangeNotifierProvider(create: (context) => PrePregancyNavBarProvider()),
        ChangeNotifierProvider(create: (context) => AiAssistantProvider()),
        ChangeNotifierProvider(create: (context) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (context) => PoliciesProvider()),
        ChangeNotifierProvider(create: (context) => RecordsProvider()),
        ChangeNotifierProvider(create: (context) => VideoCallProvider()),
        ChangeNotifierProvider(create: (context) => PostAppointmentController()),
      ],
      child: SafeArea(
        top: false,
        child: PopScope(
          canPop: false,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Babyland',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            onGenerateRoute: AppRoutes.generateRoute,
            initialRoute: AppRoutes.splashView,
            // home: BasicInfoView(),
          ),
        ),
      ),
    );
  }
}