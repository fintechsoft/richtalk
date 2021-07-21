import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
List<UserModel> selectedusers = [];
class AddCoHostScreen extends StatefulWidget {
  final Function clickCallback;
  final StateSetter mystate;
  AddCoHostScreen({this.clickCallback,this.mystate});

  @override
  _AddCoHostScreenState createState() => _AddCoHostScreenState();
}

class _AddCoHostScreenState extends State<AddCoHostScreen> {
  bool loading = false;
  var searchcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            height: 40,
          ),
          InkWell(
            child: Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.arrow_back_ios)),
            onTap: () {

              Get.back();
            },
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Style.themeColor),
                    child: TextField(
                        onChanged: (tx){
                          setState(() {

                          });
                        },
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.blueAccent,
                        ),
                        controller: searchcontroller,
                        decoration: InputDecoration(
                          contentPadding:
                              EdgeInsets.fromLTRB(8.0, 13.0, 8.0, 8.0),
                          prefixIcon: Icon(Icons.search),
                          hintText: "Search people to add as co-host",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        )),
                  ),
                  Expanded(
                    child: Container(
                        margin: EdgeInsets.symmetric(vertical: 30),
                        child: loading
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : StreamBuilder(
                                stream: Database.getUsersToFollow(-1),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    print(snapshot.error.toString());
                                    return Text("Technical Error");
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting)
                                    Center(child: CircularProgressIndicator());
                                  if (snapshot.data == null) {
                                    return Center(child: Text("No Users Yet "));
                                  }
                                  List<UserModel> users = snapshot.data;
                                  if (users.length == 0) {
                                    return Center(child: Text("No Users Yet "));
                                  }
                                  return GridView.builder(
                                    itemCount: users.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      if (searchcontroller.text.isEmpty) {
                                        return singleUser(users[index]);
                                      } else if (users[index]
                                          .firstname
                                          .toLowerCase()
                                          .contains(searchcontroller.text) || users[index]
                                          .lastname
                                          .toLowerCase()
                                          .contains(searchcontroller.text)) {
                                        return singleUser(users[index]);
                                      }
                                      return Container();
                                    },
                                  );
                                })),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  singleUser(UserModel user) {
    return Container(
      height: 60,
      child: InkWell(
        onTap: (){
          if(!selectedusers.contains(user)) widget.clickCallback(user);
          print(selectedusers.contains(user).toString());
          widget.mystate(() {

          });
          Get.back();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: CachedNetworkImage(
                    imageUrl: user.imageurl,
                    fit: BoxFit.cover,
                  ),
                ),
                selectedusers.contains(user) == true ? Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(30)
                    ),
                    child: Icon(Icons.check, size: 15,color: Colors.white,)
                ) : Container()
              ],
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.firstname + " " + user.lastname,
                    textScaleFactor: 1,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
