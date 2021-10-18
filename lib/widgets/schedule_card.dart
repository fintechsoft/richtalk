import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/services/database.dart';
import 'package:richtalk/util/style.dart';
import 'package:flutter/material.dart';
import 'package:richtalk/widgets/widgets.dart';

class ScheduleCard extends StatefulWidget {
  @override
  _ScheduleCardState createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: Database.getEvents("", 4),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Handling errors from firebase
          // if (snapshot.connectionState == ConnectionState.waiting)
          //   Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            print(snapshot.error);
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.data != null && snapshot.data.docs.length == 0) {
            return Container();
          }
          return snapshot.hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        margin: EdgeInsets.symmetric(horizontal: 30),
                        child: Text("Upcoming Events".toUpperCase(),
                            style: TextStyle(color: Style.AccentGrey))),
                    SizedBox(height: 10,),
                    SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: PageView.builder(
                          itemCount: snapshot.data.docs.length,
                          controller: PageController(viewportFraction: 0.8),
                          onPageChanged: (int index) =>
                              setState(() => _index = index),
                          itemBuilder: (_, i) {
                            UpcomingRoom room = UpcomingRoom.fromJson(
                                snapshot.data.docs[_index]);

                            return Transform.scale(
                              scale: i == _index ? 1 : 0.9,
                              child: InkWell(
                                onTap: (){
                                  upcomingroomBottomSheet(context, room,false, false);
                                },
                                child: Card(
                                  color: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 10),
                                    child: buildScheduleItem(room),
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
                  ],
                )
              : Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

}
