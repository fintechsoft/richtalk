import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/functions/functions.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/home/select_interests.dart';
import 'package:roomies/pages/room/followers_list.dart';
import 'package:roomies/pages/room/new_upcoming_room.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/utils.dart';
import 'package:roomies/widgets/widgets.dart';
//ignore: must_be_immutable
class ViewClub extends StatefulWidget {
  Club club;

  ViewClub({this.club});

  @override
  _ViewClubState createState() => _ViewClubState();
}

class _ViewClubState extends State<ViewClub> {
  bool keyboardup = false;
  int _index = 0;

  StreamSubscription<DocumentSnapshot> clubliten;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    clubliten = clubRef.doc(widget.club.id).snapshots().listen((event) {
      widget.club = Club.fromJson(event);
      setState(() {});
    });
  }


  @override
  void dispose() {
    clubliten.cancel();
    super.dispose();
  }

  handleClick(c) {
    switch (c) {
      case "topics":
        Get.to(() => InterestsPick(
            title: "Choose Topics",
            subtitle:
                "Choose up to 3 topics to help others find and understand your club",
            club: widget.club));
        break;
      case "allowfolloers":
        Database.updateClub(
            widget.club.id, {"allowfollowers": !widget.club.allowfollowers});
        break;
      case "start":
        Database.updateClub(widget.club.id,
            {"membercanstartrooms": !widget.club.membercanstartrooms});
        break;
      case "hide":
        Database.updateClub(
            widget.club.id, {"membersprivate": !widget.club.membersprivate});
        break;
      case "description":
        addBio();
        break;
      case "leave":
        usersRef.doc(widget.club.ownerid).update({
          "clubs" : FieldValue.arrayRemove([widget.club.id])
        });
        clubRef.doc(widget.club.id).delete();
        Get.back();
        break;
    }
  }

  List<List<String>> options = [
    ["topics", "Edit Club Topics"],
    ["allowfolloers", "Don't Allow Followers"],
    ["start", "Let Members Start Rooms"],
    ["hide", "Hide Members List"],
    ["description", "Edit Description"],
    ["leave", "Leave Club"],
  ];

  Widget _indicator(bool isActive) {
    return Container(
      height: 10,
      child: AnimatedContainer(

        duration: Duration(milliseconds: 150),
        margin: EdgeInsets.symmetric(horizontal: 4.0),
        height: isActive
            ? 10:8.0,
        width: isActive
            ? 12:8.0,
        decoration: BoxDecoration(
          boxShadow: [
            isActive
                ? BoxShadow(
              color: Color(0XFF2FB7B2).withOpacity(0.72),
              blurRadius: 4.0,
              spreadRadius: 1.0,
              offset: Offset(
                0.0,
                0.0,
              ),
            )
                : BoxShadow(
              color: Colors.transparent,
            )
          ],
          shape: BoxShape.circle,
          color: isActive ? Colors.blueGrey : Colors.grey,
        ),
      ),
    );
  }
  List<Widget> _buildPageIndicator(List<UpcomingRoom> rooms) {
    List<Widget> list = [];
    for (int i = 0; i < rooms.length; i++) {
      list.add(i == _index ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.justadded == true) {

    // }
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: Icon(
            Icons.arrow_back_ios,
            size: 25,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.share,
              size: 30,
            ),
          ],
        ),
        actions: widget.club.ownerid != Get.find<UserController>().user.uid ? null : <Widget>[
          PopupMenuButton<String>(
            onSelected: handleClick,
            itemBuilder: (BuildContext context) {
              return options.map((List choice) {
                return PopupMenuItem<String>(
                  value: choice[0],
                  child: Text(choice[1]),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  children: [
                    widget.club.imageurl.isNotEmpty ? RoundImage(
                      url: widget.club.imageurl,
                      width: 120,
                      height: 120,
                      txt: widget.club.title,
                    ) :Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Style.SelectedItemGrey),
                        child: Center(
                            child: Text(
                          widget.club.title.toUpperCase().substring(0, 2),
                          style: TextStyle(fontSize: 20),
                        )),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            widget.club.title.toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Icon(
                          Icons.home,
                          color: Style.AccentGreen,
                          size: 25,
                        )
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      child: Text(
                        "${widget.club.members.length} member${widget.club.members.length > 1 ? "s" : ""}",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (widget.club.ownerid == Get.find<UserController>().user.uid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          InkWell(
                            onTap: () {
                              Get.to(() => NewUpcomingRoom(club: widget.club));
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 30),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Style.indigo),
                              child: Text(
                                "Schedule a Room",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontFamily: "InterSemiBold"),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Get.to(() => FollowersList(club: widget.club));
                            },
                            child: Container(
                              margin: EdgeInsets.only(top: 30),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.white),
                              child: Text(
                                "Add Members",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Style.indigo,
                                    fontFamily: "InterSemiBold"),
                              ),
                            ),
                          )
                        ],
                      ),
                    if (widget.club.ownerid != Get.find<UserController>().user.uid)
                      Container(
                        margin: EdgeInsets.only(top: 30),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Style.indigo),
                        child: Text(
                          "${widget.club.members.contains(Get.find<UserController>().user.uid) ? "Member" : "Follow"}",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontFamily: "InterSemiBold"),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: 30,
                ),
                Text(
                  "Up next",
                  style: TextStyle(color: Style.AccentGrey),
                ),
                SizedBox(
                  height: 5,
                ),
                Divider(
                  thickness: 1,
                ),
                Flexible(
                  child: StreamBuilder(
                      stream: Database.getClubUpcomingRooms(widget.club),
                      builder: (context, snapshot) {
                        print(snapshot.error.toString());
                        if (snapshot.hasData &&
                            snapshot.data != null &&
                            snapshot.data.length > 0) {
                          List<UpcomingRoom> rooms = snapshot.data;
                          return Column(
                            children: [
                              Expanded (
                                child: PageView.builder(
                                    itemCount: rooms.length,
                                    onPageChanged: (int index) =>
                                        setState(() => _index = index),
                                    itemBuilder: (_, i) {
                                      UpcomingRoom room = rooms[_index];

                                      return Transform.scale(
                                        scale: i == _index ? 1 : 0.9,
                                        child: InkWell(
                                            onTap: () {
                                              upcomingroomBottomSheet(
                                                  context, room, false, false);
                                            },
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  child: Text(
                                                    (room.publisheddate !=null ? Functions.timeFutureSinceDate(
                                                            room.publisheddate) : "") +
                                                        " " +
                                                        room.timedisplay,
                                                    style: TextStyle(
                                                      color: Style.DarkBrown,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  room.title,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 20,
                                                      fontFamily: "InterSemiBold"),
                                                ),
                                                Column(
                                                  children: [
                                                    room.users.length == 0
                                                        ? Container()
                                                        : Container(
                                                            height: 43,
                                                            margin: EdgeInsets.only(top: 8),
                                                            child: ListView(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              children: room.users
                                                                  .map((e) => Container(
                                                                    height: 43,
                                                                    width: 43,
                                                                    margin:
                                                                        EdgeInsets.only(
                                                                            right: 10),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                                  18),
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            CachedNetworkImageProvider(
                                                                          e.imageurl,
                                                                        ),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  ))
                                                                  .toList(),
                                                            ),
                                                          ),
                                                    room.users.length == 0
                                                        ? Container()
                                                        : Container(
                                                            child: Wrap(
                                                              children: room.users
                                                                  .map((e) => Text(
                                                                        e.firstname +
                                                                            " " +
                                                                            e.lastname+", ",
                                                                        style: TextStyle(
                                                                            fontStyle:
                                                                                FontStyle
                                                                                    .italic),
                                                                      ))
                                                                  .toList(),
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              ],
                                            )),
                                      );
                                    }),
                              ),
                              Wrap(
                                children: _buildPageIndicator(rooms).toList(),
                              )
                            ],
                          );
                        } else {
                          return DottedBorder(
                              color: Colors.black,
                              strokeWidth: 1,
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 130,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.calendar_badge_minus,
                                      size: 28,
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "This club has no scheduled rooms",
                                      style: TextStyle(
                                          fontSize: 17, color: Style.AccentGrey),
                                    )
                                  ],
                                ),
                              ),
                              borderType: BorderType.RRect,
                              radius: Radius.circular(20),
                              dashPattern: [6, 3, 2, 3]);
                        }
                      }),
                ),

                SizedBox(
                  height: 10,
                ),
                Container(
                  height: widget.club.topics.length > 0 ? 20 : 0,
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: widget.club.topics
                        .map((e) => Center(
                          child: Container(
                                padding: EdgeInsets.only(right: 5),
                                child: Text(
                                  e.title+",",
                                  style: TextStyle(fontFamily: "InterSemiBold"),
                                ),
                              ),
                        ))
                        .toList(),
                  ),
                ),
                if(widget.club.description.isNotEmpty) Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      "About",
                      style: TextStyle(color: Style.AccentGrey),
                    ),
                    Divider(
                      thickness: 1,
                    ),
                    Container(
                      child: Text(widget.club.description),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  "${widget.club.members.length} Members",
                  style: TextStyle(color: Style.AccentGrey),
                ),
                SizedBox(
                  height: 5,
                ),
                Divider(
                  thickness: 1,
                ),
                SizedBox(
                  height: 10,
                ),
                if(widget.club.members.length < 20) Expanded(
                  child: StreamBuilder<List<UserModel>>(
                      stream: Database.getusersInaClub(widget.club),
                      builder: (BuildContext context, snapshot) {
                        if (snapshot.hasData) {
                          List<UserModel> users = snapshot.data;
                          return ListView.separated(
                            separatorBuilder: (c, i) {
                              return Container(
                                height: 15,
                              );
                            },
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              return singleItem(users[index]);
                            },
                          );
                        } else {
                          return Container();
                        }
                      }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget singleItem(UserModel user) {
    return Container(
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            clipBehavior: Clip.hardEdge,
            child: CachedNetworkImage(
              imageUrl: user.imageurl,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.getName(),
                  textScaleFactor: 1,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.bio,
                  textScaleFactor: 1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 16,
          ),
          if(Get.find<UserController>().user != null &&
              !Get.find<UserController>()
                  .user
                  .following
                  .contains(user.uid)) TextButton(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all(Colors.transparent),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Style.indigo,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                Get.find<UserController>().user != null &&
                        Get.find<UserController>()
                            .user
                            .following
                            .contains(user.uid)
                    ? "Following"
                    : "Follow",
                textScaleFactor: 1,
                style: TextStyle(
                  color: Style.indigo,
                ),
              ),
            ),
            onPressed: () {
              if (Get.find<UserController>()
                  .user
                  .following
                  .contains(user.uid)) {
                print("unfollow " + user.uid);
                Database().unFolloUser(user.uid);
              } else {
                print("follow " + user.uid);
                Database().folloUser(user);
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  addBio() {
    var biocontroller = TextEditingController();

    biocontroller.text = widget.club.description;

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Style.AccentBrown,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      )),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return DraggableScrollableSheet(
              initialChildSize: 0.9,
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Update description for ${widget.club.title}",
                        style: TextStyle(fontSize: 21),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        decoration: new BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        height: 200,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: biocontroller,
                          maxLength: null,
                          maxLines: 20,
                          decoration: InputDecoration(
                              hintStyle: TextStyle(
                                fontSize: 20,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              fillColor: Colors.white),
                          keyboardType: TextInputType.text,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      CustomButton(
                        text: "Done",
                        color: Style.AccentBlue,
                        onPressed: () {
                          Navigator.pop(context);
                          Database.updateClub(widget.club.id,
                              {"description": biocontroller.text});
                        },
                      )
                    ],
                  ),
                );
              });
        });
      },
    );
  }
}
