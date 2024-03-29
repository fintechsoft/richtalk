import 'package:richtalk/models/room.dart';
import 'package:richtalk/util/style.dart';
import 'package:richtalk/widgets/round_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:richtalk/widgets/widgets.dart';
import 'package:intl/intl.dart';
class RoomCard extends StatelessWidget {
  final Room room;

  const RoomCard({Key key, this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var date = DateTime.fromMillisecondsSinceEpoch(room.createdtime);
    var formattedDate = DateFormat.jm().format(date);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
          color: Color(0xfff4adcf),
          borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(formattedDate,style:TextStyle(fontWeight: FontWeight.bold),),
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
            height: 5,
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
          txt: room.users[1].firstname,
          url: room.users[1].imageurl,
          txtsize: 14,
        ) : Container(),
        RoundImage(
          url:room.users[0].imageurl,
          txt: room.users[0].firstname,
          txtsize: 14,
        ),
      ],
    );
  }

  Widget buildUserList() {
    var len = room.users.length > 4 ? 4 : room.users.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < len; i++)
          Row(
            children: [
              Text(
                room.users[i].getName() !=null ? room.users[i].getName() : "",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
              SizedBox(
                width: 5,
              ),
              Icon(
                CupertinoIcons.chat_bubble_text,
                color: Colors.black,
                size: 14,
              ),
            ],
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
            color: Colors.black,
          ),
        ),
        Icon(
          Icons.supervisor_account,
          color: Colors.black,
          size: 14,
        ),
        Text(
          '  /  ',
          style: TextStyle(
            color: Colors.black,
            fontSize: 10,
          ),
        ),
        Text(
          '${room.speakerCount}',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        Icon(
          CupertinoIcons.chat_bubble_text,
          color: Colors.black,
          size: 14,
        ),
      ],
    );
  }
}
