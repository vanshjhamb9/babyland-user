class VaccinationModel {
  bool? success;
  String? message;
  List<Vaccinations>? vaccinations;

  VaccinationModel({this.success, this.vaccinations});

  VaccinationModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    if (json['vaccinations'] != null) {
      vaccinations = <Vaccinations>[];
      json['vaccinations'].forEach((v) {
        vaccinations!.add(Vaccinations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (vaccinations != null) {
      data['vaccinations'] = vaccinations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Vaccinations {
  String? status;
  String? vaccine;
  String? dueDate;
  bool? completed;
  String? sId;

  Vaccinations(
      {this.status, this.vaccine, this.dueDate, this.completed, this.sId});

  Vaccinations.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    vaccine = json['vaccine'];
    dueDate = json['dueDate'];
    completed = json['completed'];
    sId = json['_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['vaccine'] = vaccine;
    data['dueDate'] = dueDate;
    data['completed'] = completed;
    data['_id'] = sId;
    return data;
  }
}
