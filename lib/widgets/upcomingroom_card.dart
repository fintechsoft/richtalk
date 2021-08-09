import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roomies/util/utils.dart';
import 'package:roomies/widgets/widgets.dart';

class UpcomingRoomCard extends StatefulWidget {
  final UpcomingRoom room;

  const UpcomingRoomCard({
    Key key,
    @required this.room,
  }) : super(key: key);

  @override
  _UpcomingRoomCardState createState() => _UpcomingRoomCardState();
}

class _UpcomingRoomCardState extends State<UpcomingRoomCard> {
  bool  loading = false ;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        upcomingroomBottomSheet(context, widget.room,loading, false);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.room.timedisplay,
                  style: TextStyle(
                      fontSize: 12,
                      color:Colors.grey,
                      fontFamily: "InterBold"
                  ),
                ),
                GestureDetector(
                  child: Icon(CupertinoIcons.bell, size: 35,color: widget.room.users.indexWhere((element) => element.uid == Get.find<UserController>().user.uid) != -1 ? Colors.red : Colors.black,),
                  onTap: () async{
                    if(widget.room.users.indexWhere((element) => element.uid == Get.find<UserController>().user.uid) == -1){
                      await Database().addUsertoUpcomingRoom(widget.room);
                    }

                  },
                )
              ],
            ),
            Text(
                widget.room.title.toUpperCase(),
                style: TextStyle(
                    fontSize: 16.0, fontFamily: "InterBold")

            ),
            widget.room.clubname.isNotEmpty ? Row(
              children: [
                Text(
                  "From "+widget.room.clubname,
                  style: TextStyle(
                      color: Style.AccentGrey,
                      fontSize: 12,
                      fontFamily: "InterBold"
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Icon(
                  Icons.home,
                  color: Style.AccentGreen,
                  size: 18,
                )
              ],
            ) : Container(),
            SizedBox(height: 5,),
            widget.room.users.length==0 ? Container() : Container(
              height: 43,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.room.users.map((e) => GestureDetector(
                  onTap: () async{
                    // await usersRef.doc(widget.room.userid).get().then((value) {
                    //
                    //   Get.to(() => UserProfileView(user: UserModel.fromJson(value)));
                    // });

                  },
                  child: Container(
                    height: 40,
                    width: 43,
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          e.imageurl,
                        ),
                        fit: BoxFit.cover,
                      ),

                    ),

                  ),
                )).toList(),
              ),
            ),
            SizedBox(height: 5,),
            Container(
              height: MediaQuery.of(context).size.height / 30,
              child: Wrap(
                children: [
                  Text("W/",style: TextStyle(fontStyle: FontStyle.italic),),
                  ...widget.room.users.map((e) => Text("${e.firstname} ${e.lastname}, ",style: TextStyle(fontStyle: FontStyle.italic),)).toList(),

                ],
              ),
            ),Text(widget.room.description,
              style: TextStyle(
                  fontSize: 14,
                  fontFamily: "InterLight"
              ),
            )

          ],
        ),
      ),
    );
  }
}