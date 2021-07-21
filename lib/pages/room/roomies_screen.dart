import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/pages/room/room_screen.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/services/dynamic_link_service.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roomies/widgets/noitem_widget.dart';
import 'package:roomies/widgets/room_card.dart';
import 'package:roomies/widgets/schedule_card.dart';
import 'package:roomies/models/room.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/lobby_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:roomies/models/models.dart';

class RommiesScreen extends StatefulWidget {
  @override
  _RommiesScreenState createState() => _RommiesScreenState();
}

class _RommiesScreenState extends State<RommiesScreen>
    with WidgetsBindingObserver {
  //refresh initialize
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  //current user object
  UserModel myProfile = Get.find<UserController>().user;

  //initialize varaibles
  String roomtype = "open";
  bool loading = false;
  StreamSubscription<DocumentSnapshot> userlistener;

  @override
  void initState() {
    super.initState();

    //current user listener
    userlistener = usersRef.doc(myProfile.uid).snapshots().listen((event) {
      if (event.exists) {
        myProfile = UserModel.fromJson(event.data());
        setState(() {});
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    userlistener.cancel();
  }

  //handle deep link

  Future handleStartUpLogic() async {
    // call handle dynamic links
    await DynamicLinkService().handleDynamicLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      handleStartUpLogic();
    }
  }

  //handle on refresh
  void _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  //refresh completed
  void _onLoading() async {
    await Future.delayed(Duration(milliseconds: 1000));
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            body: Container(
              child: Column(
                children: [
                  Container(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                      ),
                      child: buildScheduleCard()),

                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Making a StreamBuilder to listen to changes in real time
                        StreamBuilder<QuerySnapshot>(
                          stream: roomsRef.snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<QuerySnapshot> snapshot) {
                            // Handling errors from firebase
                            if (snapshot.hasError)
                              return Text('Error: ${snapshot.error}');
                            if(snapshot.data == null) return noDataWidget("No Rooms yet", fontfamily: "InterSemiBold", fontsize: 21);
                            return snapshot.hasData
                                ? SmartRefresher(
                                    enablePullDown: true,
                                    controller: _refreshController,
                                    onRefresh: _onRefresh,
                                    onLoading: _onLoading,
                                    child: ListView(
                                      padding: const EdgeInsets.only(
                                        bottom: 80,
                                        left: 20,
                                        right: 20,
                                      ),
                                      children: snapshot.data.docs
                                          .map((DocumentSnapshot document) {
                                        return Dismissible(
                                          key: ObjectKey(document.data),
                                          onDismissed: (direction) {
                                            roomsRef.doc(document.id).delete();
                                          },
                                          child: buildRoomCard(
                                            Room.fromJson(document),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  )
                                : Center(
                                    child: CircularProgressIndicator(),
                                  );
                          },
                        ),
                        buildGradientContainer(),
                        buildStartRoomButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget buildScheduleCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: ScheduleCard(),
    );
  }

  addUserToRoom(Room room, ClientRole role) async {
    //ADD USE TO ROOM
    await Database().updateRoomData(room.roomid, {
      "users": FieldValue.arrayUnion([myProfile.toMap(usertype: "others")]),
    });

    //UPDDATE USER ACTIVE ROOM
    await Database()
        .updateProfileData(myProfile.uid, {"activeroom": room.roomid});

    enterRoom(room.roomid, room, role);
  }

  Widget buildRoomCard(Room room) {
    return GestureDetector(
      onTap: () {
        ClientRole role;

        //CHECK USER IF IS THE OWNER
        if (room.ownerid == Get.find<UserController>().user.uid) {
          role = ClientRole.Broadcaster;
          enterRoom(room.roomid, room, role);
        } else {
          role = ClientRole.Audience;
          //CHECK IF USER IS ACTIVE ON ANOTHER ROOM AND PROMPT TO HIM TO LEAVE
          if (myProfile.activeroom.isNotEmpty &&
              myProfile.activeroom != room.roomid) {
            var alert = new CupertinoAlertDialog(
              title: new Text(''),
              content: new Text(
                  'Joining a new room will remove you from your current room'),
              actions: <Widget>[
                new CupertinoDialogAction(
                    child: const Text('Okay'),
                    isDestructiveAction: true,
                    onPressed: () async {
                      if (engine != null) {
                        engine.leaveChannel();
                      }
                      Navigator.pop(context);
                      addUserToRoom(room, role);
                    }),
                new CupertinoDialogAction(
                    child: const Text('Cancel'),
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ],
            );
            showDialog(
                context: context,
                builder: (context) {
                  return alert;
                });
          } else {
            addUserToRoom(room, role);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: RoomCard(
          room: room,
        ),
      ),
    );
  }

  Widget buildGradientContainer() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Style.LightBrown.withOpacity(0.2),
          Style.LightBrown,
        ],
      )),
    );
  }

  Widget buildStartRoomButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: CustomButton(
          onPressed: () {
            showBottomSheet();
          },
          color: Style.AccentGreen,
          text: '+ Start a room'),
    );
  }

  enterRoom(String roomid, Room room, ClientRole role) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (rc) {
        return RoomScreen(
          roomid: roomid,
          room: room,
          role: role,
        );
      },
    );
  }

  showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      )),
      builder: (context) {
        return Wrap(
          children: [
            LobbyBottomSheet(
              onChange: (String txt) {},
              onButtonTap: (roomtype, topic, List<UserModel> users) async {
                print(roomtype + " " + topic);
                Navigator.pop(context);

                try {
                  setState(() {
                    loading = true;
                  });

                  // creating aroom

                  var ref = await Database().createRoom(
                      userData: myProfile,
                      topic: topic,
                      type: roomtype,
                      users: users);
                  ref.get().then((value) async {
                    Room room = Room.fromJson(value);
                    await Permission.microphone.request();
                    enterRoom(
                      ref.id,
                      room,
                      ClientRole.Broadcaster,
                    );
                  });

                  setState(() {
                    loading = false;
                  });
                } catch (e) {
                  print("error " + e.toString());
                }
              },
            ),
          ],
        );
      },
    );
  }
}
