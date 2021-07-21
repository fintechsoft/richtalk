
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../pages/home/profile_page.dart';

showUserProfile(BuildContext context, UserModel user, [Room room]) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,

    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        )),
    builder: (context) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
                initialChildSize: 0.8,
                expand: false,
                builder: (BuildContext context, ScrollController scrollController) {
                  return Container(
                    margin: EdgeInsets.only(top: 20),
                    child: ProfilePage(profile: user, fromRoom: true, room: room),
                  );
                });
          });
    },
  );
}