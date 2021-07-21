import 'package:roomies/models/user_model.dart';
/*
  type : Model
 */
class Room {
  final String title;
  final List<UserModel> users;
  final List<UserModel> raisedhands;
  final int speakerCount;
  final int handsraisedby;
  final String roomtype;
  final String roomid;
  final String token;
  final String ownerid;

  Room({
    this.title,
    this.roomtype,
    this.token,
    this.handsraisedby,
    this.roomid,
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
      handsraisedby: json['handsraisedby'],
      title: json['title'],
      ownerid: json['ownerid'],
      roomtype: json['roomtype'],
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
