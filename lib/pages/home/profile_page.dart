import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailto/mailto.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/models/user_model.dart';
import 'package:richtalk/pages/clubs/new_club.dart';
import 'package:richtalk/pages/clubs/view_club.dart';
import 'package:richtalk/pages/room/room_screen.dart';
import 'package:richtalk/services/database.dart';
import 'package:richtalk/services/dynamic_link_service.dart';
import 'package:richtalk/util/firebase_refs.dart';
import 'package:richtalk/util/style.dart';
import 'package:richtalk/util/utils.dart';
import 'package:richtalk/widgets/round_button.dart';
import 'package:richtalk/widgets/round_image.dart';
import 'package:richtalk/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_page.dart';

//ignore: must_be_immutable
class ProfilePage extends StatefulWidget {
  UserModel profile;
  bool fromRoom = false;
  bool short = false;
  Room room;

  ProfilePage({this.profile, this.fromRoom, this.room, this.short});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String followtxt = "";
  UserModel userModel = Get.find<UserController>().user;
  StreamSubscription<DocumentSnapshot> streamSubscription;
  final picker = ImagePicker();
  File _imageFile;
  List<Interest> selectedTopicsList = [];
  List<String> selectedTopicsListString = [];

  bool loading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    followersFollowingListener();
  }

  _cropImage(filePath, setState) async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: filePath,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        aspectRatioPresets: [CropAspectRatioPreset.square],
        compressQuality: 70,
        compressFormat: ImageCompressFormat.jpg,
        iosUiSettings: IOSUiSettings(
          minimumAspectRatio: 1.0,
          rotateClockwiseButtonHidden: false,
          rotateButtonsHidden: false,
        ));
    if (croppedImage != null) {
      _imageFile = croppedImage;
      Get.put(OnboardingController()).imageFile = _imageFile;
      setState(() {});
    }
  }

  _getFromGallery(setState, ImageSource imageSource) async {
    PickedFile pickedFile = await picker.getImage(
      source: imageSource,
    );
    _cropImage(pickedFile.path, setState);
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
      } else if (userModel.blocked.contains(widget.profile.uid)) {
        followtxt = "Blocked";
      } else if (!userModel.following.contains(widget.profile.uid)) {
        followtxt = "Follow";
      }

      setState(() {});
    });

    //listener for the user profile followers and followed
    usersRef.doc(widget.profile.uid).snapshots().listen((event) {
      widget.profile = UserModel.fromJson(event.data());
      if (userModel.following.contains(widget.profile.uid)) {
        followtxt = "Unfollow";
      } else if (userModel.blocked.contains(widget.profile.uid)) {
        followtxt = "Blocked";
      } else if (!userModel.following.contains(widget.profile.uid)) {
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
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        backgroundColor: Style.pinkAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              print(widget.profile.username);
              final RenderBox box = context.findRenderObject();
              DynamicLinkService()
                  .createGroupJoinLink(widget.profile.username, "profile")
                  .then((value) async {
                await Share.share(value,
                    subject:
                    "Share " + widget.profile.getName() + " Profile",
                    sharePositionOrigin:
                    box.localToGlobal(Offset.zero) & box.size);
              });
            },
          ),
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
          horizontal: 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            buildProfile(context),
            Flexible(child: SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  if (widget.fromRoom == true && widget.room.users.indexWhere((element) =>
                  (element.usertype == "moderator" || element.usertype == "host") &&
                      userModel.uid == element.uid) !=
                      -1)
                    Column(
                      children: [
                        if(widget.room.users.indexWhere((element) =>
                        (element.usertype == "speaker" || element.usertype == "moderator")) ==-1) Container(
                          margin: EdgeInsets.only(bottom: 20),
                          child: CustomButton(
                            minimumWidth: MediaQuery.of(context).size.width,
                            color: Colors.grey[200],
                            text: "Make Speaker",
                            txtcolor: Colors.black,
                            fontSize: 13,
                            onPressed: () async {
                              Navigator.pop(context);
                              await Database()
                                  .updateRoomData(widget.room.roomid, {
                                "users": widget.room.users
                                    .map((i) => i.toMap(
                                    usertype: i.uid == widget.profile.uid
                                        ? "speaker"
                                        : i.usertype,
                                    callmute: i.callmute,
                                    callerid: i.callerid))
                                    .toList()
                              });
                              engine.setClientRole(ClientRole.Broadcaster);
                            },
                          ),
                        ),
                        if(widget.room.users.indexWhere((element) =>
                        (element.usertype == "moderator" || element.usertype == "speaker")) !=-1) Container(
                          margin: EdgeInsets.only(bottom: 20),
                          child: CustomButton(
                            minimumWidth: MediaQuery.of(context).size.width,
                            color: Colors.grey[200],
                            text: "Move to Audience",
                            txtcolor: Colors.black,
                            fontSize: 13,
                            onPressed: () async {
                              Navigator.pop(context);
                              await Database()
                                  .updateRoomData(widget.room.roomid, {
                                "users": widget.room.users
                                    .map((i) => i.toMap(
                                    usertype: i.uid == widget.profile.uid
                                        ? "others"
                                        : i.usertype,
                                    callmute: i.callmute,
                                    callerid: i.callerid))
                                    .toList()
                              });
                              engine.setClientRole(ClientRole.Audience);
                            },
                          ),
                        ),
                        // if (widget.fromRoom == true)
                        if(widget.room.users.indexWhere((element) =>
                        (element.usertype == "moderator")) ==-1) Container(
                          margin: EdgeInsets.only(bottom: 20),
                          child: CustomButton(
                            minimumWidth: MediaQuery.of(context).size.width,
                            color: Colors.grey[200],
                            text: "Make Leader",
                            txtcolor: Colors.black,
                            fontSize: 13,
                            onPressed: () async {

                              Navigator.pop(context);
                              await Database()
                                  .updateRoomData(widget.room.roomid, {
                                "users": widget.room.users
                                    .map((i) => i.toMap(
                                    usertype: i.uid == widget.profile.uid
                                        ? "moderator"
                                        : i.usertype,
                                    callmute: i.callmute,
                                    callerid: i.callerid))
                                    .toList()
                              });
                              engine.setClientRole(ClientRole.Broadcaster);

                            },
                          ),
                        ),
                      ],
                    ),
                  if (widget.short==null || widget.short == false||widget.profile.uid == Get.find<UserController>().user.uid)
                    if (widget.profile.uid == Get.find<UserController>().user.uid)
                      Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.only(bottom: 30, top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset("assets/icons/twitter.png", width: 20,),
                                SizedBox(width: 5,),
                                Text("Add Twitter", style: TextStyle(color: Style.pinkAccent),)
                              ],
                            ),
                            SizedBox(width: 40,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset("assets/icons/instagram.png", width: 20,),
                                SizedBox(width: 5,),
                                Text("Add Instagram", style: TextStyle(color: Style.pinkAccent),)
                              ],
                            )
                          ],
                        ),
                      ),
                  if (widget.short==null || widget.short == false)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Member of",
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        myClubs(),
                      ],
                    ),
                  if (widget.short == true)
                    CustomButton(
                      minimumWidth: MediaQuery.of(context).size.width,
                      color: Colors.grey[200],
                      text: "View full profile",
                      txtcolor: Colors.black,
                      fontSize: 13,
                      onPressed: () async {
                        showUserProfile(context, widget.profile,
                            room: widget.room, short: false);
                        Navigator.of(context);
                      },
                    ),
                ],
              ),
            ))

          ],
        ),
      ),
    );
  }

  Widget myClubs() {
    return StreamBuilder(
        stream: Database.getMyClubs(widget.profile.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
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
                    children: club
                        .map((e) => Container(
                      margin: EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () {
                          Get.to(() => ViewClub(
                            club: e,
                          ));
                        },
                        child: RoundImage(
                          url: e.imageurl,
                          width: 40,
                          height: 40,
                          borderRadius: 15,
                          txt: e.title,
                          txtsize: 16,
                        ),
                      ),
                    ))
                        .toList(),
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                if (widget.profile.uid == Get.find<UserController>().user.uid)
                  InkWell(
                    onTap: () {
                      if (userModel.clubs.length >= 3) {
                        topTrayPopup("You can only add 3 clubs");
                      } else {
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
          } else {
            return InkWell(
              onTap: () {
                if (userModel.clubs.length >= 3) {
                  topTrayPopup("You can only add 3 clubs");
                } else {
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
            );
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
                final RenderBox box = context.findRenderObject();
                DynamicLinkService()
                    .createGroupJoinLink(widget.profile.username, "profile")
                    .then((value) async {
                  await Share.share(value,
                      subject: "Share " + widget.profile.getName() + " Profile",
                      sharePositionOrigin:
                      box.localToGlobal(Offset.zero) & box.size);
                });
              },
            ),
            CupertinoActionSheetAction(
              child: Text(
                  userModel.blocked.contains(widget.profile.uid) == true
                      ? 'Unblock'
                      : "Block",
                  style: TextStyle(color: Style.pinkAccent, fontSize: 16)),
              onPressed: () {
                Navigator.pop(context);
                if (userModel.blocked.contains(widget.profile.uid)) {
                  unBlockProfile(context,
                      myprofile: userModel, reportuser: widget.profile);
                } else {
                  blockProfile(context,
                      myprofile: userModel, reportuser: widget.profile);
                }
              },
            ),
            if (widget.profile.uid != userModel.uid)
              CupertinoActionSheetAction(
                child: Text("Report ${widget.profile.username}",
                    style: TextStyle(color: Style.pinkAccent, fontSize: 16)),
                onPressed: () {
                  Navigator.pop(context);
                  reportProfile();
                },
              ),
            if (widget.fromRoom == true && widget.room.ownerid == userModel.uid)
              CupertinoActionSheetAction(
                child: const Text('Remove from room',
                    style: TextStyle(color: Style.pinkAccent, fontSize: 16)),
                onPressed: () {
                  Navigator.pop(context);
                  widget.room.users.removeAt(widget.room.users.indexWhere(
                          (element) => element.uid == widget.profile.uid));
                  Database().updateRoomData(
                      widget.room.roomid, {"users": widget.room.users});
                },
              ),
            if (widget.fromRoom == true && widget.room.ownerid == userModel.uid)
              CupertinoActionSheetAction(
                child: const Text('End Room',
                    style: TextStyle(color: Style.pinkAccent, fontSize: 16)),
                onPressed: () {
                  Navigator.pop(context);
                  roomsRef.doc(widget.room.roomid).delete();
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
    return
      SafeArea(child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
            decoration: new BoxDecoration(
              color: Style.pinkAccent,
              //   gradient: LinearGradient(
              //     begin: Alignment.centerLeft,
              //     end: Alignment.centerRight,
              //     colors: [
              //       Style.pinkAccent,
              //       Style.pinkAccent,
              //     ],
              //   ),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(20))
            ),
            child:  Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        if (widget.profile.uid == Get.find<UserController>().user.uid) {
                          updateUserPhoto();
                        }
                      },
                      child: RoundImage(
                        url: widget.profile.imageurl,
                        txtsize: 35,
                        txt: widget.profile.firstname,
                        width: 80,
                        height: 80,
                        borderRadius: 100,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.fromRoom == true)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (widget.profile.uid !=
                                  Get.find<UserController>().user.uid)
                                IconButton(
                                  color: Colors.white,
                                  icon: Icon(Icons.more_horiz),
                                  onPressed: () {
                                    userActionSheet();
                                  },
                                ),
                              IconButton(
                                color: Colors.white,
                                icon: Icon(CupertinoIcons.xmark),
                                onPressed: () {
                                  Get.back();
                                },
                              ),
                            ],
                          ),
                        if (widget.fromRoom != true)
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.fromRoom != true)
                SizedBox(
                  height: 20,
                ),

                Text(
                  widget.profile.getName(),
                  style: TextStyle(
                    fontSize:  widget.fromRoom != true ? 21: 15,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  "@"+widget.profile.username,
                  style: TextStyle(
                    fontSize:widget.fromRoom != true?15:10,
                    color: Colors.white,
                  ),
                ),
                if (widget.fromRoom != true)
                SizedBox(
                  height: 15,
                ),
                if (widget.fromRoom != true)
                Container(
                  padding: EdgeInsets.only(left: 10,right: 10,top: 10),
                  decoration: new BoxDecoration(
                    color: Style.pink,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: widget.profile.followers.length.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                      ),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: widget.profile.following.length.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.fromRoom != true)
                Container(
                  padding: EdgeInsets.only(left: 10,right: 10,top: 5, bottom: 10),
                  decoration: new BoxDecoration(
                    color: Style.pink,
                    borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: "Followers",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,

                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: "Following",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20,),
                      if (widget.profile.uid != Get.find<UserController>().user.uid)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            InkWell(
                              onTap: () {
                                if (userModel.blocked.contains(widget.profile.uid)) {
                                  unBlockProfile(context,
                                      myprofile: userModel,
                                      reportuser: widget.profile);
                                } else {
                                  if (userModel.following
                                      .contains(widget.profile.uid)) {
                                    Database().unFolloUser(widget.profile.uid);
                                  } else {
                                    Database().folloUser(widget.profile);
                                  }
                                }
                                setState(() {});
                              },
                              child: Container(
                                padding:
                                EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(topRight: Radius.circular(30),topLeft: Radius.circular(30),bottomRight: Radius.circular(30),),
                                    color:
                                    userModel.blocked.contains(widget.profile.uid)
                                        ? Style.pinkAccent
                                        : Style.pinkAccent),
                                child: Text(
                                  followtxt,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Container(
                              child: InkWell(
                                  onTap: () {
                                    topTrayPopup(
                                        "You will be notified when ${widget.profile.getName()} is talking");
                                  },
                                  child: Icon(
                                    CupertinoIcons.bell_circle,
                                    size: 35,
                                    color: Colors.white,
                                  )),
                            ),
                          ],
                        )
                    ],
                  ),
                ),
                if (widget.fromRoom == true)
                  Container(
                    padding: EdgeInsets.only(left: 10,right: 10,top: 5, bottom: 10),
                    decoration: new BoxDecoration(
                      color: Style.pink,
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: "${widget.profile.followers.length.toString()} Followers",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,

                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: "${widget.profile.following.length.toString()} Following",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20,),
                        if (widget.profile.uid != Get.find<UserController>().user.uid)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              InkWell(
                                onTap: () {
                                  if (userModel.blocked.contains(widget.profile.uid)) {
                                    unBlockProfile(context,
                                        myprofile: userModel,
                                        reportuser: widget.profile);
                                  } else {
                                    if (userModel.following
                                        .contains(widget.profile.uid)) {
                                      Database().unFolloUser(widget.profile.uid);
                                    } else {
                                      Database().folloUser(widget.profile);
                                    }
                                  }
                                  setState(() {});
                                },
                                child: Container(
                                  padding:
                                  EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(topRight: Radius.circular(30),topLeft: Radius.circular(30),bottomRight: Radius.circular(30),),
                                      color:
                                      userModel.blocked.contains(widget.profile.uid)
                                          ? Style.pinkAccent
                                          : Style.pinkAccent),
                                  child: Text(
                                    followtxt,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Container(
                                child: InkWell(
                                    onTap: () {
                                      topTrayPopup(
                                          "You will be notified when ${widget.profile.getName()} is talking");
                                    },
                                    child: Icon(
                                      CupertinoIcons.bell_circle,
                                      size: 35,
                                      color: Colors.white,
                                    )),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (widget.fromRoom != true)
          SizedBox(height: 10,),
          RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: "About myself",
                  style: TextStyle(
                    fontSize: widget.fromRoom != true? 20:15,
                    color: Style.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (widget.profile.uid == userModel.uid && widget.profile.bio.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: InkWell(
                onTap: () {
                  addBio();
                },
                child: Text(
                  widget.profile.bio.isEmpty ? "Add a bio" : widget.profile.bio,
                  style: TextStyle(
                      fontSize: widget.fromRoom != true? 15:10,
                      color:Colors.black),
                ),
              ),
            ),
          if(widget.profile.bio.isNotEmpty)Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: InkWell(
              onTap: () {
                addBio();
              },
              child: Text(
                widget.profile.bio,
                overflow: TextOverflow.ellipsis,
                maxLines: widget.short == true ? 2 : null,
                style: TextStyle(
                  fontSize: widget.fromRoom != true? 15:10,
                  color: Colors.black,),
              ),
            ),
          ),
        ],
      ));
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
      backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
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
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
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
                            color: Style.pinkAccent,
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
      report profile
   */
  reportProfile() {
    var reportcontroller = TextEditingController();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
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
                            "Why do you want to report ${widget.profile.username}?",
                            style: TextStyle(fontSize: 14),
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
                              controller: reportcontroller,
                              maxLength: null,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                  hintText:
                                  "Describe why you want to report ${widget.profile.username}",
                                  hintStyle: TextStyle(
                                    fontSize: 12,
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  fillColor: Colors.white),
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
                            text: "Report Now",
                            color: Style.pinkAccent,
                            onPressed: () async {
                              if (reportcontroller.text.isNotEmpty) {
                                Navigator.pop(context);
                                final mailtoLink = Mailto(
                                  to: [adminemail],
                                  subject:
                                  '${widget.profile.username} profile reported',
                                  body: reportcontroller.text,
                                );
                                await launch('$mailtoLink');
                              }
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

  Future<void> _showMyDialog(setState) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: false,
          title: const Text('Add a profile photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _getFromGallery(setState, ImageSource.gallery);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("Choose from galley"),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _getFromGallery(setState, ImageSource.camera);
                },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text("Take photo"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  /*
      user profile photo
   */
  updateUserPhoto() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.white,
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "Change your photo",
                            style: TextStyle(fontSize: 21),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          InkWell(
                            onTap: () {
                              _showMyDialog(setState);
                            },
                            child: _imageFile != null
                                ? Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(80),
                              ),
                              child: _imageFile != null
                                  ? Container(
                                child: ClipOval(
                                  child: Image.file(
                                    _imageFile,
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                                  : Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 100,
                                color: Style.pinkAccent,
                              ),
                            )
                                : RoundImage(
                              url: userModel.imageurl,
                              txt: userModel.firstname,
                              txtsize: 35,
                              width: 150,
                              height: 150,
                              borderRadius: 60,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          loading == true
                              ? Container(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                              : CustomButton(
                            text: "Done",
                            color: Style.pinkAccent,
                            onPressed: _imageFile == null
                                ? null
                                : () async {
                              setState(() {
                                loading = true;
                              });
                              if (_imageFile != null) {
                                await Database().uploadImage(
                                    FirebaseAuth
                                        .instance.currentUser.uid,
                                    update:
                                    true); //createUserInfo(FirebaseAuth.instance.currentUser.uid);
                              } else {
                                Get.snackbar("", "",
                                    snackPosition: SnackPosition.BOTTOM,
                                    borderRadius: 0,
                                    margin: EdgeInsets.all(0),
                                    backgroundColor: Style.pinkAccent,
                                    colorText: Colors.white,
                                    messageText: Text.rich(TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                          "Choose your profile image first",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )));
                              }

                              Navigator.pop(context);
                              setState(() {
                                loading = false;
                                _imageFile = null;
                              });
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
}
