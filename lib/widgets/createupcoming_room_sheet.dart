
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/pages/room/add_co_host.dart';
import 'package:richtalk/pages/room/new_upcoming_room.dart';
import 'package:richtalk/pages/room/upcoming_roomsreen.dart';
import 'package:richtalk/util/utils.dart';


List<UserModel> hosts = [Get.find<UserController>().user];
userClickCallBack(UserModel user) {
  if (!hosts.contains(user)) hosts.add(user);
}
void addCoHost(BuildContext context, StateSetter mystate) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        )),
    builder: (context) {
      return AddCoHostScreen(
          clickCallback: userClickCallBack, mystate: mystate);
    },
  ).whenComplete(() {
    print('Hey there, I\'m calling after hide bottomSheet');
  });
}

Future<Widget> createUpcomingRoomSheet(BuildContext context,bool keyboardup,
    [UpcomingRoom roomm]) async {
  if (roomm != null) {

    eventcontroller.text = roomm.title;
    descriptioncontroller.text = roomm.description;
    datedisplay = roomm.eventdate;
    timedisplay = roomm
        .timedisplay; // DateTime.fromMillisecondsSinceEpoch(roomm.eventtime).hour.toString()+":"+DateTime.fromMillisecondsSinceEpoch(roomm.eventtime).minute.toString();
    publish = true;
    timeseconds = roomm.eventtime;
  }

  return await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Style.LightGrey,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
    ),
    builder: (context) {
      return NewUpcomingRoom();
    },
  );
}