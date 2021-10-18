import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/Interest.dart';
import 'package:richtalk/models/user_model.dart';
import 'package:richtalk/pages/home/search_view.dart';
import 'package:richtalk/pages/home/select_interests.dart';
import 'package:richtalk/pages/room/notifications.dart';
import 'package:richtalk/pages/room/upcoming_roomsreen.dart';
import 'package:richtalk/util/configs.dart';
import 'package:richtalk/pages/home/profile_page.dart';
import 'package:richtalk/pages/home/follower_page.dart';
import 'package:richtalk/pages/room/roomies_screen.dart';
import 'package:richtalk/services/authenticate.dart';
import 'package:richtalk/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:richtalk/util/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/widgets.dart';
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

PageController pageController = PageController(
  initialPage: 1,
  keepPage: true,
);
class _HomePageState extends State<HomePage> {
  bool isCallApi = false;
  bool loading = false;
  Color alcol=Style.pinkAccent;
  Color altex=Colors.white;
  bool altap=false;

  StreamSubscription<DocumentSnapshot> userlisterner;

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    updatesCheck();
    getFirebaseData();
    userlisterner = usersRef.doc(FirebaseAuth.instance.currentUser.uid).snapshots().listen((event) {
      Get.put(UserController()).user = UserModel.fromJson(event.data());
      setState(() {
      });
    });
  }

  QuerySnapshot tempList;
  List<Interest> selectedItemList = [];

  updatesCheck(){
    //if account has an issue, logout automatically
    if(FirebaseAuth.instance.currentUser !=null){
      usersRef.doc(FirebaseAuth.instance.currentUser.uid).snapshots().listen((value){
        if(value.exists == false){
          AuthService().signOut();
        }
      });
    }

    settingsRef.snapshots().listen((event) async {

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String code = packageInfo.buildNumber;
      if(event.docs.length > 0){

        if(int.parse(code) < event.docs[0].data()["version"] && Platform.isAndroid){
          var alert = new CupertinoAlertDialog(
            title: new Text(''),
            content: new Text(
                'RichTalk has a new update, kindly update to enjoying new exciting features and fixed bugs'),
            actions: <Widget>[
              new CupertinoDialogAction(
                  child: const Text('Update Now'),
                  isDestructiveAction: event.docs[0].data()["forced"],
                  onPressed: () async {
                    String url = "";
                    if (Platform.isAndroid) {
                      // Android-specific code
                      url = playstoreUrl;
                    } else if (Platform.isIOS) {
                      // iOS-specific code
                    }
                    if (await canLaunch(url))
                    await launch(url);
                    else
                    // can't launch url, there is some error
                    throw "Could not launch $url";
                    // Navigator.pop(context);
                  }),
              new CupertinoDialogAction(
                  child: const Text('Maybe Later'),
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
        }

      }


    });
  }
  @override
  Widget build(BuildContext context) {
    return GetX<UserController>(
      initState: (_) async{
        Get.find<UserController>().user = await Database().getUserProfile(FirebaseAuth.instance.currentUser.uid);
      },
      builder: (_) {
        if(_.user == null){
          return Scaffold(
            body: Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        return Scaffold(
          // appBar: AppBar(
          //   automaticallyImplyLeading: false,
          //   title: HomeAppBar(
          //     profile: _.user,
          //     onProfileTab: () {
          //       Get.to(() => ProfilePage(
          //         profile: _.user,
          //         fromRoom: false,
          //       ));
          //     },
          //   ),
          // ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            toolbarHeight: 100,
            centerTitle: true,
            elevation: 0.5,
            title:
                Container(
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: (){
                          Get.to(()=>SearchView());
                        },
                        child:Container(
                          child:
                          Row(
                            children: [
                              Icon(
                                Icons.search,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width-100,
                                padding: EdgeInsets.all(10),
                                decoration: new BoxDecoration(color: Colors.black12,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12.0),
                                  ),
                                ),
                                child: Text("Search"),
                              )
                            ],
                          ),
                        ) ,
                      ),
                      funListViewData(
                          list: tempList.docs[0]['data'],
                          categoryName:
                          tempList.docs[0].id.toString()
                      ),
                    ],
                  ),
                ),

            actions: [
              GestureDetector(
                onTap: () {
                  Get.to(() => NotificationActivities());
                },
                child: Icon(
                  Icons.notifications_none,
                ),
              ),
              SizedBox(
                width: 14,
              )
            ],
          ),
            body: PageView(
              controller: pageController,
              children: [
                //followers page
                FollowerPage(),
                //rooms list page
                RommiesScreen(showbutton: false,),
              ],
            ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.compass),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.add_circled_solid,size: 40,),
                label: 'New Room',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.folder),
                label: 'Files',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Style.pinkAccent,
            unselectedItemColor: Colors.black26,
            // onTap: _onItemTapped,
            onTap: (int index){
              _onItemTapped;
              switch(index)
              {
                case 0:
                  break;
                case 1:
                  Get.to(() => UpcomingRoomScreen());
                  break;
                case 2:
                pageController.animateToPage(2,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.ease);
                  Get.to(() => RommiesScreen(showbutton:true));
                  break;
                case 3:
                  Get.to(() => SearchView());
                  break;
                case 4:
                  Get.to(() => ProfilePage(
                    profile: _.user,
                    fromRoom: false,
                  ));
                  break;
              }
            },
            showSelectedLabels: false,
            showUnselectedLabels: false,
          ),
        );
      }
    );
  }

  Widget funListViewData({List list, String categoryName}) {

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 2000,
        child: Wrap(
          direction: Axis.horizontal,
          children: listMyWidgets(list),
        ),
      ),
    );

  }
  List<Widget> listMyWidgets(List<dynamic> docs) {
    List<Widget> list = [];
    list.add( GestureDetector(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical:7),
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: Text(
          "All Topics",
          style: TextStyle(
              fontSize: 16, fontFamily: "Roboto",
              color: altex,
          ),
        ),
        decoration: BoxDecoration(
          color: alcol,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              // color: ccc.getactiveBgColor.value,
              // blurRadius: 4,
            ),
          ],
        ),
      ),
      onTap: () {
        setState(() {
          if(altap)
            {
              alcol=Style.pinkAccent;
              altex=Colors.white;
              altap=false;
            }
          else
            {
              alcol=Colors.white;
              altex=Colors.black;
              altap=true;
            }
        });

      },
    ));
    for(var itemm in docs){
      Interest item = Interest.fromJson2(itemm, docs.indexOf(itemm).toString());
      list.add( GestureDetector(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical:7),
          margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Text(
            item.title,
            style: TextStyle(
                fontSize: 16, fontFamily: "Roboto",
                color: getColor(item.title) || Get.put(UserController()).user.interests.contains(item.title) ? Colors.white : Colors.black
            ),
          ),
          decoration: BoxDecoration(
            color: getColor(item.title) || Get.put(UserController()).user.interests.contains(item.title) ? Style.pinkAccent : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                // color: ccc.getactiveBgColor.value,
                // blurRadius: 4,
              ),
            ],
          ),
        ),
        onTap: () {
          updateUserInterests(item);
          setState(() {
          });

        },
      ));
    }
    return list;
  }

  getFirebaseData() async {
    isCallApi = true;
    setState(() {});
    tempList = await interestsRef.get();
    isCallApi = false;
    setState(() {});
  }
  void updateUserInterests(Interest item) {
    bool isAddData = true;
    for (var i = 0; i < selectedItemList.length; i++) {
      if (selectedItemList[i].title == item.title) {
        isAddData = false;
        selectedItemList.removeAt(i);
        usersRef.doc(Get.find<UserController>().user.uid).update({
          "Spaces" : FieldValue.arrayRemove([item.title])
        });

        break;
      } else {
        isAddData = true;
      }
    }
    if (isAddData) {
      selectedItemList.add(Interest(title: item.title));
      //check if its from signup
      usersRef.doc(FirebaseAuth.instance.currentUser.uid).update({
        "Spaces" : FieldValue.arrayUnion([item.title])
      });
    }
  }
  bool getColor(String itemName) {
    bool val = false;
    for (var i = 0; i < selectedItemList.length; i++) {
      if (selectedItemList[i].title == itemName || Get.find<UserController>().user.interests.contains(itemName)) {
        val = true;
        break;
      } else {
        val = false;
      }
    }
    return val;
  }
}
