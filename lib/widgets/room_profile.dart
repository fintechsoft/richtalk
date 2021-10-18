import 'package:richtalk/models/models.dart';
import 'package:richtalk/models/user_model.dart';
import 'package:richtalk/util/style.dart';
import 'package:richtalk/widgets/round_image.dart';
import 'package:flutter/material.dart';

import 'widgets.dart';

class RoomProfile extends StatefulWidget {
  final UserModel user;
  final Room room;
  final double size;
  final bool isMute;
  final bool isModerator;
  final Color bordercolor;

  const RoomProfile(
      {Key key,
      this.user,
      this.room,
      this.size,
      this.isMute = false,
      this.bordercolor = const Color(0xFFFFFFFF),
      this.isModerator = false})
      : super(key: key);

  @override
  _RoomProfileState createState() => _RoomProfileState();
}

class _RoomProfileState extends State<RoomProfile> {
  bool short = true;
   listener(shor, set){
    short = !shor;
    set(() {

    });
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                showUserProfile(context, widget.user,room: widget.room,short: short);
                // showShortUserProfile(context, user,room);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: widget.bordercolor ?? Color(0xFFFFFFFF), width: 5),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(widget.size / 2 - widget.size / 18),
                      topRight: Radius.circular(widget.size / 2 - widget.size / 18),
                      bottomRight: Radius.circular(widget.size / 2 - widget.size / 18),
                      bottomLeft: Radius.circular(widget.size / 2 - widget.size / 18)),
                ),
                child: RoundImage(
                  url: widget.user.imageurl,
                  txt: widget.user.firstname,
                  width: widget.size,
                  height: widget.size,
                  txtsize: 21,
                  borderRadius: 30,
                ),
              ),
            ),
            //buildNewBadge(widget.user.isNewUser),
            buildNewLeader(widget.isModerator),
            buildMuteBadge(widget.isMute),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // buildModeratorBadge(widget.isModerator),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                children : [
                Text(
                  widget.user.firstname+" "+widget.user.lastname,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold
                  ),
                ),
                ]
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildModeratorBadge(bool isModerator) {
    return isModerator
        ? Container(
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              color: Style.pinkAccent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: 12,
            ),
          )
        : Container();
  }

  Widget buildMuteBadge(bool isMute) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: isMute
          ? Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    offset: Offset(0, 1),
                  )
                ],
              ),
              child: Icon(Icons.mic_off),
            )
          : Container(),
    );
  }
Widget buildNewLeader(bool isNewUser) {
  return Positioned(
    left: 0,
    bottom: 0,
    child: isNewUser
        ? Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  offset: Offset(0, 1),
                )
              ],
            ),
            child:
            Image.asset("assets/images/badge.png", width: 10,),
            // Text(
            //   '🎉',
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: 18,
            //   ),
            // ),
          )
        : Container(),
  );
}
  // Widget buildNewBadge(bool isNewUser) {
  //   return Positioned(
  //     left: 0,
  //     bottom: 0,
  //     child: isNewUser
  //         ? Container(
  //             width: 25,
  //             height: 25,
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(50),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.grey.withOpacity(0.5),
  //                   offset: Offset(0, 1),
  //                 )
  //               ],
  //             ),
  //             child: Text(
  //               '🎉',
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 fontSize: 18,
  //               ),
  //             ),
  //           )
  //         : Container(),
  //   );
  // }
}
