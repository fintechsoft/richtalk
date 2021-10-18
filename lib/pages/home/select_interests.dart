import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/pages/onboarding/follow_friends.dart';
import 'package:richtalk/services/database.dart';
import 'package:richtalk/util/firebase_refs.dart';
import 'package:richtalk/util/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:richtalk/widgets/widgets.dart';
/*
    interests pick screen
 */
//ignore: must_be_immutable

class InterestsPick extends StatefulWidget {
  final String title;
  final String subtitle;
  final Club club;
  final Function selectedItemsCallback;
  final showbackarrow;
  final fromsignup;
  InterestsPick({this.title,this.subtitle,this.selectedItemsCallback,this.club,this.showbackarrow = true, this.fromsignup = false});

  @override
  _InterestsPickState createState() => _InterestsPickState();
}

class _InterestsPickState extends State<InterestsPick> {
  bool isCallApi = false;
  bool loading = false;
  StreamSubscription<DocumentSnapshot> userlisterner;

  @override
  void initState() {
    super.initState();
    if(widget.club !=null){
      selectedItemList = widget.club.topics;
    }
    getFirebaseData();
    userlisterner = usersRef.doc(FirebaseAuth.instance.currentUser.uid).snapshots().listen((event) {
      Get.put(UserController()).user = UserModel.fromJson(event.data());
      setState(() {

      });
    });

  }

  @override
  void dispose() {
    userlisterner.cancel();
    super.dispose();
  }

  QuerySnapshot tempList;
  List<Interest> selectedItemList = [];

  @override
  Widget build(BuildContext context) {
    // loading = false;
    return loading ? Center(
      child: CircularProgressIndicator(),
    ) : Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // set
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: isCallApi
                ? Center(child: CircularProgressIndicator())
                : ListView(
              children: [
                if(widget.showbackarrow == true) Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Stack(
                    children: [
                      IconButton(
                        onPressed: ()=>Get.back(),
                        icon: Icon(Icons.arrow_back_ios),
                      ),

                      Center(
                        child: Text(
                          widget.title !=null ? widget.title : 'Spaces',
                          style:
                          TextStyle(
                              fontFamily: "InterExtraBold", fontSize: 25
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Center(
                    child: Text(widget.subtitle !=null ? widget.subtitle : "Choose Your's Spaces",
                      style: TextStyle(
                          fontFamily: "Roboto bold",
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0XFF7B7B7B)
                      ),
                      textAlign: TextAlign.center,

                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Center(
                    child: Text(widget.subtitle !=null ? widget.subtitle : 'Tell as something about yourself',
                      style: TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 14,
                          color: Color(0XFF7B7B7B)
                      ),
                      textAlign: TextAlign.center,

                    ),
                  ),
                ),
                SizedBox(height: 20),
                ListView.builder(
                    physics: BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: tempList.docs.length,
                    itemBuilder: (BuildContext context, int i) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text('${tempList.docs[i].id}',
                          //     style: TextStyle(
                          //         fontSize: 15.0,
                          //         color: Colors.black,
                          //         fontFamily: "InterSemiBold"
                          //     )
                          // ),
                          // SizedBox(height: 10),
                          funListViewData(
                              list: tempList.docs[i]['data'],
                              categoryName:
                              tempList.docs[i].id.toString()
                          ),
                          SizedBox(height: 20),
                        ],
                      );
                    }),
              ],
            ),
          ),
          if(widget.fromsignup == true)Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.symmetric(horizontal: 20),
                width: 200,
                child: CustomButton(
                    padding: EdgeInsets.symmetric(vertical: 13, horizontal: 25),
                    onPressed: () {
                      Get.to(() => FollowFriends());
                    },
                    color: Style.pinkAccent,
                    text: 'Next'),
              ),
            ),
          )
        ],
      ),

    );
  }

  /*
    single interest widget
   */
  List<Widget> listMyWidgets(List<dynamic> docs) {
    List<Widget> list = [];

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
          if(widget.club !=null){
            updateClubTopics(item);
          }else{
            print(item.title+" Tapped");
            updateUserInterests(item);
          }
          setState(() {

          });

        },
      ));
    }
    return list;
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
      if( widget.selectedItemsCallback !=null ){
        widget.selectedItemsCallback(selectedItemList);
      }

      usersRef.doc(FirebaseAuth.instance.currentUser.uid).update({
        "Spaces" : FieldValue.arrayUnion([item.title])
      });
    }
  }

  void updateClubTopics(Interest item) {
    if(selectedItemList.length ==3 && selectedItemList.indexWhere((element) => element.title == item.title) < 0){
      var alert = new CupertinoAlertDialog(
        title: new Text(''),
        content: new Text(
            'A club can only have 3 topics maximum'),
        actions: <Widget>[
          new CupertinoDialogAction(
              child: const Text('Okay'),
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

    }else{
      bool isAddData = true;
      for (var i = 0; i < selectedItemList.length; i++) {
        if (selectedItemList[i].title == item.title) {
          isAddData = false;
          selectedItemList.removeAt(i);
          print(item.toMap());
          if(widget.club.id !=null){

            Database.updateClub(widget.club.id, {
              "topics" : FieldValue.arrayRemove([item.toMap()])
            });
          }else{

            widget.selectedItemsCallback(selectedItemList);
          }

          break;
        } else {
          isAddData = true;
        }
      }
      if (isAddData) {
        selectedItemList.add(Interest(title: item.title, id: item.id));

        if(widget.club.id !=null) {
          Database.updateClub(widget.club.id, {
            "topics": FieldValue.arrayUnion([item.toMap()])
          });
        }else{
          widget.selectedItemsCallback(selectedItemList);
        }
      }
    }
  }

// ==========   Use for show data in gridview based on category     ================

  Widget funListViewData({List list, String categoryName}) {

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        width: 650,
        child: Wrap(
          direction: Axis.horizontal,
          children: listMyWidgets(list),
        ),
      ),
    );

  }


// ==========   Use for get data from firebase     ================

  getFirebaseData() async {
    isCallApi = true;
    setState(() {});
    tempList = await interestsRef.get();
    isCallApi = false;
    setState(() {});
  }

  /*
      assign intersts link color
   */
  bool getColor(String itemName) {
    bool val = false;
    if(widget.club !=null){

      for (var i = 0; i < selectedItemList.length; i++) {
        if (selectedItemList[i].title == itemName || selectedItemList.indexWhere((element) => element.title == itemName) > 0) {
          val = true;
          break;
        } else {
          val = false;
        }
      }
    }else{
      for (var i = 0; i < selectedItemList.length; i++) {
        if (selectedItemList[i].title == itemName || Get.find<UserController>().user.interests.contains(itemName)) {
          val = true;
          break;
        } else {
          val = false;
        }
      }
    }
    return val;
  }
}