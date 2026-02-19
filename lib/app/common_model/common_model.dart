class CommonResponseModel {
  bool? success;
  String? message;
  String? token;
  dynamic data;

  CommonResponseModel({this.success, this.message, this.data});

  CommonResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    token = json['token']?.toString();
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['token'] = token;
    return data;
  }
}
