class MenstrualDashboardPredictModel {
  bool? success;
  String? message;
  Data? data;

  MenstrualDashboardPredictModel({this.success, this.message, this.data});

  MenstrualDashboardPredictModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? daysSinceCreation;
  String? nextPeriodDate;
  String? percentage;

  Data({this.daysSinceCreation, this.nextPeriodDate});

  Data.fromJson(Map<String, dynamic> json) {
    daysSinceCreation = json['daysSinceCreation']?.toString();
    nextPeriodDate = json['nextPeriodDate']?.toString();
    percentage = json['percentage']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['daysSinceCreation'] = daysSinceCreation;
    data['nextPeriodDate'] = nextPeriodDate;
    data['percentage'] = percentage;
    return data;
  }
}
