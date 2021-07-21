import 'package:roomies/models/user_model.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:flutter/material.dart';

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
          child: RoundImage(
            url: user.imageurl,
            borderRadius: 15,
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
                '${user.bio}',
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
                    color: Style.AccentGreen,
                  ),
                ),
                Icon(
                  Icons.lock,
                  color: Style.AccentGreen,
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
