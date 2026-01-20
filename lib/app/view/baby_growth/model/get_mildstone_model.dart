class MilestonesModel {
  bool? success;
  String? message;
  List<MilestoneItem>? data;

  MilestonesModel({this.success, this.message, this.data});

  MilestonesModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    if (json['milestones'] != null) {
      data = (json['milestones'] as List)
          .map((i) => MilestoneItem.fromJson(i))
          .toList();
    }
  }
}

class MilestoneItem {
  String? date;
  String? title;
  String? photo;
  String? note;

  MilestoneItem({this.date, this.title, this.photo, this.note});

  MilestoneItem.fromJson(Map<String, dynamic> json) {
    date = json['date'];
    title = json['title'];
    photo = json['photo'];
    note = json['note'];
  }
}
