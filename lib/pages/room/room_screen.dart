import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/room/followers_match_grid_sheet.dart';
import 'package:roomies/pages/home/profile_page.dart';
import 'package:roomies/widgets/room_profile.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/services/dynamic_link_service.dart';
import 'package:roomies/util/configs.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:roomies/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:roomies/Notifications/push_nofitications.dart';

RtcEngine engine;
/*
    class to manage rooms
    all room functionality is held here
 */
class RoomScreen extends StatefulWidget {
  final String roomid;
  final Room room;
  final ClientRole role;

  const RoomScreen({Key key, this.roomid, this.role, this.room})
      : super(key: key);

  @override
  _RoomScreenState createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin {
  UserModel myProfile = Get.put(UserController()).user;
  bool waitinguser = false;
  Room room;
  String currentUserType = "";
  List<UserModel> otherusers = [];
  List<UserModel> raisedhandsusers = [];
  List<UserModel> _tempListOfUsers = [];
  List<UserModel> speakerusers = [];
  AnimationController _animationController;
  Animation _colorTween;
  int index = -2;
  var mycalluid = 0;
  StreamSubscription<DocumentSnapshot> roomlistener;
  final TextEditingController textController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {

    //initialize agora engine
    engine = await RtcEngine.create(APP_ID);

    //wait for room to be generated
    setState(() {
      waitinguser = true;
    });

    //defining ring around the active user speaking
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _colorTween = ColorTween(begin: Colors.white, end: Colors.grey)
        .animate(_animationController);

    //setting room object from the parameters from the previous screen
    room = widget.room;

    //start listening for changes in the room
    roomlistener =
         roomsRef.doc(widget.roomid).snapshots().listen((event) async {
      if (event.exists == false && room.ownerid != myProfile.uid) {
        //notify user when room has been deleted
        var alert = new CupertinoAlertDialog(
          title: new Text('Room is not longer available'),
          content:
              new Text('room you was actively on has been deleted by the host'),
          actions: <Widget>[
            new CupertinoDialogAction(
                child: const Text('Okay'),
                isDestructiveAction: true,
                onPressed: () async {
                  Navigator.pop(context);
                  Navigator.pop(context);

                  await engine.leaveChannel();
                  await engine.destroy();
                }),
          ],
        );

        //show the alert dialog
        showDialog(
            context: context,
            builder: (context) {
              return alert;
            });
      } else {

        //update room variables and re-generate room object
        try {
          speakerusers.clear();
          otherusers.clear();
          room = Room.fromJson(event);

          _tempListOfUsers = room.users;

          //POPULATE USERS WHO HAVE RAISED THEIR HANDS
          if (room.raisedhands.length > raisedhandsusers.length) {
            raisedhandsusers = room.raisedhands;
          }

          if (room.users.length > 0) {
            index = room.users
                .indexWhere((element) => element.uid == myProfile.uid);
            if (index != -1) {
              currentUserType = room.users[index].usertype;
            }
            var speakers = room.users.where((row) =>
                (row.usertype.contains("host")) ||
                row.usertype.contains("speaker"));
            speakerusers.addAll(speakers);

            var others =
                room.users.where((row) => (row.usertype.contains("others")));
            otherusers.addAll(others);
            setState(() {
              waitinguser = false;
            });
          }
        } catch (e) {
          print(e.toString());
        }
      }
    });

    initialize();
  }

  //methos invoked when user is leaving the room
  Future<void> leaveChannel() async {
    if (index != -1) {
      print(room.users[index].usertype);
      if (room.users[index].usertype == "host") {

        //notify user if he is the host that the room will be deleted
        var alert = new CupertinoAlertDialog(
          title: new Text('Leaving will end the room.'),
          content:
              new Text('you can wait a little longer to have people join.'),
          actions: <Widget>[
            new CupertinoDialogAction(
                child: const Text('End Room'),
                isDestructiveAction: true,
                onPressed: () async {
                  quitRoomandPop();
                  Navigator.pop(context);
                  roomlistener.cancel();
                  roomsRef.doc(room.roomid).delete();
                }),
            new CupertinoDialogAction(
                child: const Text('Wait'),
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        );

        //show alert
        showDialog(
            context: context,
            builder: (context) {
              return alert;
            });
      } else {
        //regenerate the users who have raised their hands
        int index2 = room.raisedhands
            .indexWhere((element) => element.uid == myProfile.uid);
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
        room.users.removeAt(index);
        roomsRef.doc(room.roomid).update({
          "users": room.users
              .map((i) => i.toMap(
                  usertype: i.usertype,
                  callmute: i.callmute,
                  callerid: i.callerid))
              .toList(),
        });

        quitRoomandPop();
      }
    } else {
      quitRoomandPop();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
    if (room.users.length == 0) {
      engine.leaveChannel();
      engine.destroy();
    }
  }

  /// Create Agora SDK instance and initialize
  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
  }

  //init agora sdk
  Future<void> _initAgoraRtcEngine() async {
    try {
      await Permission.microphone.request();
      await engine.enableAudio();
      await engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
      await engine.enableAudioVolumeIndication(500, 3, true);
      engine.renewToken("token");
      await engine.setDefaultAudioRoutetoSpeakerphone(true);
      await engine.setClientRole(ClientRole.Broadcaster);
      await engine.joinChannel(room.token, room.ownerid, null, 0);
    } catch (e) {
      print("error general " + e.toString());
    }
  }

  //when user icon is clicked
  searchUserClickCallBack(UserModel user){
    Get.back();
    showUserProfile(context, user);
  }

  /// Add Agora event handlers
  void _addAgoraEventHandlers() {
    engine.setEventHandler(RtcEngineEventHandler(error: (code) async {
      setState(() {
        print('onError: $code');
      });
    }, joinChannelSuccess: (channel, uid, elapsed) async {
      print('onJoinChannel: $channel, uid: $uid');
      mycalluid = uid;
      // mute user microphone if he is not the host
      if (room.users.length > 1) {
        print("muting two");
        engine.muteLocalAudioStream(true);
      }
      //enabling phone loud speaker
      await engine.setEnableSpeakerphone(true);

    }, leaveChannel: (stats) {
      print("leaving one");
    }, userOffline: (uid, elapsed) {
      final info = 'userOffline: $uid';
      print(info);
      if (uid == mycalluid) {
        topTrayPopup("you have a poor connection");
      }
    }, audioRouteChanged: (AudioOutputRouting audioOutputRouting) {
      print("audioOutputRouting " + audioOutputRouting.index.toString());
    }, userJoined: (uid, elapsed) {
      print('userJoined: $uid');
    }, audioVolumeIndication:
        (List<AudioVolumeInfo> speakers, int totalVolume) {
      speakers.forEach((eleme) {
        //CHECK IF SOUND IS FROM THE CURRENT USER
        bounceRings(eleme, totalVolume);
      });
    }));
  }

  //user click listener on the ping user bottom sheet
  callback(UserModel user){
    // Get.back();
    String title = Get.find<UserController>().user.getName() +
        " pinged you to join " +
        room.title;
    PushNotificationsManager().callOnFcmApiSendPushNotifications(
        [user.firebasetoken], title, title);
  }

  @override
  Widget build(BuildContext context) {
    return waitinguser == true
        ? Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              toolbarHeight: 150,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  IconButton(
                    iconSize: 30,
                    icon: Icon(Icons.keyboard_arrow_down),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'All rooms',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => ProfilePage(
                          profile: myProfile,
                          fromRoom: false,
                        ),
                      );
                    },
                    child: RoundImage(
                      url: myProfile.imageurl,
                      width: 40,
                      height: 40,
                    ),
                  ),
                ],
              ),
            ),
            body: Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(30),
                  topLeft: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      bottom: 80,
                      top: 20,
                    ),
                    child: Column(
                      children: [
                        room != null ? buildTitle(room.title) : Text(""),
                        SizedBox(
                          height: 10,
                        ),
                        buildSpeakers(speakerusers),
                        buildOthers(otherusers),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child:buildBottom(context, room)
                  ),
                ],
              ),
            ),
            // bottomSheet: buildBottom(context, room),
          );
  }


  //bottomsheet widget to control the room privacy
  Widget buildBottom(BuildContext context, Room room) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.room.roomtype == "Closed")
            Column(
              children: [
                Divider(),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "This is a closed room",
                        style: TextStyle(fontSize: 16),
                      ),
                      InkWell(
                        onTap: () {
                          showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) =>
                                  CupertinoActionSheet(
                                      title: Text("Who else can join?"),
                                      actions: [
                                        CupertinoActionSheetAction(
                                          child: const Text('Everyone',
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 16)),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                        CupertinoActionSheetAction(
                                          child: const Text(
                                              'Followed by the moderator',
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontSize: 16)),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                      cancelButton: CupertinoActionSheetAction(
                                        child: Text(
                                          'Cancel',
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      )));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[200]),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 10),
                            child: Text("Open it Up"),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => leaveChannel(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 16.0,
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
                        TextSpan(
                          text: 'Leave quietly',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              buildBottomNav()
            ],
          )
        ],
      ),
    );
  }

  //room time widget
  Widget buildTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            Container(
              child: IconButton(
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                        actions: [
                          CupertinoActionSheetAction(
                            child: const Text('Share Room'),
                            onPressed: () {
                              final RenderBox box = context.findRenderObject();
                              DynamicLinkService()
                                  .createGroupJoinLink(room.roomid)
                                  .then((value) async {
                                Navigator.pop(context);
                                await Share.share(value,
                                    subject: "Join " + room.title,
                                    sharePositionOrigin:
                                        box.localToGlobal(Offset.zero) &
                                            box.size);
                              });
                            },
                          ),
                          CupertinoActionSheetAction(
                            child: const Text('Search Room'),
                            onPressed: () {
                              Navigator.pop(context);
                              searchPeopleRoom(context);
                            },
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          child: Text(
                            'End Room',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            print("end room");
                            quitRoomandPop();
                            roomlistener.cancel();
                            roomsRef.doc(room.roomid).delete();
                            Navigator.of(context, rootNavigator: true)
                                .pop("Cancel");
                          },
                        )),
                  );
                },
                iconSize: 30,
                icon: Icon(Icons.more_horiz),
              ),
            ),
            if (widget.room.roomtype == "Closed")
              IconButton(
                  onPressed: () {}, iconSize: 25, icon: Icon(Icons.lock)),
          ],
        )
      ],
    );
  }

  //speakers widget
  Widget buildSpeakers(List<UserModel> users) {
    return GridView.builder(
      shrinkWrap: true,
      physics: ScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: users.length,
      itemBuilder: (gc, index) {
        return AnimatedBuilder(
          animation: _colorTween,
          builder: (context, child) => GestureDetector(
            onTap: () {},
            child: RoomProfile(
              user: users[index],
              isModerator: index == 0,
              bordercolor:
                  users[index].valume > 0 ? _colorTween.value : Colors.white,
              isMute: room.users[index].callmute,
              room:room,
              size: 70,
            ),
          ),
        );
      },
    );
  }

  //other uses widget
  Widget buildOthers(List<UserModel> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Others in the room',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.grey.withOpacity(0.6),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: ScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: MediaQuery.of(context).size.width /
                (MediaQuery.of(context).size.height),
          ),
          itemCount: users.length,
          itemBuilder: (gc, index) {
            return GestureDetector(
                onTap: () {}, child: RoomProfile(user: users[index], size: 70));
          },
        ),
      ],
    );
  }

  //search people in the room widget
  void searchPeopleRoom(context) {
    showModalBottomSheet(
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        context: context,
        builder: (context) {
          //3
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
                expand: false,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.only(
                              top: 15, left: 10, bottom: 5),
                          child: Text(
                            "Search people in the room",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        Container(
                            padding: EdgeInsets.all(8),
                            margin: EdgeInsets.only(bottom: 10),
                            child: Row(children: <Widget>[
                              Expanded(
                                  child: TextField(
                                      controller: textController,
                                      decoration: InputDecoration(
                                        hintText: "Search",
                                        contentPadding: EdgeInsets.all(5),
                                        border: new OutlineInputBorder(
                                          borderRadius:
                                              new BorderRadius.circular(8.0),
                                          borderSide: new BorderSide(),
                                        ),
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _tempListOfUsers =
                                              _buildSearchList(value);
                                        });
                                      })),
                            ])),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: GridView.builder(
                              itemCount: _tempListOfUsers.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3),
                              itemBuilder: (BuildContext context, int index) {
                                if (textController.text.isEmpty) {
                                  return userWidget(user: _tempListOfUsers[index],clickCallBack: searchUserClickCallBack);
                                } else if (_tempListOfUsers[index]
                                        .firstname
                                        .toLowerCase()
                                        .contains(textController.text) ||
                                    _tempListOfUsers[index]
                                        .lastname
                                        .toLowerCase()
                                        .contains(textController.text)) {
                                  return userWidget(user: _tempListOfUsers[index],clickCallBack: searchUserClickCallBack);
                                }
                                return Container();
                              },
                            ),
                          ),
                        )
                      ]);
                });
          });
        });
  }

  //search people to ping to join the room
  void pingPeopleRoom(context) {
    showModalBottomSheet(
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
        ),
        context: context,
        builder: (context) {
          //3
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
                expand: false,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Container(padding: const EdgeInsets.only(
                      top: 15, left: 10, bottom: 10),
                      child: FollowerMatchGridPage(callback: callback,title: "Ping people into the room",fromroom: true,),
                  );
                });
          });
        });
  }

  //ebuild users list when user is filtering
  List<UserModel> _buildSearchList(String userSearchTerm) {
    List<UserModel> _searchList = [];

    for (int i = 0; i < room.users.length; i++) {
      String name = room.users[i].getName();
      if (name.toLowerCase().contains(userSearchTerm.toLowerCase())) {
        _searchList.add(room.users[i]);
      }
    }
    return _searchList;
  }

  //bottom widget of the room screen
  Widget buildBottomNav() {
    // print("BottomNavs ${user.uid} ${room.ownerid}");
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            pingPeopleRoom(context);
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
                          return raisedHandsView(mystate);
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
            .indexWhere((element) => element.uid == myProfile.uid) !=-1 && room.users[room.users
                        .indexWhere((element) => element.uid == myProfile.uid)]
                    .usertype ==
                "others"
            ? GestureDetector(
                onTap: () {
                  // if(room.raisedhands == 1 || myProfile){
                  raiseMyHandView(context);
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
                  callMuteUnmute();
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

  //raise hands action bottom sheet widget
  raiseMyHandView(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        builder: (context) {
          return Container(
            height: 350,
            margin: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.hand_raised_fill,
                  size: 60.0,
                  color: Color(0XFFE5C9B6),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    "Raise your hand?",
                    style:
                        TextStyle(fontSize: 18, fontFamily: "InterExtraBold"),
                  ),
                ),
                Center(
                    child: Text(
                  "This will let the speaker know you have something you'd like to say",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontFamily: "InterRegular"),
                )),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 35),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 21, vertical: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.red
                            ),
                            child: Text(
                              "Never mind",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: "InterBold",
                                  color: Colors.white),
                            ),
                          )),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 13),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.red
                        ),
                        child: TextButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              topTrayPopup(
                                  " you  raised your hand! we'll let the speakers know you want to talk..");

                              if (room.raisedhands.any(
                                  (element) => element.uid == myProfile.uid)) {
                                return;
                              }
                              await roomsRef.doc(room.roomid).set({
                                "raisedhands": FieldValue.arrayUnion(
                                    [room.users[index].toMap()]),
                              }, SetOptions(merge: true));
                            },

                            icon: Icon(
                              CupertinoIcons.hand_raised_fill,
                              size: 20.0,
                              color: Color(0XFFE5C9B6),
                            ),
                            label: Text(
                              "Raise hand",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: "InterBold",
                                  color: Colors.white),
                            )),
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        });
  }

  //raised hands bottom sheet widget
  Widget raisedHandsView(StateSetter mystate) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.hand_raised_fill,
                      size: 30.0,
                      color: Colors.grey,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Raised hands",
                            style: TextStyle(
                                fontSize: 18, fontFamily: "InterSemiBold"),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            room.getHandsRaisedByType(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, fontFamily: "InterRegular"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                InkWell(
                    onTap: () {
                      showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) {
                            return CupertinoActionSheet(
                                title: Text("Raised hands available to.."),
                                actions: [
                                  CupertinoActionSheetAction(
                                    child: const Text('Everyone'),
                                    onPressed: () async {
                                      mystate(() {});
                                      await Database().updateRoomData(
                                          room.roomid, {"handsraisedby": 1});
                                      Navigator.pop(context);
                                    },
                                  ),
                                  CupertinoActionSheetAction(
                                    child:
                                        const Text('Followed by the Speakers'),
                                    onPressed: () async {
                                      await Database().updateRoomData(
                                          room.roomid, {"handsraisedby": 2});
                                      mystate(() {});
                                      Navigator.pop(context);
                                    },
                                  ),
                                  CupertinoActionSheetAction(
                                    child: const Text('Nobody'),
                                    onPressed: () async {
                                      await Database().updateRoomData(
                                          room.roomid, {"handsraisedby": 3});
                                      mystate(() {});
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  child: Text(
                                    'Cancel',
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ));
                          });
                    },
                    child: Text(
                      "Edit",
                      style: TextStyle(color: Colors.blueAccent),
                    )),
              ],
            ),
          ),
          room.raisedhands.length == 0
              ? Container(
                  margin: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                      child: Text(
                    "No raised hands yet",
                    style: TextStyle(fontSize: 21),
                  )))
              : Text(""),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: room.raisedhands.map((UserModel user) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: ListTile(
                  // leading: UserProfileImage(imageUrl: user.imageurl, size: 60, type:"header"),
                  title: Text(user.username),
                  trailing: GestureDetector(
                    onTap: () {
                      activateDeactivateUser(user);
                      mystate(() {});
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: user.callmute == true ? Colors.grey : Colors.red,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                            bottomLeft: Radius.circular(25)),
                      ),
                      width: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark,
                            size: 23.0,
                            color: Colors.white,
                          ),
                          const Icon(
                            CupertinoIcons.mic_solid,
                            size: 23.0,
                            color: Colors.white,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  //bouncine ring functionality when user is speaking
  void bounceRings(AudioVolumeInfo eleme, int totalVolume) {
    if (eleme.uid == 0 && totalVolume > 0) {
      room.users[room.users.indexWhere((element) => element.usertype == "host")]
          .valume = totalVolume;
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    } else if (room.users
                .indexWhere((element) => element.callerid == eleme.uid) !=
            -1 &&
        totalVolume > 0) {
      room
          .users[
              room.users.indexWhere((element) => element.callerid == eleme.uid)]
          .valume = totalVolume;
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }
  }


  //exit room and navigate back to homepage
  Future<void> quitRoomandPop() async {
    await engine.leaveChannel();
    await engine.destroy();
    roomlistener.cancel();
    Navigator.pop(context);
  }


  //mute user mic
  void callMuteUnmute() {
    room.users[index].callmute = !room.users[index].callmute;
    engine.muteLocalAudioStream(room.users[index].callmute);
    roomsRef.doc(room.roomid).update({
      "users": room.users
          .map((i) => i.toMap(
              usertype: i.usertype, callmute: i.callmute, callerid: i.callerid))
          .toList(),
    });
    setState(() {});
  }

  //add user to speaker
  //remove user from being speaker
  void activateDeactivateUser(UserModel user) {
    if (room.raisedhands.indexWhere((element) => element.uid == user.uid) ==
        -1) {
      //user ha already removed his hand
      setState(() {});
    } else {
      print(raisedhandsusers.length.toString());
      raisedhandsusers.removeAt(
          room.raisedhands.indexWhere((element) => element.uid == user.uid));
      print(raisedhandsusers.length.toString());
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
      setState(() {});
    }
  }
}
