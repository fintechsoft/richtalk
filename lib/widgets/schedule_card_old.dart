import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/services/database.dart';
import 'package:richtalk/util/style.dart';
import 'package:flutter/material.dart';

class ScheduleCardOld extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: Database.getEvents("", 4),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
              vertical: 5
            ),
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
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
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: buildScheduleItem(room),
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

  Widget buildScheduleItem(UpcomingRoom room) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 75,
          child: Text(
            room.timedisplay,
            style: TextStyle(
              color: Style.DarkBrown,
              fontSize: 11
            ),
          ),
        ),
        SizedBox(
          width: 5,
        ),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              room.clubname.isNotEmpty ? Row(
                children: [
                  Text(
                    room.clubname,
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
                    color: Style.pinkAccent,
                    size: 10,
                  )
                ],
              ) : Container(),
              Text(
                room.title,
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