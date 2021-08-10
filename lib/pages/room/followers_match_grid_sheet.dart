import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/widgets.dart';

class FollowerMatchGridPage extends StatefulWidget {
  final Function callback;
  final String title;
  final bool fromroom;
  final StateSetter state;
  final StateSetter customState;
  final Room room;
  FollowerMatchGridPage({this.customState,this.state,this.callback, this.title,this.fromroom, this.room});
  @override
  _FollowerMatchGridPageState createState() => _FollowerMatchGridPageState();
}

class _FollowerMatchGridPageState extends State<FollowerMatchGridPage> {
  UserModel myProfile = Get.find<UserController>().user;
  bool loading = false;
  final globalScaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController textController = new TextEditingController();
  List<UserModel> allusers = [];
  List<UserModel> roomallusers = [];
  List<UserModel> pinggedusers = [];

  userclickCallBack(UserModel user) {

    if(roomallusers.indexWhere((element) => element.uid == user.uid) ==-1){
      roomallusers.add(user);
    } else if(roomallusers.indexWhere((element) => element.uid == user.uid) !=-1){
      roomallusers.removeAt(roomallusers.indexWhere((element) => element.uid == user.uid));
    }
    if(widget.fromroom == true){
      widget.callback(user,widget.room,widget.customState);
    }else{
      widget.callback(roomallusers,widget.room,widget.state);
    }
    widget.customState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return buildAvailableChatList(context);
  }

  Widget buildAvailableChatTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'AVAILABLE TO CHAT',
          style: TextStyle(
            color: Style.DarkBrown,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Style.DarkBrown,
          ),
        ),
      ],
    );
  }

  List<UserModel> _buildSearchList(String userSearchTerm) {
    List<UserModel> _searchList = [];

    if (userSearchTerm.isEmpty) {
      return allusers;
    }
    for (int i = 0; i < allusers.length; i++) {
      String name = allusers[i].getName();
      if (name.toLowerCase().contains(userSearchTerm.toLowerCase())) {
        _searchList.add(allusers[i]);
      }
    }
    return _searchList;
  }

  Widget buildAvailableChatList(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "DONE",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                  ))
            ],
          ),
        ),
        Container(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Style.followColor,
              borderRadius: BorderRadius.circular(8)
            ),
            child: TextFormField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: "Search",
                  prefixIcon: Icon(Icons.search),
                  focusedBorder: InputBorder.none,
                  border: InputBorder.none
                ),
                onChanged: (value) {
                  setState(() {
                  });
                })),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: StreamBuilder(
                stream: Database.getmyFollowers(),
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Center(child: noDataWidget("No users whom you follow each others"));
                  }
                  if (snapshot.data.length == 0) {
                    return Center(child: Text("No users who you follow each others"));
                  }
                  allusers = snapshot.data;
                  return GridView.builder(
                    itemCount: _buildSearchList(textController.text).length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3),
                    itemBuilder: (BuildContext context, int index) {
                      print(roomallusers.indexWhere((element) => element.uid == _buildSearchList(textController.text)[index].uid));
                      return userWidgetWithInfo(
                          user: _buildSearchList(textController.text)[index],
                          selected: roomallusers.indexWhere((element) => element.uid == _buildSearchList(textController.text)[index].uid) !=-1 ? true : false,
                          clickCallBack: userclickCallBack);
                      // }
                    },
                  );
                }),
          ),
        ),
      ],
    );
  }
}
