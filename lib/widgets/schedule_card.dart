import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
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
              ? Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Style.AccentBrown,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: snapshot.data.docs.map((DocumentSnapshot document) {
                    UpcomingRoom room = UpcomingRoom.fromJson(document);
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: buildScheduleItem(room.timedisplay, room.title),
                    );
                  }).toList(),
                )
              ],
            ),
          ): Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  Widget buildScheduleItem(String time, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 75,
          child: Text(
            time,
            style: TextStyle(
              color: Style.DarkBrown,
            ),
          ),
        ),
        SizedBox(
          width: 10,
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'COMMUNITY CLUB',
                    style: TextStyle(
                      color: Style.AccentGrey,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Icon(
                    Icons.home,
                    color: Style.AccentGreen,
                    size: 15,
                  )
                ],
              ),
              Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
