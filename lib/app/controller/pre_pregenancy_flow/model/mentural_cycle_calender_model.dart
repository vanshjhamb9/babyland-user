class MentauralCalenderModel {
  bool? success;
  String? message;
  Data? data;

  MentauralCalenderModel({this.success, this.message, this.data});

  MentauralCalenderModel.fromJson(Map<String, dynamic> json) {
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
  String? message;
  String? year;
  String? month;
  FilteredCalendar? filteredCalendar;
  CycleStats? cycleStats;
  NextPeriod? nextPeriod;
  String? nextOvulation;
  List<String>? nextFertileWindow;

  Data(
      {this.success,
        this.message,
        this.year,
        this.month,
        this.filteredCalendar,
        this.cycleStats,
        this.nextPeriod,
        this.nextOvulation,
        this.nextFertileWindow});

  Data.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    year = json['year']?.toString();
    month = json['month']?.toString();
    filteredCalendar = json['filteredCalendar'] != null
        ? FilteredCalendar.fromJson(json['filteredCalendar'])
        : null;
    cycleStats = json['cycleStats'] != null
        ? CycleStats.fromJson(json['cycleStats'])
        : null;
    nextPeriod = json['nextPeriod'] != null
        ? NextPeriod.fromJson(json['nextPeriod'])
        : null;
    nextOvulation = json['nextOvulation']?.toString();
    nextFertileWindow = json['nextFertileWindow'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['year'] = year;
    data['month'] = month;
    if (filteredCalendar != null) {
      data['filteredCalendar'] = filteredCalendar!.toJson();
    }
    if (cycleStats != null) {
      data['cycleStats'] = cycleStats!.toJson();
    }
    if (nextPeriod != null) {
      data['nextPeriod'] = nextPeriod!.toJson();
    }
    data['nextOvulation'] = nextOvulation;
    data['nextFertileWindow'] = nextFertileWindow;
    return data;
  }
}

class NextPeriod {
  String? start;
  String? end;

  NextPeriod({this.start, this.end});

  NextPeriod.fromJson(Map<String, dynamic> json) {
    start = json['start']?.toString();
    end = json['end']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['start'] = start;
    data['end'] = end;
    return data;
  }
}

class FilteredCalendar {
  List<String>? predictedPeriod;
  List<String>? fertileWindow;
  List<String>? ovulationDays;

  FilteredCalendar(
      {this.predictedPeriod, this.fertileWindow, this.ovulationDays});

  FilteredCalendar.fromJson(Map<String, dynamic> json) {
    predictedPeriod = json['predictedPeriod'].cast<String>();
    fertileWindow = json['fertileWindow'].cast<String>();
    ovulationDays = json['ovulationDays'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['predictedPeriod'] = predictedPeriod;
    data['fertileWindow'] = fertileWindow;
    data['ovulationDays'] = ovulationDays;
    return data;
  }
}

class CycleStats {
  String? cycleLength;
  String? periodLength;
  String? cycleType;

  CycleStats({this.cycleLength, this.periodLength, this.cycleType});

  CycleStats.fromJson(Map<String, dynamic> json) {
    cycleLength = json['cycleLength']?.toString();
    periodLength = json['periodLength']?.toString();
    cycleType = json['cycleType']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cycleLength'] = cycleLength;
    data['periodLength'] = periodLength;
    data['cycleType'] = cycleType;
    return data;
  }
}
