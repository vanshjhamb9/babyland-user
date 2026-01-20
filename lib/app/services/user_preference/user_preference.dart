import 'package:hive_flutter/adapters.dart';

class UserPreference{
  UserPreference._();

  static late Box _box;

  static Future<void> init()async{
    await Hive.initFlutter();
    _box = await Hive.openBox("userBox");
  }

 static Future<void> saveIsFirstTime (bool isFirstTime) async => _box.put("isFirstTime", isFirstTime);
 static bool? getIsFirstTime()=> _box.get("isFirstTime");

}