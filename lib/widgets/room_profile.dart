import 'package:roomies/models/models.dart';
import 'package:roomies/models/user_model.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:flutter/material.dart';

import 'widgets.dart';

class RoomProfile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                showUserProfile(context, user,room);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: bordercolor ?? Color(0xFFFFFFFF), width: 5),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(size / 2 - size / 18),
                      topRight: Radius.circular(size / 2 - size / 18),
                      bottomRight: Radius.circular(size / 2 - size / 18),
                      bottomLeft: Radius.circular(size / 2 - size / 18)),
                ),
                child: RoundImage(
                  url: user.imageurl,
                  txt: user.firstname,
                  width: size,
                  height: size,
                  txtsize: 21,
                  borderRadius: 30,
                ),
              ),
            ),
            buildNewBadge(user.isNewUser),
            buildMuteBadge(isMute),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildModeratorBadge(isModerator),
            Text(
              user.firstname,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
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
              color: Style.AccentGreen,
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

  Widget buildNewBadge(bool isNewUser) {
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
              child: Text(
                '🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            )
          : Container(),
    );
  }
}
