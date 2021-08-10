import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/home/home_page.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/widgets/noitem_widget.dart';
import 'package:roomies/widgets/user_profile_image.dart';
import 'package:roomies/widgets/widgets.dart';

class FollowFriends extends StatefulWidget {
  const FollowFriends({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FollowFriendsState();
  }
}

class _FollowFriendsState extends State<FollowFriends> with WidgetsBindingObserver {
  UserModel userModel;
  List<String> followed = [];
  bool deselect = false;
  @override
  void initState() {

    super.initState();
    usersRef.doc(FirebaseAuth.instance.currentUser.uid).get().then((event) {
      userModel = UserModel.fromJson(event.data());
      followed = userModel.following;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildGradientContainer() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Style.LightBrown.withOpacity(0.2),
              Style.LightBrown,
            ],
          )),
    );
  }
  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: false,
          title: const Text('Are you sure?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Roomies will be be pretty quiet for you."),
              SizedBox(height: 20,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                      onTap: (){
                        deselect = !deselect;
                        setState(() {

                        });
                        Navigator.pop(context);
                      },
                      child: Text("NEVER MIND", style: TextStyle(color: Style.AccentBlue),)
                  ),
                  SizedBox(height: 20,),
                  InkWell(
                      onTap: (){
                        Get.to(() => HomePage());
                        Navigator.pop(context);
                      },
                      child: Text("YES", style: TextStyle(color: Style.AccentBlue),)
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Style.followColor,
      body: SafeArea(
        child: CupertinoPageScaffold(
          backgroundColor: Style.followColor,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30,),
                    Center(
                      child: Text(
                        "Follow new friends to have access to their rooms",
                        textScaleFactor: 1.0,
                        style: TextStyle(fontSize: 23, color: Colors.black, fontFamily: "InterSemiBold"),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 30,),
                      Expanded(
                          child: StreamBuilder(
                            stream: Database.friendsToFollow(),
                            builder: (context, snapshot) {
                              if(snapshot.connectionState == ConnectionState.waiting){
                                return Container(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if(snapshot.data == null){
                                return noDataWidget("No Friends to follow yet");
                              }
                              if(snapshot.hasData){
                                List<UserModel> users = snapshot.data;
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
                              }
                            }
                          )),
                  ],
                ),
                Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,child: buildGradientContainer()),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      width: 200,
                      child: CustomButton(
                          padding: EdgeInsets.symmetric(vertical: 13, horizontal: 25),
                          onPressed: () {
                            if(deselect == true){
                              _showMyDialog();
                            }else {
                              Get.to(() => HomePage());
                            }

                          },
                          color: Style.AccentBlue,
                          text: deselect == true ? "Skip ->" : 'Follow -> '),
                    ),
                  ),
                ),

                Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,child: Column(children: [
                  InkWell(
                    onTap: (){
                      deselect = !deselect;
                      if(deselect == true){
                        Database().updateProfileData(userModel.uid, {
                          "following": []
                        });
                      }else{
                        Database().updateProfileData(userModel.uid, {
                          "following": FieldValue.arrayUnion(followed)
                        });
                      }
                      setState(() {

                      });
                    },
                    child: Text(deselect == true ? "Or use our suggestons" : "Deselect all", style: TextStyle(color: Style.AccentBlue, fontFamily: "InterBold"),),
                  )
                ],))
              ],
            ),
          ),
        ),
      ),
    );
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
          TextButton(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all(Colors.transparent),
            ),
            child: deselect == false && followed.contains(user.uid) ? Icon(Icons.check_circle) : Icon(Icons.add_circle_outline),
            onPressed: () {
              if (userModel.following.contains(user.uid)) {
                print("unfollow " + user.uid);
                followed.remove(user.uid);
                Database().unFolloUser(user.uid);
              } else {
                print("follow " + user.uid);
                followed.add(user.uid);
                Database().folloUser(user);
              }
            },
          ),
        ],
      ),
    );
  }
}
