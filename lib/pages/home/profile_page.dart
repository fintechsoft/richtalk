import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/models/user_model.dart';
import 'package:roomies/pages/clubs/new_club.dart';
import 'package:roomies/pages/clubs/view_club.dart';
import 'package:roomies/pages/room/room_screen.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/services/dynamic_link_service.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:roomies/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'settings_page.dart';

//ignore: must_be_immutable
class ProfilePage extends StatefulWidget {
  UserModel profile;
  bool fromRoom = false;
  Room room;

  ProfilePage({this.profile, this.fromRoom, this.room});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String followtxt = "";
  UserModel userModel;
  StreamSubscription<DocumentSnapshot> streamSubscription;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    followersFollowingListener();
  }

  @override
  void dispose() {
    streamSubscription.cancel();
    super.dispose();
  }

  //listening to the users profile cahnges
  followersFollowingListener() {
    //listener for the current user profile followers and followed

    streamSubscription = usersRef
        .doc(Get.find<UserController>().user.uid)
        .snapshots()
        .listen((event) {
      userModel = UserModel.fromJson(event.data());
      if (userModel.following.contains(widget.profile.uid)) {
        followtxt = "Unfollow";
      } else {
        followtxt = "Follow";
      }
      setState(() {});
    });

    //listener for the user profile followers and followed
    usersRef.doc(widget.profile.uid).snapshots().listen((event) {
      widget.profile = UserModel.fromJson(event.data());
      if (userModel.following.contains(widget.profile.uid)) {
        followtxt = "Unfollow";
      } else {
        followtxt = "Follow";
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.fromRoom
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              actions: [
                if (widget.profile.uid == Get.find<UserController>().user.uid)
                  IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        userSettings();
                      }),
                if (widget.profile.uid != Get.find<UserController>().user.uid)
                  IconButton(
                      icon: Icon(Icons.more_horiz),
                      onPressed: () {
                        userActionSheet();
                      })
              ],
            ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildProfile(context),
              SizedBox(
                height: 20,
              ),
              if (widget.fromRoom == true)
                CustomButton(
                  minimumWidth: MediaQuery.of(context).size.width,
                  color: Colors.grey[200],
                  text: "Move to Audience",
                  txtcolor: Colors.black,
                  fontSize: 13,
                  onPressed: () async {
                    var currentprofileuser = widget.room.users[widget.room.users
                        .indexWhere(
                            (element) => element.uid == widget.profile.uid)];

                    var currentuser = widget.room.users[widget.room.users
                        .indexWhere((element) =>
                            element.uid == Get.find<UserController>().user.uid)];

                    Navigator.pop(context);
                    if (currentprofileuser.uid == currentuser.uid ||
                        (currentuser.usertype == "speaker" ||
                            currentuser.usertype == "host")) {
                      await Database().updateRoomData(widget.room.roomid, {
                        "users": widget.room.users
                            .map((i) => i.toMap(
                                usertype: i.uid == currentprofileuser.uid
                                    ? "others"
                                    : i.usertype,
                                callmute: i.uid == currentprofileuser.uid
                                    ? true
                                    : i.callmute,
                                callerid: i.callerid))
                            .toList()
                      });
                      engine.setClientRole(ClientRole.Audience);
                    }
                  },
                ),
              SizedBox(
                height: 20,
              ),
              if (widget.fromRoom == true)
                CustomButton(
                  minimumWidth: MediaQuery.of(context).size.width,
                  color: Colors.grey[200],
                  text: "Move to Moderator",
                  txtcolor: Colors.black,
                  fontSize: 13,
                  onPressed: () async {
                    var currentprofileuser = widget.room.users[widget.room.users
                        .indexWhere(
                            (element) => element.uid == widget.profile.uid)];

                    var currentuser = widget.room.users[widget.room.users
                        .indexWhere((element) =>
                            element.uid == Get.find<UserController>().user.uid)];

                    if (currentuser.usertype == "speaker" ||
                        currentuser.usertype == "host") {
                      Navigator.pop(context);
                      await Database().updateRoomData(widget.room.roomid, {
                        "users": widget.room.users
                            .map((i) => i.toMap(
                                usertype: i.uid == currentprofileuser.uid
                                    ? "host"
                                    : i.usertype,
                                callmute: i.callmute,
                                callerid: i.callerid))
                            .toList()
                      });
                      engine.setClientRole(ClientRole.Broadcaster);
                    }
                  },
                ),
              if (widget.fromRoom == false) builderInviter(),
              SizedBox(
                height: 30,
              ),
              Text(
                "Member of",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(
                height: 10,
              ),
              myClubs()
            ],
          ),
        ),
      ),
    );
  }

  Widget myClubs() {
    return StreamBuilder(
        stream: Database.getMyClubs(),
        builder: (context, snapshot) {
          if(snapshot.hasError){
            print(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            List<Club> club = snapshot.data;
            return Row(
              children: [
                Container(
                  height: 40,
                  child: ListView(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    children: club.map((e) => InkWell(
                      onTap: () {
                        Get.to(() => ViewClub(club: e,));
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Style.SelectedItemGrey),
                        child: Center(
                            child: Text(
                              e.title.substring(0,2).toUpperCase(),
                              style: TextStyle(fontFamily: "InterSemiBold"),
                            )),
                      ),

                    )).toList(),
                  ),
                ),
                SizedBox(width: 5,),
                if (widget.profile.uid == Get.find<UserController>().user.uid) InkWell(
                  onTap: () {
                    if(userModel.clubs.length >= 3){
                      topTrayPopup("You can only add 3 clubs");
                    }else{
                      Get.to(() => NewClub());
                    }

                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Style.SelectedItemGrey),
                    child: Center(
                        child: Text(
                          "+",
                          style: TextStyle(fontSize: 20),
                        )),
                  ),
                )
              ],
            );
          }else{
            return Container();
          }
        });
  }

  /*
      profile action sheet
   */
  userActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
          title: Text(widget.profile.getName()),
          actions: [
            CupertinoActionSheetAction(
              child:
                  const Text('Share Profile..', style: TextStyle(fontSize: 16)),
              onPressed: () {
                if (widget.room != null) {
                  final RenderBox box = context.findRenderObject();
                  DynamicLinkService()
                      .createGroupJoinLink(widget.room.roomid)
                      .then((value) async {
                    Navigator.pop(context);
                    await Share.share(value,
                        subject: "Join " + widget.room.title,
                        sharePositionOrigin:
                            box.localToGlobal(Offset.zero) & box.size);
                  });
                }
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Block',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
              onPressed: () {
                Navigator.pop(context);
                var alert = new CupertinoAlertDialog(
                  title: new Text("Block ${widget.profile.getName()}"),
                  content: new Text(
                      'This will prevent them from entering rooms where you are a speaker, and we\'ll warn you about rooms where they are speaking'),
                  actions: <Widget>[
                    new CupertinoDialogAction(
                        child: const Text('Cancel'),
                        isDestructiveAction: true,
                        onPressed: () async {
                          Navigator.pop(context);
                        }),
                    new CupertinoDialogAction(
                        child: const Text('Block'),
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
              },
            ),
            if (widget.fromRoom == true)
              CupertinoActionSheetAction(
                child: const Text('Remove from room',
                    style: TextStyle(color: Colors.red, fontSize: 16)),
                onPressed: () {
                  Navigator.pop(context);
                  roomsRef.doc(widget.room.roomid).delete();
                },
              ),
            if (widget.fromRoom == true)
              CupertinoActionSheetAction(
                child: const Text('Remove and report',
                    style: TextStyle(color: Colors.red, fontSize: 16)),
                onPressed: () {
                  Navigator.pop(context);
                  roomsRef.doc(widget.room.roomid).delete();
                },
              ),
            if (widget.fromRoom == false)
              CupertinoActionSheetAction(
                child: const Text('Report an incident',
                    style: TextStyle(color: Colors.red, fontSize: 16)),
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
          )),
    );
  }

  /*
      profile widget
   */
  Widget buildProfile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundImage(
              url: widget.profile.imageurl,
              width: 100,
              height: 100,
              borderRadius: 35,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.fromRoom == true)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.profile.uid !=
                          Get.find<UserController>().user.uid)
                        IconButton(
                          icon: Icon(Icons.more_horiz),
                          onPressed: () {
                            userActionSheet();
                          },
                        ),
                      IconButton(
                        icon: Icon(CupertinoIcons.xmark),
                        onPressed: () {
                          Get.back();
                        },
                      ),
                    ],
                  ),
                SizedBox(
                  height: 10,
                ),
                if (widget.profile.uid != Get.find<UserController>().user.uid)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: InkWell(
                            onTap: () {
                              topTrayPopup(
                                  "You will be notified when ${widget.profile.getName()} is talking");
                            },
                            child: Icon(
                              CupertinoIcons.bell_circle,
                              size: 35,
                              color: Colors.blue,
                            )),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {
                          if (userModel.following
                              .contains(widget.profile.uid)) {
                            Database().unFolloUser(widget.profile.uid);
                          } else {
                            Database().folloUser(widget.profile);
                          }
                          setState(() {});
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.blue),
                          child: Text(
                            followtxt,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        Text(
          widget.profile.getName(),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 5,
        ),
        Text(
          "@" + widget.profile.username,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Row(
          children: [
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: widget.profile.followers.length.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' followers'),
                ],
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(
              width: 50,
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: widget.profile.following.length.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' following'),
                ],
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        if (widget.fromRoom == false)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: InkWell(
              onTap: () {
                addBio();
              },
              child: Text(
                widget.profile.bio.isEmpty ? "Add Bio" : widget.profile.bio,
                style: TextStyle(
                    fontSize: 15,
                    color: widget.profile.bio.isEmpty
                        ? Colors.blue
                        : Colors.black),
              ),
            ),
          ),
      ],
    );
  }

  /*
    profile settings bottom sheet
   */
  userSettings() {
    var biocontroller = TextEditingController();

    biocontroller.text = widget.profile.bio;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Style.AccentBrown,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      )),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return DraggableScrollableSheet(
              initialChildSize: 0.9,
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                    margin: EdgeInsets.only(top: 20),
                    child: SettingsPage(
                      profile: widget.profile,
                    ));
              });
        });
      },
    );
  }

  /*
      user profile bio
   */
  addBio() {
    var biocontroller = TextEditingController();

    biocontroller.text = widget.profile.bio;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Style.AccentBrown,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      )),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return DraggableScrollableSheet(
              initialChildSize: 0.9,
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Update your bio",
                        style: TextStyle(fontSize: 21),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        decoration: new BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        height: 200,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: biocontroller,
                          maxLength: null,
                          decoration: InputDecoration(
                              hintStyle: TextStyle(
                                fontSize: 20,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              fillColor: Colors.white),
                          keyboardType: TextInputType.text,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      CustomButton(
                        text: "Done",
                        color: Style.AccentBlue,
                        onPressed: () {
                          Navigator.pop(context);
                          Database().updateProfileData(
                              widget.profile.uid, {"bio": biocontroller.text});
                        },
                      )
                    ],
                  ),
                );
              });
        });
      },
    );
  }

  /*
    user invited by widget
   */
  Widget builderInviter() {
    return Row(
      children: [
        RoundImage(
          path: 'assets/images/puzzleleaf.png',
        ),
        SizedBox(
          width: 10,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.profile.lastAccessTime == null
                ? Text("")
                : Text("Joined " +
                    new DateFormat('d MMMM yyyy').format(
                        DateTime.fromMicrosecondsSinceEpoch(
                            widget.profile.lastAccessTime))),
            SizedBox(
              height: 3,
            ),
            RichText(
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: 'Nominated by ',
                  ),
                  TextSpan(
                    text: 'roomies',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
