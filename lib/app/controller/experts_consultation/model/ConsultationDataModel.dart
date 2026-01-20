class ConsultationDataModel {
  final bool success;
  final ConsultationData? data;

  ConsultationDataModel({
    required this.success,
    this.data,
  });

  factory ConsultationDataModel.fromJson(Map<String, dynamic> json) {
    return ConsultationDataModel(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? ConsultationData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ConsultationData {
  final String id;
  final String patientId;
  final String doctorId;
  final String file;
  final DateTime uploadedAt;

  ConsultationData({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.file,
    required this.uploadedAt,
  });

  factory ConsultationData.fromJson(Map<String, dynamic> json) {
    return ConsultationData(
      id: json['_id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      file: json['file'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'file': file,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
