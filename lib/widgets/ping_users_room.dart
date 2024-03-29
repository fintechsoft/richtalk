
//search people to ping to join the room
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:richtalk/Notifications/push_nofitications.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/pages/room/followers_match_grid_sheet.dart';


//user click listener on the ping user bottom sheet
pingCallback(UserModel user, Room room, StateSetter state){
  // Get.back();
  String title = Get.find<UserController>().user.getName() +
      " Invited you to join " +
      room.title;
  PushNotificationsManager().callOnFcmApiSendPushNotifications(
      [user.firebasetoken], "RichTalk Room Invite", title);

}
void pingPeopleRoom(context, Room room) {
  showModalBottomSheet(
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      context: context,
      builder: (context) {
        //3
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter csetState) {
              return DraggableScrollableSheet(
                  expand: false,
                  builder:
                      (BuildContext context, ScrollController scrollController) {
                    return Container(padding: const EdgeInsets.only(
                        top: 15, left: 10, bottom: 10),
                      child: FollowerMatchGridPage(callback: pingCallback,title: "Invite people into the room",fromroom: true,room: room, customState: csetState,),
                    );
                  });
            });
      });
}