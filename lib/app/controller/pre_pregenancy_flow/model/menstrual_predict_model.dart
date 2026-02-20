class MenstrualPredictModel {
  bool? success;
  String? message;
  Data? data;

  MenstrualPredictModel({this.success, this.message, this.data});

  MenstrualPredictModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
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
  bool? success;
  List<PredictedCycles>? predictedCycles;
  List<AiInsights>? aiInsights;
  FilteredCalendar? filteredCalendar;

  Data({this.success, this.predictedCycles, this.aiInsights, this.filteredCalendar});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['predictedCycles'] != null) {
      predictedCycles = <PredictedCycles>[];
      json['predictedCycles'].forEach((v) {
        predictedCycles!.add(PredictedCycles.fromJson(v));
      });
    }
    if (json['aiInsights'] != null) {
      aiInsights = <AiInsights>[];
      json['aiInsights'].forEach((v) {
        aiInsights!.add(AiInsights.fromJson(v));
      });
    }
    filteredCalendar = json['filteredCalendar'] != null
        ? FilteredCalendar.fromJson(json['filteredCalendar'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (predictedCycles != null) {
      data['predictedCycles'] =
          predictedCycles!.map((v) => v.toJson()).toList();
    }
    if (aiInsights != null) {
      data['aiInsights'] = aiInsights!.map((v) => v.toJson()).toList();
    }
    if (filteredCalendar != null) {
      data['filteredCalendar'] = filteredCalendar!.toJson();
    }
    return data;
  }
}

class FilteredCalendar {
  List<String>? predictedPeriod;
  List<String>? fertileWindow;
  List<String>? ovulationDays;

  FilteredCalendar({this.predictedPeriod, this.fertileWindow, this.ovulationDays});

  FilteredCalendar.fromJson(Map<String, dynamic> json) {
    predictedPeriod = json['predictedPeriod']?.cast<String>();
    fertileWindow = json['fertileWindow']?.cast<String>();
    ovulationDays = json['ovulationDays']?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['predictedPeriod'] = predictedPeriod;
    data['fertileWindow'] = fertileWindow;
    data['ovulationDays'] = ovulationDays;
    return data;
  }
}

class PredictedCycles {
  String? startDate;
  String? endDate;
  String? ovulationDay;
  List<String>? fertilityWindow;

  PredictedCycles(
      {this.startDate, this.endDate, this.ovulationDay, this.fertilityWindow});

  PredictedCycles.fromJson(Map<String, dynamic> json) {
    startDate = json['startDate'];
    endDate = json['endDate'];
    ovulationDay = json['ovulationDay'];
    fertilityWindow = json['fertilityWindow']?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['ovulationDay'] = ovulationDay;
    data['fertilityWindow'] = fertilityWindow;
    return data;
  }
}

class AiInsights {
  String? type;
  String? message;

  AiInsights({this.type, this.message});

  AiInsights.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['message'] = message;
    return data;
  }
}
