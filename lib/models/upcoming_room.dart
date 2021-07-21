import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/models/models.dart';
/*
  type : Model
 */
class UpcomingRoom{

  final String title;
  final String roomid;
  final String description;
  final String eventdate;
  final String timedisplay;
  final List<UserModel> users;
  final int eventtime;
  final bool started;
  final String userid;

  UpcomingRoom({
    this.title,
    this.description,
    this.users,
    this.roomid,
    this.eventdate,
    this.eventtime,
    this.timedisplay,
    this.started,
    this.userid,
  });

  factory UpcomingRoom.fromJson(DocumentSnapshot json) {
    return UpcomingRoom(
      eventdate: json['eventdate'] ?? "",
      title: json['title'] ?? "",
      roomid: json.id,
      users: json['users'] !=null ? json['users'].map<UserModel>((user) {
        return UserModel.fromJson(user);
      }).toList() : [],
      description: json['description'] ?? "",
      eventtime: json['eventtime'] ?? 0,
      timedisplay: json['timedisplay'] ?? 0,
      started: json['started'] ?? false,
      userid: json['userid'] ?? "",
    );
  }
}