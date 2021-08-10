import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/functions/functions.dart';
import 'package:roomies/pages/home/home_page.dart';
import 'package:roomies/pages/room/room_screen.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/services/dynamic_link_service.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roomies/util/utils.dart';
import 'package:roomies/widgets/noitem_widget.dart';
import 'package:roomies/widgets/room_card.dart';
import 'package:roomies/models/room.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/lobby_bottom_sheet.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/widgets/schedule_card_old.dart';
import 'package:roomies/widgets/user_profile_image.dart';
import 'package:roomies/widgets/widgets.dart';

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

  StreamSubscription<DocumentSnapshot> listener;

  //initialize varaibles
  String roomtype = "open";
  bool loading = false;

  bool showhalfroom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Data.addInterests();
    listener = usersRef.doc(myProfile.uid).snapshots().listen((event) {
      myProfile = UserModel.fromJson(event.data());
      Get.find<UserController>().user = myProfile;
      setState(() {

      });
    });
  }

  Future<void> registerNewRoom({roomtype, topic, List<UserModel> users,Club club}) async {
    try {
      setState(() {
        loading = true;
      });

      Navigator.pop(context);
      //CREATING A NEW ROOM


      var ref = await Database().createRoom(
          userData: myProfile,
          topic: topic,
          type: roomtype,
          users: users,
          clubid: club !=null ? club.id : "",
          clubname: club !=null ? club.title : "",
          context: context);
      ref.get().then((value) async {
        Room room = Room.fromJson(value);
        await Permission.microphone.request();
        enterRoom(
          ref.id,
          room,
          ClientRole.Broadcaster,
        );
        setState(() {
          loading = false;
        });

      });
    } catch (e) {
      print("error when creating room " + e.toString());
    }
  }

  Future<void> _joinexistingroom(Room room) async {
    // Get.find<CurrentRoomController>().room = null;
    ClientRole role;

    //CHECK USER IF IS THE OWNER or he already exists in the room
    if (room.ownerid == Get.find<UserController>().user.uid ||
        room.users.indexWhere((element) =>
                element.uid == Get.find<UserController>().user.uid) !=
            -1) {
      role = ClientRole.Broadcaster;
      enterRoom(room.roomid, room, role);
    } else {
      role = ClientRole.Audience;
      //CHECK IF USER IS ACTIVE ON ANOTHER ROOM AND PROMPT TO HIM TO LEAVE
      await Database().leaveActiveRoom(context: context);
      //add user to the room
      addUserToRoom(room, role);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    listener.cancel();
    super.dispose();
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
      Database().updateProfileData(myProfile.uid, {
        "online": true,
      });
    }
    if (state == AppLifecycleState.paused) {
      Database().updateProfileData(myProfile.uid, {
        "online": false,
        "lastAccessTime": DateTime.now().microsecondsSinceEpoch
      });
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildScheduleCard(),
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Making a StreamBuilder to listen to changes in real time
                      StreamBuilder<QuerySnapshot>(
                        stream: roomsRef
                            .orderBy("created_time", descending: true)
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          // Handling errors from firebase
                          if (snapshot.hasError)
                            return Text('Error: ${snapshot.error}');

                          return snapshot.hasData
                              ? snapshot.data.docs.length > 0
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
                                              if (document.data()["ownerid"] ==
                                                  myProfile.uid) {
                                                roomsRef
                                                    .doc(document.id)
                                                    .delete();
                                              }
                                            },
                                            child: buildRoomCard(
                                              Room.fromJson(document),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : noDataWidget("No Rooms yet",
                                      fontfamily: "InterSemiBold", fontsize: 21)
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
            if (loading == true)
              Center(
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  color: Colors.white60,
                  child: LoadingIndicator(
                    indicatorType: Indicator.ballPulse,

                    /// Required, The loading type of the widget
                    colors: const [Colors.white],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildScheduleCard() {
    return Container(
      child: ScheduleCardOld(),
    );
  }

  addUserToRoom(Room room, ClientRole role) async {
    //ADD USE TO ROOM
    if(myProfile == null && myProfile.username.isEmpty){
      topTrayPopup("Error creating a room at this time, try again later");
    }else{
      await Database().addUserToRoom(room: room, role: role, user: myProfile);
      enterRoom(room.roomid, room, role);
    }

  }

  Widget buildRoomCard(Room room) {
    return GestureDetector(
      onTap: () {
        _joinexistingroom(room);
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
      height: 80,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Positioned(
              left: 30,
              child: Stack(
                children: [
                  InkWell(
                      onTap: () {
                        pageController.animateToPage(0,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.ease);
                      },
                      child: Icon(
                        CupertinoIcons.circle_grid_3x3,
                        size: 30,
                      )),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 15,
                      width: 15,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Style.AccentGreen),
                    ),
                  )
                ],
              ),
              top: 15,
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: CustomButton(
                    padding: EdgeInsets.symmetric(vertical: 13, horizontal: 25),
                    onPressed: () {
                      showBottomSheet();
                    },
                    color: Style.AccentGreen,
                    text: '+ Start a room'),
              ),
            ),
          ],
        ),

        GetX<CurrentRoomController>(builder: (_) {
          Room activeroom = _.room;

          if (activeroom == null || activeroom.roomid == null)
            return Container();
          showhalfroom = true;
          return InkWell(
            onTap: () => enterRoom(
                activeroom.roomid,
                activeroom,
                activeroom.ownerid == myProfile.uid
                    ? ClientRole.Broadcaster
                    : ClientRole.Audience),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        activeroom.users.length > 1
                            ? Container(
                              child: UserProfileImage(
                                  user: activeroom.users[1],
                                  width: 45,
                                  height: 45,
                                  borderRadius: 20,
                                ),
                            )
                            : Container(),
                        Container(
                          margin: EdgeInsets.only(left: 42),
                          child: UserProfileImage(
                            user: activeroom.users[0],
                            width: 45,
                            height: 45,
                            borderRadius: 20,
                          ),
                        ),
                        activeroom.users.length > 2
                            ? RoundImage(
                                margin: EdgeInsets.only(left: 84),
                                width: 45,
                                height: 45,
                                borderRadius: 20,
                                url: "",
                                txt: "+" +
                                    (activeroom.users.length - 2).toString(),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Functions.leaveChannel(
                          room: activeroom,
                          currentUser: myProfile,
                          context: context,
                          quit: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '✌🏾',
                              style: TextStyle(fontSize: 15.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  buildBottomNav(
                      activeroom, context, myProfile, activeroom.raisedhands),
                ],
              ),
            ),
          );
        })
      ],
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
      isScrollControlled: true,
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
              onButtonTap: (roomtype, topic, List<UserModel> users, Club club) async {
                registerNewRoom(roomtype:roomtype, topic:topic, users:users, club:club);
              },
            ),
          ],
        );
      },
    );
  }
}
