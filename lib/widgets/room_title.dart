

import 'package:flutter/material.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/util/utils.dart';

roomTitle([Room room]){
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      room !=null && room.clubname.isNotEmpty ? Row(
        children: [
          Text(
            room.clubname.toUpperCase(),
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "InterRegular"
            ),
          ),
          SizedBox(
            width: 5,
          ),
          Icon(
            Icons.home,
            color: Style.pinkAccent,
            size: 18,
          )
        ],
      ) : Container(),
       if(room !=null && room.title.isNotEmpty) Text(
        room.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    ],
  );
}