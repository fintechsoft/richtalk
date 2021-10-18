import 'package:richtalk/models/user_model.dart';
/*
  type : Model
 */
class Room {
  final String title;
  final List<UserModel> users;
  final List<UserModel> raisedhands;
  final int speakerCount;
  final int handsraisedby;
  final int createdtime;
  final String roomtype;
  final String roomid;
  final String token;
  final String ownerid;
  final String clubname;
  final String clubid;

  Room({
    this.clubid,
    this.clubname,
    this.title,
    this.roomtype,
    this.token,
    this.handsraisedby,
    this.roomid,
    this.createdtime,
    this.speakerCount,
    this.ownerid,
    this.users,
    this.raisedhands,
  });

  getHandsRaisedByType(){
    if(handsraisedby == 1)return "Open to EveryOne";
    if(handsraisedby == 2)return "Followed by the Speakers";
    if(handsraisedby == 3)return "Off";
  }



  factory Room.fromJson(doc) {
    var json  = doc.data();
    return Room(
      handsraisedby: json['handsraisedby'] ?? 0,
      title: json['title'],
      clubname: json['clubname'] == null  ? "" : json['clubname'],
      clubid: json['clubid'] == null ? "" : json['clubid'],
      ownerid: json['ownerid'],
      roomtype: json['roomtype'],
      createdtime: json['created_time'],
      token: json['token'],
      roomid: doc.id,
      users: json['users'].map<UserModel>((user) {
        return UserModel.fromJson(user);
      }).toList(),
      raisedhands: json['raisedhands'].map<UserModel>((user) {
        return UserModel.fromJson(user);
      }).toList(),
      speakerCount: json['speakerCount'],
    );
  }
}
