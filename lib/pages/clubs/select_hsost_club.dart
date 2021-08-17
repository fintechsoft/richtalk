import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/utils.dart';
//ignore: must_be_immutable
class SelectHostClub extends StatefulWidget {
  Club selectedclub;
  Function setselectedclub;
  SelectHostClub({this.selectedclub,this.setselectedclub});
  @override
  _SelectHostClubState createState() => _SelectHostClubState();
}

class _SelectHostClubState extends State<SelectHostClub> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        margin: EdgeInsets.only(top: 30, left: 20, right: 20),
        child: Column(
          children: [
            Container(
              height: 80,
              child: CupertinoNavigationBar(
                backgroundColor: Style.LightBrown,
                padding: EdgeInsetsDirectional.only(top: 15, end: 10,bottom: 10),
                leading: GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: Icon(Icons.arrow_back_ios),
                ),
                border: Border(bottom: BorderSide(color: Colors.transparent)),
                middle: Text(
                  "HOST CLUB",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
            SizedBox(height: 20,),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text("No Host Club"),
                      trailing: widget.selectedclub ==null ? Icon(Icons.check, size: 30,color: Colors.green,) : null,
                      onTap: (){
                        widget.selectedclub = null;
                        widget.setselectedclub(null);
                        setState(() {

                        });
                      },
                    ),
                    Divider(),
                    StreamBuilder(
                        stream: Database.getMyClubs(Get.find<UserController>().user.uid),
                        builder: (context, snapshot) {
                          if(snapshot.hasError){
                            print(snapshot.error.toString());
                          }
                          if (snapshot.hasData) {
                            List<Club> club = snapshot.data;
                            return ListView(
                              shrinkWrap: true,
                              scrollDirection: Axis.vertical,
                              children: club.map((e) => Column(
                                children: [
                                  ListTile(
                                    title: Text(e.title, style: TextStyle(fontFamily: "InterSemiBold", fontSize: 16)),
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      margin: EdgeInsets.only(right: 5),
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Style.SelectedItemGrey),
                                      child: Center(
                                          child: Text(
                                            e.title.substring(0,2).toUpperCase(),
                                            style: TextStyle(fontFamily: "InterSemiBold"),
                                          )),
                                    ),
                                    trailing: widget.selectedclub !=null && widget.selectedclub.id == e.id ? Icon(Icons.check, size: 30,color: Colors.green,) : null,
                                    onTap: (){
                                      widget.selectedclub = e;
                                      widget.setselectedclub(e);
                                      setState(() {

                                      });
                                    },
                                  ),
                                  Divider()
                                ],
                              )).toList(),
                            );
                          }else{
                            return Container();
                          }
                        })
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
