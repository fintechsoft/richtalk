import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/models/room.dart';
import 'package:richtalk/pages/home/profile_page.dart';
import 'package:richtalk/widgets/follower_item.dart';
import 'package:richtalk/pages/room/room_screen.dart';
import 'package:richtalk/services/database.dart';
import 'package:richtalk/util/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../widgets/widgets.dart';

class FollowerPage extends StatefulWidget {
  @override
  _FollowerPageState createState() => _FollowerPageState();
}

class _FollowerPageState extends State<FollowerPage> {
  UserModel myProfile = Get.find<UserController>().user;
  bool loading = false;
  final globalScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: globalScaffoldKey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
        ),
        child: loading == true
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  buildAvailableChatTitle(),
                  SizedBox(
                    height: 15,
                  ),
                  buildAvailableChatList(context),
                ],
              ),
      ),
    );
  }

  Widget buildAvailableChatTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'AVAILABLE TO CHAT',
          style: TextStyle(
            color: Style.DarkBrown,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Style.DarkBrown,
          ),
        ),
      ],
    );
  }

  Widget buildAvailableChatList(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
        stream: Database.getmyFollowers(),
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasError) {
            return Text("Technical Error");
          }
          if (snapshot.connectionState == ConnectionState.waiting)
            Center(child: CircularProgressIndicator());
          if (snapshot.data == null) {
            return noDataWidget("We list users whom you follow each other and are online that you can chat with here", fontsize: 16);
          }
          List<UserModel> users = snapshot.data;
          return ListView.separated(
            shrinkWrap: true,
            separatorBuilder: (lc, i) {
              return SizedBox(
                height: 15,
              );
            },
            physics: ScrollPhysics(),
            itemBuilder: (lc, index) {
              return FollowerItem(
                user: users[index],
                onProfileTap: () {
                  Get.to(() => ProfilePage(
                        profile: users[index],
                        fromRoom: false,
                      ));
                },
                onRoomButtonTap: () async {
                  setState(() {
                    loading = true;
                  });

                  // creating a room
                  var ref = await Database().createRoom(
                      userData: Get.put(UserController()).user,
                      topic: "",
                      type: "closed", context: context, users: [users[index]]);

                  ref.get().then((value) async {

                    Room room = Room.fromJson(value);
                    await Permission.microphone.request();
                    showModalBottomSheet(
                      isScrollControlled: true,
                      context: globalScaffoldKey.currentContext,
                      builder: (rc) {
                        return RoomScreen(
                          roomid: ref.id,
                          room: room,
                          role: ClientRole.Broadcaster,
                        );
                      },
                    );



                    //send notification to users i follow
                    Database().sendNotificationToUsersiFollow("${room.title} is happening right now","By ${Get.find<UserController>().user.getName()}");


                  });

                  // if (mounted)
                  setState(() {
                    loading = false;
                  });


                },
              );
            },
            itemCount: users.length,
          );
        });
  }
}
