class CommonResponseModel {
  bool? success;
  String? message;
  String? token;
  String? refreshToken;
  dynamic data;

  CommonResponseModel({this.success, this.message, this.token, this.refreshToken, this.data});

  CommonResponseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message']?.toString();
    
    // Check both `token` and `authToken` keys at top level
    token = (json['token'] ?? json['authToken'])?.toString();
    
    refreshToken = json['refreshToken']?.toString();
    data = json['data'] ?? json['user'];

    // Some controllers return refreshToken both at top-level and inside `data`.
    if (refreshToken == null || refreshToken!.isEmpty) {
      final dataMap = data is Map ? Map<String, dynamic>.from(data as Map) : null;
      refreshToken = dataMap?['refreshToken']?.toString();
    }

    // Also check inside `data` for token/authToken if still null
    // Backend may nest: { success: true, data: { authToken: "...", refreshToken: "...", user: {...} } }
    if (token == null || token!.isEmpty) {
      final dataMap = data is Map ? Map<String, dynamic>.from(data as Map) : null;
      token = (dataMap?['authToken'] ?? dataMap?['token'])?.toString();
    }
    if (refreshToken == null || refreshToken!.isEmpty) {
      final dataMap = data is Map ? Map<String, dynamic>.from(data as Map) : null;
      refreshToken = dataMap?['refreshToken']?.toString();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['token'] = token;
    data['refreshToken'] = refreshToken;
    return data;
  }
}
