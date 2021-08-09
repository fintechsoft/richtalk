import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/functions/functions.dart';
import 'package:intl/intl.dart';
import '../../widgets/widgets.dart';

class NotificationActivities extends StatefulWidget {
  @override
  _NotificationActivitiesState createState() => _NotificationActivitiesState();
}

class _NotificationActivitiesState extends State<NotificationActivities> {
  StreamSubscription<QuerySnapshot> stream;
  List<ActivityItem> activities = [];

  @override
  void initState() {
    stream = activitiesRef
        .where("to", isEqualTo: Get.find<UserController>().user.uid)
        .orderBy("time", descending: true)
        .snapshots()
        .listen((event) {
      activities.clear();
      if (event.docs.length > 0) {
        event.docs.forEach((element) {
          activities.add(ActivityItem.fromJson(element.data(),element.id));
        });
      }
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    stream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Style.followColor,
        body: SingleChildScrollView(
          child: CupertinoPageScaffold(
            backgroundColor: Style.followColor,
            navigationBar: CupertinoNavigationBar(
              border: null,
              padding: EdgeInsetsDirectional.only(top: 20),
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
                "NOTIFICATIONS",
                textScaleFactor: 1.0,
                style: TextStyle(fontSize: 21, color: Colors.black),
              ),
            ),

            child: Column(
              mainAxisAlignment: activities.length == 0
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [

                if (activities.length == 0)
                  noDataWidget("No Activities yet", fontsize: 21),
                if (activities.length > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: ScrollPhysics(),
                      itemBuilder: (lc, index) {
                        return Column(
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  RoundImage(
                                    url: activities[index].imageurl,
                                    borderRadius: 18,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Expanded(
                                    child: Wrap(
                                      children: [
                                        Text(
                                          activities[index].name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${activities[index].message}',
                                          style: TextStyle(
                                            color: Style.DarkBrown,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Container(
                                    margin: EdgeInsets.only(left: 5),
                                    child: Text(
                                      Functions.timeAgoSinceDate(
                                          DateFormat("dd-MM-yyyy h:mma").format(
                                              activities[index].time.toDate())),
                                      style:
                                          TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            if(activities[index].type == "clubinvite" && activities[index].actioned == false)Column(
                              children: [
                                Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      CustomButton(
                                        onPressed: (){
                                            Database.acceptClubInvite(activities[index].actionkey);
                                            print(activities[index].id);
                                            Database.activityUpdate(activities[index].id,{
                                              "actioned" : true
                                            });
                                        },
                                        minimumWidth: 150,
                                        minimumHeight: 20,
                                        color: Style.AccentBlue,
                                        fontSize: 12,
                                        text: 'Join',
                                      ),
                                      CustomButton(
                                        onPressed: (){},
                                        minimumWidth: 150,
                                        minimumHeight: 20,
                                        color: Colors.white,
                                        txtcolor: Style.AccentBlue,
                                        fontSize: 12,
                                        text: 'Ignore',
                                      )
                                    ],
                                  ),
                                ),
                                Divider(height: 1,),
                              ],
                            )
                          ],
                        );
                      },
                      itemCount: activities.length,
                    ),
                  ),
              ],
            ),
          ),
        ));
  }
}
