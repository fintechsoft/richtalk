import 'package:roomies/models/user_model.dart';
import 'package:roomies/pages/home/search_view.dart';
import 'package:roomies/pages/room/upcoming_roomsreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/pages/room/notifications.dart';
import 'package:roomies/widgets/user_profile_image.dart';
class HomeAppBar extends StatelessWidget {
  final UserModel profile;
  final Function onProfileTab;

  const HomeAppBar({Key key, this.profile, this.onProfileTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          child: IconButton(
            onPressed: () {
              Get.to(()=>SearchView());
            },
            iconSize: 30,
            icon: Icon(Icons.search),
          ),
        ),
        Spacer(),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              iconSize: 30,
              icon: Icon(CupertinoIcons.mail),
            ),
            SizedBox(
              width: 10,
            ),
            IconButton(
              onPressed: () {
                Get.to(() => UpcomingRoomScreen());
              },
              iconSize: 30,
              icon: Icon(CupertinoIcons.calendar_today,),
            ),
            SizedBox(
              width: 10,
            ),
            InkWell(
              onTap: (){
                Get.to(() => NotificationActivities());
              },
              child: Container(
                margin: EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 35,),
                    Positioned(
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.red
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            GestureDetector(
              onTap: onProfileTab,
              child: profile.imageurl == null ? Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                ),
                child:Text(profile.firstname.substring(0,2))
              ) :UserProfileImage(
                user: profile,
                borderRadius: 20,
                width: 40,
                height: 40,
              ),
            )
          ],
        ),
      ],
    );
  }
}
