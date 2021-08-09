
//bottom widget of the room screen
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/room/room_screen.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/utils.dart';
import 'package:roomies/widgets/raise_my_hand.dart';
import 'package:roomies/widgets/widgets.dart';

Widget buildBottomNav(Room room, BuildContext context, UserModel myProfile, List<UserModel> raisedhandsusers, [StateSetter state]) {
  if(room ==null) return Container();
  int index = room.users.indexWhere((element) => element.uid == myProfile.uid);
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      GestureDetector(
        onTap: () {
          pingPeopleRoom(context, room);
        },
        child: const Icon(CupertinoIcons.add_circled_solid, size: 40.0),
      ),
      SizedBox(
        width: 10,
      ),
      room != null && myProfile.uid == room.ownerid
          ? GestureDetector(
        onTap: () {
          showModalBottomSheet(
              context: context,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              builder: (context) {
                return StatefulBuilder(builder:
                    (BuildContext context, StateSetter mystate) {
                  return raisedHandsView(mystate, room, context, raisedhandsusers);
                });
              });
        },
        child: Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(CupertinoIcons.news, size: 30.0),
              room.raisedhands.length > 0
                  ? Positioned(
                right: 0.6,
                top: 0.8,
                child: Container(
                  height: 18.0,
                  width: 18.0,
                  child: Center(
                    child: Text(
                      "${room.raisedhands.length}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
              )
                  : Text(""),
            ],
          ),
        ),
      )
          : Text(""),
      SizedBox(
        width: 10,
      ),
      room.users
          .indexWhere((element) => element.uid == myProfile.uid) != -1 &&
          room.users[room.users
              .indexWhere((element) => element.uid == myProfile.uid)]
              .usertype ==
              "others" && (room.handsraisedby == 1 || Database().followedBySpeakersCheck(room) == true)
          ? GestureDetector(
        onTap: () {
          // if(room.raisedhands == 1 || myProfile){
          raiseMyHandView(context, room, myProfile);
          // }
        },
        child: Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: const Icon(CupertinoIcons.hand_raised, size: 30.0),
        ),
      )
          : Text(""),
      index != -2 && index != -1 && room.users[index].usertype != "others"
          ? GestureDetector(
        onTap: () {
          //initiate raising a hand
          callMuteUnmute(room,index, state);
        },
        child: Container(
          padding: const EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: index != -1 && room.users[index].callmute == true
              ? const Icon(CupertinoIcons.mic_off, size: 30.0)
              : const Icon(CupertinoIcons.mic_fill, size: 30.0),
        ),
      )
          : Text(""),
    ],
  );
}

//mute user mic
void callMuteUnmute(Room room, int index, StateSetter state) {

  room.users[index].callmute = !room.users[index].callmute;
  engine.muteLocalAudioStream(room.users[index].callmute);

  roomsRef.doc(room.roomid).update({
    "users": room.users
        .map((i) =>
        i.toMap(
            usertype: i.usertype, callmute: i.callmute, callerid: i.callerid))
        .toList(),
  });
  state(() {});
}