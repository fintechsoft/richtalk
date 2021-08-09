
//add user to speaker
//remove user from being speaker
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/room/room_screen.dart';
import 'package:roomies/util/utils.dart';

void activateDeactivateUser(UserModel user, Room room, StateSetter setState, List<UserModel> raisedhandsusers) {
  if (room.raisedhands.indexWhere((element) => element.uid == user.uid) ==
      -1) {
    //user ha already removed his hand
    setState(() {});
  } else {
    raisedhandsusers.removeAt(
        room.raisedhands.indexWhere((element) => element.uid == user.uid));
    print(raisedhandsusers.length.toString());
    engine.setClientRole(ClientRole.Broadcaster);

    roomsRef.doc(room.roomid).update({
      "users": room.users
          .map((i) => i.toMap(
          usertype: i.uid == user.uid ? "speaker" : i.usertype,
          callmute: i.uid == user.uid ? true : i.callmute,
          callerid: i.callerid))
          .toList(),
      "raisedhands": raisedhandsusers
          .map((i) => i.toMap(
          usertype: i.uid == user.uid ? "speaker" : i.usertype,
          callmute: i.uid == user.uid ? true : i.callmute,
          callerid: i.callerid))
          .toList(),
    });
    if(setState !=null)setState(() {});
  }

}