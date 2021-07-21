import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/pages/home/profile_page.dart';
import 'package:roomies/pages/home/follower_page.dart';
import 'package:roomies/pages/room/roomies_screen.dart';
import 'package:roomies/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/widgets.dart';
class HomePage extends StatelessWidget {
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
            children: [

              //rooms list page
              RommiesScreen(),

              //followers page
              FollowerPage(),
            ],
          ),
        );
      }
    );
  }
}
