import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/pages/room/room_screen.dart';
import 'package:richtalk/util/utils.dart';
import 'package:richtalk/widgets/widgets.dart';

/*
  type : Class
  packages used: none
  function: holds all general methods used in the whole app
 */

class Functions {
  //creates a timestamp string with how long ago a task was done
  static String timeAgoSinceDate(String dateString,
      {bool numericDates = true}) {
    DateTime notificationDate =
        DateFormat("dd-MM-yyyy h:mma").parse(dateString);
    final date2 = DateTime.now();
    final difference = date2.difference(notificationDate);

    if (difference.inDays > 8) {
      return dateString;
    } else if ((difference.inDays / 7).floor() >= 1) {
      return (numericDates) ? '1w ago' : 'Last week';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1d ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours}h ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1h ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes}mins ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1mins ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }
  //creates a timestamp string with how long ago a task was done
  static String timeFutureSinceDate(Timestamp dateString) {

    DateTime notificationDate =
        DateFormat("dd-MM-yyyy h:mma").parse(DateFormat("dd-MM-yyyy h:mma").format(dateString.toDate()));
    final date2 = DateTime.now();
    final difference = date2.difference(notificationDate);

    if (difference.inDays < 1) {
      return "Today ";
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inHours > 1) {
      return DateFormat('E, d MMM').format(dateString.toDate());
    }
    return "";
  }

  //methos invoked when user is leaving the room
  static Future<void> leaveChannel(
      {room,
      UserModel currentUser,
      BuildContext context,
      StreamSubscription<DocumentSnapshot> roomlistener, bool quit = false}) async {
    if (currentUser.uid == room.ownerid) {
      if (quit == true) {
        quitRoomandPop(roomlistener: roomlistener, context: context);
      } else {
        leaveEngine();
      }
      // Navigator.pop(context);
      roomsRef.doc(room.roomid).delete();
      usersRef.doc(currentUser.uid).update({"activeroom": ""});
    } else {
      //regenerate the users who have raised their hands
      int index2 = room.raisedhands
          .indexWhere((element) => element.uid == currentUser.uid);
      if (index2 != -1) {
        room.raisedhands.removeAt(index2);
        roomsRef.doc(room.roomid).update({
          "raisedhands": room.raisedhands
              .map((i) => i.toMap(
                  usertype: i.usertype,
                  callmute: i.callmute,
                  callerid: i.callerid))
              .toList(),
        });
      }

      //removing user from users list array when he leaves the room
      int index3 = room.users
          .indexWhere((element) => element.uid == currentUser.uid);
      if(index3 !=-1){
        room.users.removeAt(
            room.users.indexWhere((element) => element.uid == currentUser.uid));
        roomsRef.doc(room.roomid).update({
          "users": room.users
              .map((i) => i.toMap(
              usertype: i.usertype,
              callmute: i.callmute,
              callerid: i.callerid))
              .toList(),
        });
      }

      Get.find<CurrentRoomController>().room = null;

      await usersRef.doc(currentUser.uid).update({"activeroom": ""});
      if (quit == true) {
        quitRoomandPop(roomlistener: roomlistener, context: context);
      } else {
        leaveEngine();
      }
    }
  }

  //exit room and navigate back to homepage
  static Future<void> quitRoomandPop(
      {StreamSubscription<DocumentSnapshot> roomlistener, context}) async {
    leaveEngine();
    roomlistener.cancel();
    Navigator.pop(context);
  }

  static leaveEngine() async {
    if(engine !=null){
      await engine.leaveChannel();
      await engine.destroy();
    }
    Get.find<CurrentRoomController>().room = null;
  }
  static var alert;

  static void deleteRoom(
      {Room room, UserModel currentuser, BuildContext context, StreamSubscription<DocumentSnapshot> roomlistener}) {
    if(alert ==null){
      alert = new CupertinoAlertDialog(
        content: new Text('Room does not exists any longer'),
        actions: <Widget>[
          new CupertinoDialogAction(
              child: const Text('End Room'),
              isDestructiveAction: true,

              onPressed: () async {
                roomlistener.cancel();
                Navigator.pop(context);
                Navigator.pop(context);
                roomsRef.doc(room.roomid).delete();
                usersRef.doc(currentuser.uid).update({"activeroom": ""});
                leaveEngine();
                alert = null;
              }),
        ],
      );

      //show alert
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return alert;
          });

    }
  }

  static Future<void> raisehand(Room room) async {
    topTrayPopup(
        " you  raised your hand! we'll let the speakers know you want to talk..");

    if (room.raisedhands.any(
            (element) =>
        element.uid == Get.find<UserController>().user.uid)) {
      return;
    }
    await roomsRef.doc(room.roomid).set({
      "raisedhands": FieldValue.arrayUnion(
          [room.users[room.users.indexWhere((element) => element.uid == Get.find<UserController>().user.uid)].toMap()]),
    }, SetOptions(merge: true));

    //SEND NOTIFICATION TO THE SPEAKER
    List<String> users = [];
    room.users.forEach((element) {
      if(element.usertype == "host"){
        users.add(element.uid);
      }

    });
    // PushNotificationsManager().callOnFcmApiSendPushNotifications(users, "", "${Get.find<UserController>().user.username} want to speak");
  }
}
