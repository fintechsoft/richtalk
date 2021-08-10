import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/authenticate.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'select_interests.dart';

//ignore: must_be_immutable
class SettingsPage extends StatefulWidget {
  UserModel profile;

  SettingsPage({this.profile});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pause = false;
  UserModel profile = Get.find<UserController>().user;
  StreamSubscription<DocumentSnapshot> userlistener;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    userlistener = usersRef.doc(profile.uid).snapshots().listen((event) {
      profile = UserModel.fromJson(event.data());
      pause = profile.pausenotifications;
      setState(() {

      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    userlistener.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.AccentBrown,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            "Settings",
                            style: TextStyle(fontSize: 21),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(CupertinoIcons.xmark),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              InkWell(
                onTap: () {
                  accountSheet();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 20),
                            child: RoundImage(
                              url: widget.profile.imageurl,
                              txtsize: 18,
                              txt: widget.profile.firstname,
                              width: 50,
                              height: 50,
                              borderRadius: 15,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.profile.getName(),
                                style: (TextStyle(fontSize: 16)),
                              ),
                              Text(
                                "@" + widget.profile.username,
                                style: (TextStyle(fontSize: 13)),
                              )
                            ],
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_right_rounded,
                        size: 30,
                        color: Colors.grey,
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pause Notifications",
                          style: (TextStyle(fontSize: 16)),
                        ),
                        CupertinoSwitch(
                          value: pause,
                          onChanged: (value) {
                            setState(() {
                              pause = !pause;
                            });
                            if (pause == true) {
                              notificationActionSheet();
                            }else{
                              Database().updateProfileData(profile.uid, {
                                "pausenotifications" : false,
                              });
                            }
                          },
                        )
                      ],
                    ),
                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Send Fewer Notifications",
                          style: (TextStyle(fontSize: 16)),
                        ),
                        CupertinoSwitch(
                          value: profile.sendfewernotifications,
                          onChanged: (value) {
                            profile.sendfewernotifications = value;
                            Database().updateProfileData(profile.uid, {
                              "sendfewernotifications": value
                            });
                          },
                        )
                      ],
                    ),
                    Divider(),
                    InkWell(
                      onTap: () {
                        notificationSettingsBottomSheet();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Notification Settings",
                            style: (TextStyle(fontSize: 16)),
                          ),
                          Icon(
                            Icons.keyboard_arrow_right_rounded,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              InkWell(
                onTap: () {
                  Get.to(() => InterestsPick());
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Interests",
                        style: (TextStyle(fontSize: 16)),
                      ),
                      Row(
                        children: [
                          Text(
                            Get.find<UserController>()
                                .user
                                .interests
                                .length
                                .toString(),
                            style: (TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            )),
                          ),
                          Icon(
                            Icons.keyboard_arrow_right_rounded,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "What's New",
                            style: (TextStyle(fontSize: 16)),
                          ),
                          Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "FAQ / Contact Us",
                            style: (TextStyle(fontSize: 16)),
                          ),
                          Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Community Guidelines",
                            style: (TextStyle(fontSize: 16)),
                          ),
                          Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Terms of Service",
                            style: (TextStyle(fontSize: 16)),
                          ),
                          Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Privacy Policy",
                            style: (TextStyle(fontSize: 16)),
                          ),
                          Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
              ),
              InkWell(
                onTap: () {
                  AuthService().signOut();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Logout",
                          style: (TextStyle(fontSize: 16, color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

/*
    notification settings bottom sheet
 */
  notificationActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
          title: Text('Pause Notifications'),
          actions: [
            CupertinoActionSheetAction(
              child: const Text('For an Hour', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Database().updateProfileData(profile.uid, {
                  "pausedtime": FieldValue.serverTimestamp(),
                  "pausenotifications" : true,
                  "pausedtype" : "hour"
                });
                Navigator.pop(context);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Until this Evening',
                  style: TextStyle(fontSize: 16)),
              onPressed: () {
                var timeNow = DateTime.now().hour;
                print(timeNow);
                Database().updateProfileData(profile.uid, {
                  "pausedtime": FieldValue.serverTimestamp(),
                  "pausenotifications" : true,
                  "pausedtype" : "evening"
                });
                Navigator.pop(context);
              },
            ),
            CupertinoActionSheetAction(
              child:
                  const Text('Until Morning', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Database().updateProfileData(profile.uid, {
                  "pausedseconds" : 3600 * 24,
                  "pausedtime": FieldValue.serverTimestamp(),
                  "pausenotifications" : true,
                  "pausedtype" : "morning"
                });
                Navigator.pop(context);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('For a Week', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Database().updateProfileData(profile.uid, {
                  "pausedtime": FieldValue.serverTimestamp(),
                  "pausenotifications" : true,
                  "pausedtype" : "week"
                });
                Navigator.pop(context);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text(
              'Cancel',
            ),
            onPressed: () {
              setState(() {
                pause = !pause;
              });
              Navigator.pop(context);
            },
          )),
    ).whenComplete(() {
      setState(() {
          pause = profile.pausenotifications;
      });
    });
  }

  /*
      connect to social accounts
   */
  accountSheet() {
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
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Get.back();
                            },
                            icon: Icon(Icons.arrow_back_ios,
                                size: 30, color: Colors.grey),
                          ),
                          Center(
                              child: Text(
                            "Account",
                            style: TextStyle(fontSize: 21),
                          )),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Connect Twitter",
                                style: (TextStyle(fontSize: 16)),
                              ),
                              Divider(),
                              Text(
                                "Connect Instagram",
                                style: (TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Deactivate Account",
                                style: (TextStyle(
                                    fontSize: 16, color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
        });
      },
    );
  }

  /*
    room notification settings

   */

  notificationSettingsBottomSheet() {
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
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Get.back();
                            },
                            icon: Icon(Icons.arrow_back_ios,
                                size: 30, color: Colors.grey),
                          ),
                          Expanded(
                            child: Center(
                                child: Text(
                              "NOTIFICATION SETTINGS",
                              style: TextStyle(fontSize: 16),
                            )),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Room Notifications",
                                          style: (TextStyle(fontSize: 16)),
                                        ),
                                        Text(
                                          "When followers speak, start rooms etc",
                                          style: (TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    value: profile.subroomtopic,
                                    onChanged: (value) {
                                      if (value == true) {
                                        FirebaseMessaging.instance
                                            .subscribeToTopic(roomtopic);
                                      } else {
                                        FirebaseMessaging.instance
                                            .unsubscribeFromTopic(roomtopic);
                                      }
                                      setState(() {
                                        profile.subroomtopic = value;
                                      });
                                      Database().updateProfileData(
                                          profile.uid, {"subroomtopic": value});
                                    },
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Divider(),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Trend Notifications",
                                          style: (TextStyle(fontSize: 16)),
                                        ),
                                        Text(
                                          "Intersting Rooms, clubs etc",
                                          style: (TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    value: profile.subtrend,
                                    onChanged: (value) {
                                      if (value == true) {
                                        FirebaseMessaging.instance
                                            .subscribeToTopic(trendingtopic);
                                      } else {
                                        FirebaseMessaging.instance
                                            .unsubscribeFromTopic(
                                                trendingtopic);
                                      }
                                      setState(() {
                                        profile.subtrend = value;
                                      });
                                      Database().updateProfileData(
                                          profile.uid, {"subtrend": value});
                                    },
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Divider(),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Other Notifications",
                                          style: (TextStyle(fontSize: 16)),
                                        ),
                                        Text(
                                          "New followers speak, events,clubs etc ",
                                          style: (TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    value: profile.subothernot,
                                    onChanged: (value) {
                                      if (value == true) {
                                        FirebaseMessaging.instance
                                            .subscribeToTopic(otherstopic);
                                      } else {
                                        FirebaseMessaging.instance
                                            .unsubscribeFromTopic(otherstopic);
                                      }
                                      setState(() {
                                        profile.subothernot = value;
                                      });
                                      print(profile.uid);
                                      Database().updateProfileData(
                                          profile.uid, {"subothernot": value});
                                    },
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
        });
      },
    );
  }
}
