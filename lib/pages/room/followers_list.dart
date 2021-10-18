import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/services/database.dart';
import 'package:richtalk/util/firebase_refs.dart';
import 'package:richtalk/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:richtalk/widgets/noitem_widget.dart';

//ignore: must_be_immutable
class FollowersList extends StatefulWidget {
  Club club;

  FollowersList({this.club});

  @override
  State<StatefulWidget> createState() {
    return _FollowersListState();
  }
}

class _FollowersListState extends State<FollowersList>
    with WidgetsBindingObserver {
  StreamSubscription<DocumentSnapshot> streamSubscription;
  QuerySnapshot tempList;
  List<Interest> selectedItemList = [];
  bool isCallApi = false;
  FocusNode _focus = new FocusNode();

  bool loading = false;
  TextEditingController _controller = new TextEditingController();
  var profile = Get.put(OnboardingController());
  UserModel userModel = Get.find<UserController>().user;

  @override
  void initState() {
    invitedlistener();
    _focus.addListener(_onFocusChange);
    super.initState();
  }

  void _onFocusChange() {
    debugPrint("Focus: " + _focus.hasFocus.toString());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');
  }

  @override
  void dispose() {
    if(streamSubscription !=null){
      streamSubscription.cancel();
    }

    super.dispose();
  }

  //listening to the users profile cahnges
  invitedlistener() {
    //listener for the current user profile followers and followed
    if(widget.club !=null){
      streamSubscription =
          clubRef.doc(widget.club.id).snapshots().listen((event) {
            widget.club = Club.fromJson(event);
            setState(() {});
          });

    }
  }

  bool getColor(String itemName) {
    bool val = false;
    for (var i = 0; i < selectedItemList.length; i++) {
      if (selectedItemList[i].title == itemName) {
        val = true;
        break;
      } else {
        val = false;
      }
    }
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.followColor,
      body: CupertinoPageScaffold(
              backgroundColor: Style.followColor,
              navigationBar: CupertinoNavigationBar(
                border: null,
                padding: EdgeInsetsDirectional.fromSTEB(0,10,10,10),
                backgroundColor: Style.followColor,
                automaticallyImplyLeading: false,
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.back,
                    size: 35,
                    color: CupertinoColors.black,
                  ),
                  onPressed: () {
                    Get.back();
                  },
                ),
                middle: Text(
                  "ADD MEMBERS",
                  textScaleFactor: 1.0,
                  style: TextStyle(fontSize: 21, color: Colors.black),
                ),
                  trailing: widget.club.id == null ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        loading = true;
                      });
                      await Database().addClub(
                          title: widget.club.title,
                          description: widget.club.description,
                          allowfollowers: widget.club.allowfollowers,
                          membersprivate: widget.club.membersprivate,
                          membercanstartrooms: widget.club.membercanstartrooms,
                          selectedTopicsList: widget.club.topics);
                      setState(() {
                        loading = false;
                      });
                      Navigator.pop(context);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Done",
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 23,
                          fontFamily: "InterSemiBold"),
                    ),
                  ),
                ) : null,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Style.themeColor),
                      child: TextField(
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.blueAccent,
                          ),
                          focusNode: _focus,
                          controller: _controller,
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            contentPadding:
                                EdgeInsets.fromLTRB(8.0, 13.0, 8.0, 8.0),
                            prefixIcon: Icon(Icons.search),
                            hintText: "Find People",
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                          )),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Recommended Members",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Expanded(
                        child: StreamBuilder(
                            stream: Database.getmyFollowers(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return ListView.separated(
                                  separatorBuilder: (c, i) {
                                    return Container(
                                      height: 15,
                                    );
                                  },
                                  itemCount:
                                      _buildSearchList(snapshot.data).length,
                                  itemBuilder: (context, index) {
                                    return singleItem(
                                        _buildSearchList(snapshot.data)[index]);
                                  },
                                );
                              } else {
                                return noDataWidget("No users to invite yet");
                              }
                            })),
                  ],
                ),
              ),
            ),
    );
  }

  List<UserModel> _buildSearchList(List<UserModel> users) {
    List<UserModel> _searchList = [];
    if (_controller.text.isEmpty) {
      return users;
    }
    for (int i = 0; i < users.length; i++) {
      String name = users[i].getName();
      if (name.toLowerCase().contains(_controller.text.toLowerCase())) {
        _searchList.add(users[i]);
      }
    }
    return _searchList;
  }

  Widget singleItem(UserModel user) {
    return Container(
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            clipBehavior: Clip.hardEdge,
            child: CachedNetworkImage(
              imageUrl: user.imageurl,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.getName(),
                  textScaleFactor: 1,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.bio,
                  textScaleFactor: 1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 16,
          ),
          if (widget.club != null)
            widget.club != null && widget.club.invited !=null && widget.club.invited.contains(user.uid)
                ? Wrap(
              children: ["✓", " Invited"].map((e) => Text(e)).toList(),
            )
                : TextButton(
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Style.pinkAccent,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  "Invite",
                  textScaleFactor: 1,
                  style: TextStyle(
                    color: Style.pinkAccent,
                  ),
                ),
              ),
              onPressed: () {
                if (widget.club == null) {
                  print("uninvite " + user.uid);
                  // Database().unInviteUser(widget.club, user);
                }
                else {
                  print("invite " + user.uid);
                  Database().inviteUserToClub(widget.club, user);
                }
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
