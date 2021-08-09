import 'package:roomies/models/room.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roomies/widgets/widgets.dart';

class RoomCard extends StatelessWidget {
  final Room room;

  const RoomCard({Key key, this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              offset: Offset(0, 1),
            )
          ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: roomTitle(room),
              ),
              if (room.roomtype == "Closed")
                IconButton(
                    onPressed: () {}, iconSize: 20, icon: Icon(Icons.lock)),
              if (room.roomtype == "Social")
                IconButton(
                    onPressed: () {}, iconSize: 20, icon: Icon(CupertinoIcons.circle_grid_hex_fill)),
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Row(
            children: [
               if(room.users.length > 0) buildProfileImages(),
              SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildUserList(),
                  SizedBox(
                    height: 5,
                  ),
                  buildRoomInfo(),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget buildProfileImages() {
    return Stack(
      children: [
        room.users.length > 1 ? RoundImage(
          margin: const EdgeInsets.only(top: 15, left: 25),
          url: room.users[1].imageurl,
        ) : Container(),
        RoundImage(
          url:room.users[0].imageurl,
        ),
      ],
    );
  }

  Widget buildUserList() {
    var len = room.users.length > 4 ? 4 : room.users.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < len; i++)
          Container(
            child: Row(
              children: [
                Text(
                  room.users[i].username,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Icon(
                  CupertinoIcons.chat_bubble_text,
                  color: Colors.grey,
                  size: 14,
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget buildRoomInfo() {
    return Row(
      children: [
        Text(
          '${room.users.length}',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        Icon(
          Icons.supervisor_account,
          color: Colors.grey,
          size: 14,
        ),
        Text(
          '  /  ',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
        Text(
          '${room.speakerCount}',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        Icon(
          CupertinoIcons.chat_bubble_text,
          color: Colors.grey,
          size: 14,
        ),
      ],
    );
  }
}
