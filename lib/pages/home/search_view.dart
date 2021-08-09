import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/widgets/noitem_widget.dart';

class SearchView extends StatefulWidget {
  const SearchView({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SearchViewState();
  }
}

class _SearchViewState extends State<SearchView> with WidgetsBindingObserver {
  StreamSubscription<DocumentSnapshot> streamSubscription;
  UserModel userModel;
  QuerySnapshot tempList;
  List<Interest> selectedItemList = [];
  bool isCallApi = false;
  FocusNode _focus = new FocusNode();
  List<UserModel> _allUsers = [];

  TextEditingController _controller = new TextEditingController();
  var profile = Get.put(OnboardingController());

  @override
  void initState() {
    followersFollowingListener();
    _focus.addListener(_onFocusChange);

    //add list of users to remove from the query
    Get.find<UserController>()
        .user
        .following
        .add(Get.find<UserController>().user.uid);

    List<String> removeusers = Get.find<UserController>().user.following;

    //query users that i can follow
    usersRef.snapshots().listen((value) {
      _allUsers.clear();
      value.docs.forEach((element) {
        UserModel userModel = UserModel.fromJson(element.data());
        // _allUsers.add(UserModel.fromJson(element.data()));

        if (!removeusers.contains(userModel.uid)) {
          _allUsers.add(UserModel.fromJson(element.data()));
        }
      });
      setState(() {});
    });

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
      Get.find<UserController>().user = userModel;
      setState(() {});
    });
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
          padding: EdgeInsetsDirectional.zero,
          backgroundColor: Style.followColor,
          automaticallyImplyLeading: false,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.back,
              size: 25,
              color: CupertinoColors.black,
            ),
            onPressed: () {
              Get.back();
            },
          ),
          middle: Text(
            "EXPLORE",
            textScaleFactor: 1.0,
            style: TextStyle(fontSize: 21, color: Colors.black),
          ),
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
                      setState(() {
                        _buildSearchList(value);
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(8.0, 13.0, 8.0, 8.0),
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
              if (_buildSearchList(_controller.text).length > 0)
                Text(
                  "PEOPLE TO FOLLOW",
                  style: TextStyle(fontSize: 16),
                ),
              SizedBox(
                height: 20,
              ),
              if (_buildSearchList(_controller.text).length == 0)
                noDataWidget("No users yet to follow"),
              if (_buildSearchList(_controller.text).length > 0)
                Expanded(
                    child: ListView.separated(
                  separatorBuilder: (c, i) {
                    return Container(
                      height: 15,
                    );
                  },
                  itemCount: _buildSearchList(_controller.text).length,
                  itemBuilder: (context, index) {
                    return singleItem(
                        _buildSearchList(_controller.text)[index]);
                  },
                )),
            ],
          ),
        ),
      ),
    );
  }

  List<UserModel> _buildSearchList(String userSearchTerm) {
    List<UserModel> _searchList = [];
    if (userSearchTerm.isEmpty) {
      return _allUsers;
    }
    for (int i = 0; i < _allUsers.length; i++) {
      String name = _allUsers[i].getName();
      if (name.toLowerCase().contains(userSearchTerm.toLowerCase())) {
        _searchList.add(_allUsers[i]);
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
          TextButton(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all(Colors.transparent),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Style.indigo,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                userModel != null && userModel.following.contains(user.uid)
                    ? "Following"
                    : "Follow",
                textScaleFactor: 1,
                style: TextStyle(
                  color: Style.indigo,
                ),
              ),
            ),
            onPressed: () {
              if (userModel.following.contains(user.uid)) {
                print("unfollow " + user.uid);
                Database().unFolloUser(user.uid);
              } else {
                print("follow " + user.uid);
                Database().folloUser(user);
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
