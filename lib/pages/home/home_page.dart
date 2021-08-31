import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/util/configs.dart';
import 'package:roomies/pages/home/profile_page.dart';
import 'package:roomies/pages/home/follower_page.dart';
import 'package:roomies/pages/room/roomies_screen.dart';
import 'package:roomies/services/authenticate.dart';
import 'package:roomies/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/util/utils.dart';
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    updatesCheck();
  }
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
                'Roomies has a new update, kindly update to enjoying new exciting features and fixed bugs'),
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: HomeAppBar(
              profile: _.user,
              onProfileTab: () {
                Get.to(() => ProfilePage(
                  profile: _.user,
                  fromRoom: false,
                ));
              },
            ),
          ),
          body: PageView(
            controller: pageController,
            children: [


              //followers page
              FollowerPage(),
              //rooms list page
              RommiesScreen(),
            ],
          ),
        );
      }
    );
  }
}
