import 'package:babyland/app/controller/pre_pregenancy_flow/model/menstruals_cycle_model.dart';
import 'package:flutter/foundation.dart';
import '../network/end_points.dart';
import '../network/network_api_services.dart';

class MenstrualRepository extends ChangeNotifier {
  final NetworkApiServices apiService;
  MenstrualRepository._internal(this.apiService);
  static final MenstrualRepository _instance = MenstrualRepository._internal(NetworkApiServices());
  factory MenstrualRepository({NetworkApiServices? apiService}) {
    return _instance;
  }

  Future<Menstruals_Cycle_model> getMenstrual() async {
    final response = await apiService.get(
      EndPoints.menstruals,
    );
    return Menstruals_Cycle_model.fromJson(response);
  }

  Future<Menstruals_Cycle_model> getDailyLog() async {
    final response = await apiService.get(
      EndPoints.menstruals,
    );
    return Menstruals_Cycle_model.fromJson(response);
  }

  Future<Menstruals_Cycle_model> allInsights() async {
    final response = await apiService.get(
      EndPoints.menstruals,
    );
    return Menstruals_Cycle_model.fromJson(response);
  }
}