import 'package:cloud_firestore/cloud_firestore.dart';
/*
  type : Model
 */
class ActivityItem{
  String imageurl;
  String id;
  String name;
  String actionkey;
  bool actioned;
  String type;
  String message;
  Timestamp time;

  ActivityItem({this.imageurl, this.name, this.message, this.time, this.type,this.actionkey,this.actioned,this.id});
  factory ActivityItem.fromJson(json, String id) {
    return ActivityItem(
      imageurl: json['imageurl'],
      id: id,
      actioned: json['actioned'] ??  false,
      name: json['name'],
      type: json['type'],
      actionkey: json['actionkey'],
      message: json['message'],
      time: json['time'],
    );
  }
}