import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/widgets/upcomingroom_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roomies/widgets/widgets.dart';

final eventcontroller = TextEditingController();
final descriptioncontroller = TextEditingController();
bool showdatecalendarpicker = false,
    publish = false,
    loading = false,
    showtimecalendarpicker = false;
String timedisplay = "", datedisplay = "";
int timeseconds;

class UpcomingRoomScreen extends StatefulWidget {
  final UpcomingRoom room;

  const UpcomingRoomScreen({this.room});

  @override
  _UpcomingRoomScreenState createState() => _UpcomingRoomScreenState();
}

class _UpcomingRoomScreenState extends State<UpcomingRoomScreen> {
  String show = "";
  bool keyboardup = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _modalBottomSheetMenu();
    }
  }

  void _modalBottomSheetMenu() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await upcomingroomBottomSheet(context, widget.room, loading, keyboardup);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Container(
                  child: InkWell(
                onTap: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                        title: Text('What would you like to see?'),
                        actions: [
                          CupertinoActionSheetAction(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: const Text('Upcoming For You',
                                      style: TextStyle(fontSize: 16)),
                                ),
                                if (show != "mine")
                                  Icon(
                                    Icons.check,
                                    color: Colors.blue,
                                  )
                              ],
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                show = "";
                              });
                            },
                            isDefaultAction: true,
                          ),
                          CupertinoActionSheetAction(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: const Text('My Events',
                                      style: TextStyle(fontSize: 16)),
                                ),
                                if (show == "mine")
                                  Icon(
                                    Icons.check,
                                    color: Colors.blue,
                                  )
                              ],
                            ),
                            onPressed: () {
                              setState(() {
                                show = "mine";
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
                            Navigator.pop(context);
                          },
                        )),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      show == "mine" ? "MY EVENTS" : "UPCOMING FOR YOU",
                      style: TextStyle(fontSize: 17, color: Colors.black),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                    )
                  ],
                ),
              )),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 35,
                color: Colors.black,
              ),
              onPressed: () {
                createUpcomingRoomSheet(context, false);
              },
            )
          ],
        ),
      ),
      // appBar: AppBar(
      //   // padding: EdgeInsetsDirectional.only(top: 15, end: 10,bottom: 10),
      //   leading: InkWell(
      //     onTap: () {
      //       Get.back();
      //     },
      //     child: Icon(
      //       CupertinoIcons.back,
      //       size: 35,
      //       color: Colors.black,
      //     ),
      //   ),
      //   // border: Border(bottom: BorderSide(color: Colors.transparent)),
      //   backgroundColor: Colors.white,
      //   middle: InkWell(
      //     onTap: () {
      //       showCupertinoModalPopup(
      //         context: context,
      //         builder: (BuildContext context) => CupertinoActionSheet(
      //             title: Text('What would you like to see?'),
      //             actions: [
      //               CupertinoActionSheetAction(
      //                 child: Row(
      //                   mainAxisAlignment: MainAxisAlignment.center,
      //                   children: [
      //                     Padding(
      //                       padding: const EdgeInsets.only(right: 8.0),
      //                       child: const Text('Upcoming For You',
      //                           style: TextStyle(fontSize: 16)),
      //                     ),
      //                     if (show != "mine")
      //                       Icon(
      //                         Icons.check,
      //                         color: Colors.blue,
      //                       )
      //                   ],
      //                 ),
      //                 onPressed: () {
      //                   Navigator.pop(context);
      //                   setState(() {
      //                     show = "";
      //                   });
      //                 },
      //                 isDefaultAction: true,
      //               ),
      //               CupertinoActionSheetAction(
      //                 child: Row(
      //                   mainAxisAlignment: MainAxisAlignment.center,
      //                   children: [
      //                     Padding(
      //                       padding: const EdgeInsets.only(right: 8.0),
      //                       child: const Text('My Events',
      //                           style: TextStyle(fontSize: 16)),
      //                     ),
      //                     if (show == "mine")
      //                       Icon(
      //                         Icons.check,
      //                         color: Colors.blue,
      //                       )
      //                   ],
      //                 ),
      //                 onPressed: () {
      //                   setState(() {
      //                     show = "mine";
      //                   });
      //                   Navigator.pop(context);
      //                 },
      //               ),
      //             ],
      //             cancelButton: CupertinoActionSheetAction(
      //               child: Text(
      //                 'Cancel',
      //               ),
      //               onPressed: () {
      //                 Navigator.pop(context);
      //               },
      //             )),
      //       );
      //     },
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         Text(
      //           show == "mine" ? "MY EVENTS" : "UPCOMING FOR YOU",
      //           style: TextStyle(fontSize: 17),
      //         ),
      //         Icon(
      //           Icons.arrow_drop_down,
      //           size: 20,
      //         )
      //       ],
      //     ),
      //   ),
      //   trailing: IconButton(
      //     padding: EdgeInsets.zero,
      //     icon: Icon(
      //       CupertinoIcons.calendar_badge_plus,
      //       size: 35,
      //       color: Colors.black,
      //     ),
      //     onPressed: () {
      //       createUpcomingRoomSheet(context, false);
      //     },
      //   ),
      // ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: Database.getEvents(show),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  // Handling errors from firebase
                  if (snapshot.connectionState == ConnectionState.waiting)
                    Center(child: CircularProgressIndicator());
                  if (snapshot.hasError) {
                    print(snapshot.error);
                    return Text('Error: ${snapshot.error}');
                  }
                  // if(snapshot.connectionState == ConnectionState.done){
                  if (snapshot.data != null && snapshot.data.docs.length == 0) {
                    return Container(
                        margin: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                            child: Text(
                          "No Rooms yet",
                          style: TextStyle(fontSize: 21),
                        )));
                  }
                  // }
                  return snapshot.hasData
                      ? ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: snapshot.data.docs
                              .map((DocumentSnapshot document) {
                            return UpcomingRoomCard(
                              room: UpcomingRoom.fromJson(document),
                            );
                          }).toList(),
                        )
                      : Center(
                          child: CircularProgressIndicator(),
                        );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
