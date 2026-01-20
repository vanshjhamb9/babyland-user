class CommonResponseModel {
  bool? success;
  String? message;
  String? token;

  CommonResponseModel({this.success, this.message});

  CommonResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    token = json['token']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['token'] = token;
    return data;
  }
}
