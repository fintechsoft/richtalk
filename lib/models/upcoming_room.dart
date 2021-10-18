import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:richtalk/models/models.dart';
/*
  type : Model
 */
class UpcomingRoom{

  final String title;
  final String clubname;
  final String clubid;
  final String roomid;
  final String description;
  final String eventdate;
  final String timedisplay;
  final Timestamp publisheddate;
  final List<UserModel> users;
  final int eventtime;
  final bool started;
  final String userid;

  UpcomingRoom({
    this.title,
    this.clubid,
    this.clubname,
    this.description,
    this.publisheddate,
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
      clubname: json.data()['clubname'] == null  ? "" : json['clubname'],
      clubid: json.data()['clubid'] == null ? "" : json['clubid'],
      roomid: json.id,
      users: json['users'] !=null ? json['users'].map<UserModel>((user) {
        return UserModel.fromJson(user);
      }).toList() : [],
      description: json['description'] ?? "",
      publisheddate: json['published_date'] ?? null,
      eventtime: json['eventtime'] ?? 0,
      timedisplay: json['timedisplay'] ?? 0,
      started: json['started'] ?? false,
      userid: json['userid'] ?? "",
    );
  }
}