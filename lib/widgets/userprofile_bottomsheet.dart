import 'package:flutter/material.dart';

import '../models/models.dart';
import '../pages/home/profile_page.dart';

showUserProfile(BuildContext context, UserModel user,
    {Room room, bool short = false}) {
  showModalBottomSheet(
    isScrollControlled: !short,
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
      topLeft: Radius.circular(15),
      topRight: Radius.circular(15),
    )),
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * .9,
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return DraggableScrollableSheet(
              expand: false,
              initialChildSize:1,
              maxChildSize: 1,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  margin: EdgeInsets.only(top: 20),
                  child: ProfilePage(
                      profile: user,
                      fromRoom: true,
                      room: room,
                      short: short),
                );
              });
        }),
      );
    },
  );
}
