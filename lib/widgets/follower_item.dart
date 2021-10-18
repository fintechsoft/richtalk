import 'package:richtalk/models/user_model.dart';
import 'package:richtalk/util/style.dart';
import 'package:richtalk/widgets/round_button.dart';
import 'package:richtalk/widgets/round_image.dart';
import 'package:flutter/material.dart';
import 'package:richtalk/functions/functions.dart';
import 'package:intl/intl.dart';

class FollowerItem extends StatelessWidget {
  final UserModel user;
  final Function onProfileTap;
  final Function onRoomButtonTap;

  const FollowerItem(
      {Key key, this.user, this.onProfileTap, this.onRoomButtonTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: Stack(
            children: [
              RoundImage(
                url: user.imageurl,
                txt: user.firstname,
                txtsize: 12,
                borderRadius: 15,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 13,
                  width: 13,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: user.online == true ? Style.pinkAccent : Colors.green[100],
                      border: Border.all(width: 1,color: Colors.white)
                  ),
                ),
              )
            ],
          ),
        ),
        SizedBox(
          width: 8,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.getName(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                Functions.timeAgoSinceDate(DateFormat("dd-MM-yyyy h:mma").format(DateTime.fromMicrosecondsSinceEpoch(user.lastAccessTime))),
                style: TextStyle(
                  color: Style.DarkBrown,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 25,
          child: CustomButton(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            onPressed: onRoomButtonTap,
            color: Style.LightGreen,
            child: Row(
              children: [
                Text(
                  '+ Room',
                  style: TextStyle(
                    color: Style.pinkAccent,
                  ),
                ),
                Icon(
                  Icons.lock,
                  color: Style.pinkAccent,
                  size: 15,
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
