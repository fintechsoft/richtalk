import 'package:cloud_firestore/cloud_firestore.dart';
/*
  type : Model
 */
class ActivityItem{
  String imageurl;
  String name;
  String message;
  Timestamp time;

  ActivityItem({this.imageurl, this.name, this.message, this.time});
  factory ActivityItem.fromJson(json) {
    return ActivityItem(
      imageurl: json['imageurl'],
      name: json['name'],
      message: json['message'],
      time: json['time'],
    );
  }
}