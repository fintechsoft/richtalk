import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/util/configs.dart';
import 'package:roomies/functions/functions.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/util/utils.dart';
import 'package:roomies/widgets/room_profile.dart';
import 'package:roomies/services/dynamic_link_service.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/widgets/user_profile_image.dart';
import 'package:roomies/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';

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
  String currentUserType = "",error = "";
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
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

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
          print("listener");
      if (event.exists == false && room.ownerid != myProfile.uid && error.isEmpty) {
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
        Get.find<CurrentRoomController>().room = null;
      } else {
        //update room variables and re-generate room object
        try {
          speakerusers.clear();
          otherusers.clear();

          room = Room.fromJson(event);
          //POPULATE USERS WHO HAVE RAISED THEIR HANDS
          if (room.raisedhands.length > raisedhandsusers.length) {
            raisedhandsusers = room.raisedhands;
            if(room.ownerid == myProfile.uid) {
              UserModel raisehanduser = room.raisedhands.length == 1 ? room
                  .raisedhands[0] : room.raisedhands[room.raisedhands.length -
                  1];
              Get.snackbar("",
                  "",
                  snackPosition: SnackPosition.TOP,
                  borderRadius: 0,
                  titleText: Text("👋 ${raisehanduser.firstname + " " +
                      raisehanduser
                          .lastname} has something to say, Invite them as speaker?",
                    style: TextStyle(fontSize: 16,
                        color: Colors.white,
                        fontFamily: "InterBold"),),
                  margin: EdgeInsets.all(0),
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: Duration(days: 365),
                  messageText: Container(
                    margin: EdgeInsets.only(top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomButton(
                          color: Colors.white70,
                          text: "Dismiss",
                          txtcolor: Colors.white,
                          fontSize: 16,
                          onPressed: () {
                            Get.back();
                          },
                        ),
                        CustomButton(
                          color: Colors.white,
                          text: "Invite to speak",
                          txtcolor: Colors.green,
                          fontSize: 16,
                          onPressed: () {
                            activateDeactivateUser(
                                raisehanduser, room, null, raisedhandsusers);
                            Get.back();
                          },
                        )
                      ],
                    ),
                  ));
            }
          }


          Get.find<CurrentRoomController>().room = room;
          _tempListOfUsers = room.users;

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

  @override
  void dispose() {
    super.dispose();
    _animationController.dispose();
    // if (room.users.length == 0) {
    //   engine.leaveChannel();
    //   engine.destroy();
    // }

    print("destr");
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
      // engine.renewToken("token");
      await engine.setDefaultAudioRoutetoSpeakerphone(true);
      await engine.setClientRole(ClientRole.Broadcaster);

      //chek if user already exists
      await engine.joinChannel(room.token, room.ownerid, null, 0);
    } catch (e) {
      print("error general " + e.toString());
    }
  }

  //when user icon is clicked
  searchUserClickCallBack(UserModel user) {
    Get.back();
    showUserProfile(context, user);
  }

  /// Add Agora event handlers
  void _addAgoraEventHandlers() {
    engine.setEventHandler(RtcEngineEventHandler(error: (code) async {
      print('onError: $code');
      //delete rooms that has token expire
      if(code.toString() == "ErrorCode.TokenExpired" && APP_ENV_DEV == true){
        Functions.deleteRoom(room:room,currentuser:myProfile, context: context, roomlistener:roomlistener);
        error = code.toString();
      }
    }, joinChannelSuccess: (channel, uid, elapsed) async {
      print('onJoinChannel: $channel, uid: $uid');

      // await Database().updateRoomData(room.roomid, {
      //   "users": FieldValue.arrayUnion([myProfile.toMap(usertype: "others")]),
      // });

      mycalluid = uid;
      // mute user microphone if he is not the host
      if (myProfile.uid != room.ownerid) {
        print("muting two");
        engine.muteLocalAudioStream(true);
      }
      //enabling phone loud speaker
      await engine.setEnableSpeakerphone(true);
    }, leaveChannel: (stats) {
      print("leaving one");
      Get.find<CurrentRoomController>().room = null;
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
      // print("totalVolume ${totalVolume}");
      speakers.forEach((eleme) {
        //CHECK IF SOUND IS FROM THE CURRENT USER
        bounceRings(eleme, totalVolume);
      });
    }));
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
            key: _scaffoldKey,
            appBar: AppBar(
              toolbarHeight: 150,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      Get.find<UserController>().room = room;
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 30,
                        ),
                        Text(
                          'Hallway',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  UserProfileImage(
                    user: myProfile,
                    width: 40,
                    height: 40,
                    txtsize: 16,
                    borderRadius: 20,
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
                        buildTitle(room),
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
                      child: buildBottom(context, room, setState)),
                ],
              ),
            ),
            // bottomSheet: buildBottom(context, room),
          );
  }

  //bottomsheet widget to control the room privacy
  Widget buildBottom(BuildContext context, Room room, StateSetter state) {
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
                onTap: () async => await Functions.leaveChannel(
                    room: room,
                    currentUser: myProfile,
                    context: context,
                    roomlistener: roomlistener,
                    quit: true),
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
              buildBottomNav(room, context, myProfile, raisedhandsusers, state)
            ],
          )
        ],
      ),
    );
  }

  //room time widget
  Widget buildTitle(Room room) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: roomTitle(room),
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
                        cancelButton: room.ownerid == myProfile.uid ? null : CupertinoActionSheetAction(
                          child: Text(
                            'End Room',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            print("end room");
                            Functions.quitRoomandPop(
                                roomlistener: roomlistener, context: context);
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
          builder: (context, child) => RoomProfile(
            user: users[index],
            isModerator: index == 0,
            bordercolor:
                users[index].valume > 0 ? _colorTween.value : Colors.white,
            isMute: room.users[index].callmute,
            room: room,
            size: 70,
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
                onTap: () {},
                child: RoomProfile(
                  user: users[index],
                  size: 70,
                  room: room,
                ));
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
                                  return userWidgetWithInfo(
                                      user: _tempListOfUsers[index],
                                      clickCallBack: searchUserClickCallBack);
                                } else if (_tempListOfUsers[index]
                                        .firstname
                                        .toLowerCase()
                                        .contains(textController.text) ||
                                    _tempListOfUsers[index]
                                        .lastname
                                        .toLowerCase()
                                        .contains(textController.text)) {
                                  return userWidgetWithInfo(
                                      user: _tempListOfUsers[index],
                                      clickCallBack: searchUserClickCallBack);
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

  //bouncine ring functionality when user is speaking
  void bounceRings(AudioVolumeInfo eleme, int totalVolume) {
    if (eleme.uid == 0 && totalVolume > 0) {
      room
          .users[room.users.indexWhere((element) =>
              element.usertype == "host" || element.usertype == "speaker")]
          .valume = totalVolume;
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.reverse();
      } else {
        if(mounted) _animationController.forward();
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
}
