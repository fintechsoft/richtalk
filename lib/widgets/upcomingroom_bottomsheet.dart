import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/room/room_screen.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/services/dynamic_link_service.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/widgets.dart';
import 'package:share/share.dart';

Future<Widget> upcomingroomBottomSheet(BuildContext context, UpcomingRoom room,
    bool loading, bool keyboardup) async {
  return await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter mystate) {
        return Container(
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 30),
          child: loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  room.timedisplay,
                                  style: TextStyle(fontSize: 18),
                                ),
                                room.roomid != null &&
                                        room.userid ==
                                            Get.find<UserController>().user.uid
                                    ? GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          createUpcomingRoomSheet(
                                              context, false, room);
                                        },
                                        child: Text(
                                          "Edit",
                                          style: TextStyle(
                                              color: Colors.blue, fontSize: 18),
                                        ),
                                      )
                                    : GestureDetector(
                                        child: Icon(CupertinoIcons.bell),
                                        onTap: () async {
                                          await Database()
                                              .addUsertoUpcomingRoom(room);
                                        },
                                      )
                              ],
                            ),
                            Text(
                              room.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .copyWith(fontSize: 23.0),
                            ),

                            room.clubname.isNotEmpty ? Row(
                              children: [
                                Text(
                                  "From "+room.clubname,
                                  style: TextStyle(
                                    color: Style.AccentGrey,
                                    fontSize: 12,
                                      fontFamily: "InterBold"
                                  ),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.home,
                                  color: Style.AccentGreen,
                                  size: 18,
                                )
                              ],
                            ) : Container(),
                            const SizedBox(height: 12.0),
                            Text(
                              room.description,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 12.0),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              mystate(() {
                                loading = true;
                              });
                              final RenderBox box = context.findRenderObject();
                              DynamicLinkService()
                                  .createGroupJoinLink(
                                      room.roomid, "upcomingroom")
                                  .then((value) async {
                                await Share.share(value,
                                    subject: "Join " + room.title,
                                    sharePositionOrigin:
                                        box.localToGlobal(Offset.zero) &
                                            box.size);
                                mystate(() {
                                  loading = false;
                                });
                              });
                            },
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.share,
                                  size: 35,
                                  color: Colors.green,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text("Share")
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              mystate(() {
                                loading = true;
                              });
                              DynamicLinkService()
                                  .createGroupJoinLink(
                                      room.roomid, "upcomingroom")
                                  .then((value) async {
                                Clipboard.setData(ClipboardData(text: value));
                                mystate(() {
                                  loading = false;
                                });

                                Get.snackbar(
                                    "", "Share Link Copied To Clipboard",
                                    snackPosition: SnackPosition.BOTTOM,
                                    borderRadius: 0,
                                    margin: EdgeInsets.all(0),
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                    messageText: Text.rich(TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              "Share Link Copied To Clipboard",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )));
                              });
                            },
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.doc_on_clipboard,
                                  size: 35,
                                  color: Colors.green,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text("Copy Link")
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 20.0),
                      Get.put(UserController()).user.uid != room.userid
                          ? Container()
                          : Container(
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              child: CustomButton(
                                  color: Style.AccentGreen,
                                  text: "Start the room",
                                  minimumWidth: double.infinity * 0.8,
                                  onPressed: () async {
                                    mystate(() {
                                      loading = true;
                                    });

                                    // creating a room

                                    var ref = await Database().createRoom(
                                        userData:
                                            Get.put(UserController()).user,
                                        topic: room.title,
                                        clubid: room.clubid,
                                        clubname: room.clubname,
                                        type: "open",
                                        users: room.users,
                                        context: context);

                                    ref.get().then((value) async {
                                      if (value != null) {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      }
                                      Room room = Room.fromJson(value);
                                      await Permission.microphone.request();
                                      showModalBottomSheet(
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (rc) {
                                          return RoomScreen(
                                            roomid: ref.id,
                                            room: room,
                                            role: ClientRole.Broadcaster,
                                          );
                                        },
                                      );

                                      //send notification to users i follow
                                      Database().sendNotificationToUsersiFollow(
                                          "${room.title} is happening right now",
                                          "By ${Get.find<UserController>().user.getName()}");
                                    });

                                    mystate(() {
                                      loading = false;
                                    });
                                  }),
                            ),
                    ],
                  ),
                ),
        );
      });
    },
  );
}
