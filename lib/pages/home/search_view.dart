import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/clubs/view_club.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/widgets/noitem_widget.dart';
import 'package:roomies/widgets/user_profile_image.dart';
import 'package:roomies/widgets/widgets.dart';

class SearchView extends StatefulWidget {
  const SearchView({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SearchViewState();
  }
}

class _SearchViewState extends State<SearchView> with WidgetsBindingObserver, SingleTickerProviderStateMixin  {
  StreamSubscription<DocumentSnapshot> streamSubscription;
  UserModel userModel;
  QuerySnapshot tempList;
  List<Interest> selectedItemList = [];
  bool isCallApi = false, loading = false;
  FocusNode _focus = new FocusNode();
  List<UserModel> _allUsers = [];
  TabController _tabController;

  TextEditingController _controller = new TextEditingController();
  var profile = Get.put(OnboardingController());

  Stream<List<UserModel>> users;
  Stream<List<Club>> clubs;

  int tabindex = 0;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
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
    setState(() {

    });
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
      backgroundColor: Style.AccentBrown,
      body: CupertinoPageScaffold(
        backgroundColor: Style.AccentBrown,
        navigationBar: CupertinoNavigationBar(
          border: null,
          padding: EdgeInsetsDirectional.only(top: 20),
          backgroundColor: Style.AccentBrown,
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
            style: TextStyle(fontSize: 18, fontFamily: "InterLight"),
          ),
        ),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: 20, right: 10, top: 20),
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
                          onChanged: (value) async {
                            loading = true;
                            setState(() {

                            });
                            searchData(value);

                            loading = false;
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.fromLTRB(8.0, 13.0, 8.0, 8.0),
                            prefixIcon: Icon(Icons.search),
                            hintText: "Find People and Clubs",
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                          )),
                    ),
                  ),
                  if(_focus.hasFocus) Padding(
                    padding: const EdgeInsets.only(top: 18, right: 20),
                    child: TextButton(onPressed : (){
                      _focus.unfocus();
                      _controller.text = "";
                      searchData("");
                      setState(() {

                      });
                    },child: Center(child: Text("cancel", style: TextStyle(fontSize: 16, color: Style.AccentGrey), textAlign: TextAlign.center,))),
                  )
                ],
              ),
              if(_focus.hasFocus) Expanded(child: Container(margin:EdgeInsets.only(top: 20),child: tabsSearch())),
              if(!_focus.hasFocus)Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

            ],
          ),
        ),
      ),
    );
  }

  tabsSearch(){
    return Column(
      children: [
        // give the tab bar a height [can change hheight to preferred height]
        Container(
          height: 35,
          child: TabBar(
            indicatorColor: Style.indigo,
            indicatorWeight: 3,
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black,
            onTap: (index){
              setState(() {
                tabindex = index;
              });
              searchData(_controller.text);
            },
            tabs: [
              // first tab [you can add an icon using the icon property]
              Tab(
                child: Text(
                  "People",
                  style: TextStyle(fontFamily: "InterSemiBold",fontSize: 15),
                ),
              ),
              // first tab [you can add an icon using the icon property]
              Tab(
                child: Text(
                  "Clubs",
                  style: TextStyle(fontFamily: "InterSemiBold",fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: TabBarView(
              controller: _tabController,
              children: [
                // first tab bar view widget
                loading == true ? Center(
                  child: CircularProgressIndicator(),
                ) : Container(
                  margin: EdgeInsets.only(top: 20),
                  child: StreamBuilder(
                      stream: users,
                      builder: (context, snapshot) {
                        if(snapshot.data !=null){
                          List<UserModel> users = snapshot.data;
                          if(users.length == 0) return Container();
                          return ListView.separated(
                            separatorBuilder: (c, i) {
                              return Container(
                                height: 15,
                              );
                            },
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              return singleItem(users[index]);
                            },
                          );
                        }else{
                          return Container();
                        }
                      }
                  ),
                ),
                // first tab bar view widget
                loading == true ? Center(
                  child: CircularProgressIndicator(),
                ) : Container(
                  margin: EdgeInsets.only(top: 20),
                  child: StreamBuilder(
                      stream: clubs,
                      builder: (context, snapshot) {
                        if(snapshot.data !=null){
                          List<Club> clubs = snapshot.data;
                          if(clubs.length == 0) return Container();
                          return ListView.separated(
                            separatorBuilder: (c, i) {
                              return Container(
                                height: 15,
                              );
                            },
                            itemCount: clubs.length,
                            itemBuilder: (context, index) {
                              return singleClub(clubs[index]);
                            },
                          );
                        }else{
                          return Container();
                        }
                      }
                  ),
                ),
              ],
            ),
          ),
        )
      ],
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
          UserProfileImage(
            user: user,
            txt: user.firstname,
            width: 45,
            height: 45,
            txtsize: 16,
            borderRadius: 18,
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
          if(!_focus.hasFocus) TextButton(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all(Colors.transparent),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                  fontFamily: "InterSemiBold",
                  fontSize: 13
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
  Widget singleClub(Club club) {
    return InkWell(
      onTap: (){
        Get.to(() => ViewClub(club: club,));
      },
      child: Container(
        child: Row(
          children: [
            RoundImage(
              url: club.imageurl,
              txt: club.title,
              width: 55,
              height: 55,
              txtsize: 16,
              borderRadius: 18,
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
                    club.title.toUpperCase(),
                    textScaleFactor: 1,
                    style: TextStyle(fontSize: 12,fontFamily: "InterSemiBold"),
                  ),
                  SizedBox(height: 5,),
                  Text(
                    club.members.length.toString()+" Members",
                    textScaleFactor: 1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  searchData(value) {
    if(tabindex == 0){
      users =  Database.searchUser(value);
    }else if(tabindex == 1){
      clubs =  Database.searchClub(value);
    }
  }
}
