import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/*
    interests pick screen
 */
//ignore: must_be_immutable

class InterestsPick extends StatefulWidget {
  final String title;
  final String subtitle;
  final Club club;
  final Function selectedItemsCallback;
  InterestsPick({this.title,this.subtitle,this.selectedItemsCallback,this.club});

  @override
  _InterestsPickState createState() => _InterestsPickState();
}

class _InterestsPickState extends State<InterestsPick> {
  bool isCallApi = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if(widget.club !=null){
      selectedItemList = widget.club.topics;
    }
    getFirebaseData();
  }

  QuerySnapshot tempList;
  List<Interest> selectedItemList = [];

  @override
  Widget build(BuildContext context) {
    // loading = false;
    return loading ? Center(
      child: CircularProgressIndicator(),
    ) : Scaffold(
        backgroundColor: Style.LightBrown,
        resizeToAvoidBottomInset: false, // set
        body: Container(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: isCallApi
              ? Center(child: CircularProgressIndicator())
              : ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Stack(
                  children: [

                    IconButton(
                      onPressed: ()=>Get.back(),
                      icon: Icon(Icons.arrow_back_ios),
                    ),

                    Center(
                      child: Text(
                        widget.title !=null ? widget.title : 'Interests',
                        style:
                        TextStyle(
                            fontFamily: "InterExtraBold", fontSize: 25
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Center(
                  child: Text(widget.subtitle !=null ? widget.subtitle : 'Add your interests so we can begin to personalize Roomy for you. Interests are private to you.',
                      style: TextStyle(
                          fontFamily: "InterLight",
                          fontSize: 16,
                          color: Color(0XFF7B7B7B)
                      ),
                    textAlign: TextAlign.center,

                  ),
                ),
              ),
              SizedBox(height: 20),
              ListView.builder(
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: tempList.docs.length,
                  itemBuilder: (BuildContext context, int i) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tempList.docs[i].id}',
                            style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black,
                                fontFamily: "InterSemiBold"
                            )
                        ),
                        SizedBox(height: 10),

                        funListViewData(
                            list: tempList.docs[i]['data'],
                            categoryName:
                            tempList.docs[i].id.toString()
                        ),
                        SizedBox(height: 20),
                      ],
                    );
                  }),
            ],
          ),
        ),

    );
  }

  /*
    single interest widget
   */
  List<Widget> listMyWidgets(List<dynamic> docs) {
    List<Widget> list = [];

    for(var itemm in docs){
      Interest item = Interest.fromJson2(itemm, docs.indexOf(itemm).toString());
      list.add( GestureDetector(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical:7),
          margin: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Text(
            item.title,
            style: TextStyle(
                fontSize: 15, fontFamily: "InterRegular",
                color: getColor(item.title) ? Colors.white : Colors.black
            ),
          ),
          decoration: BoxDecoration(
            color: getColor(item.title) ? Colors.red : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                // color: ccc.getactiveBgColor.value,
                // blurRadius: 4,
              ),
            ],
          ),
        ),
        onTap: () {
          if(widget.club !=null){
            updateClubTopics(item);
          }else{
            updateUserInterests(item);
          }
          setState(() {

          });

        },
      ));
    }
    return list;
  }

  void updateUserInterests(Interest item) {
    bool isAddData = true;
    for (var i = 0; i < selectedItemList.length; i++) {
      if (selectedItemList[i].title == item.title) {
        isAddData = false;
        selectedItemList.removeAt(i);
        usersRef.doc(Get.find<UserController>().user.uid).update({
          "interests" : FieldValue.arrayRemove([item.title])
        });

        break;
      } else {
        isAddData = true;
      }
    }
    if (isAddData) {
      selectedItemList.add(Interest(title: item.title));
      widget.selectedItemsCallback(selectedItemList);
      usersRef.doc(Get.find<UserController>().user.uid).update({
        "interests" : FieldValue.arrayUnion([item.title])
      });
    }
  }

  void updateClubTopics(Interest item) {
    if(selectedItemList.length ==3 && selectedItemList.indexWhere((element) => element.title == item.title) < 0){
      var alert = new CupertinoAlertDialog(
        title: new Text(''),
        content: new Text(
            'A club can only have 3 topics maximum'),
        actions: <Widget>[
          new CupertinoDialogAction(
              child: const Text('Okay'),
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
              }),
        ],
      );
      showDialog(
          context: context,
          builder: (context) {
            return alert;
          });

    }else{
      bool isAddData = true;
      for (var i = 0; i < selectedItemList.length; i++) {
        if (selectedItemList[i].title == item.title) {
          isAddData = false;
          selectedItemList.removeAt(i);
          print(item.toMap());
          if(widget.club.id !=null){

            Database.updateClub(widget.club.id, {
              "topics" : FieldValue.arrayRemove([item.toMap()])
            });
          }else{

            widget.selectedItemsCallback(selectedItemList);
          }

          break;
        } else {
          isAddData = true;
        }
      }
      if (isAddData) {
        selectedItemList.add(Interest(title: item.title, id: item.id));

        if(widget.club.id !=null) {
          Database.updateClub(widget.club.id, {
            "topics": FieldValue.arrayUnion([item.toMap()])
          });
        }else{
          widget.selectedItemsCallback(selectedItemList);
        }
      }
    }
  }

// ==========   Use for show data in gridview based on category     ================

  Widget funListViewData({List list, String categoryName}) {

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 650,
        child: Wrap(
          direction: Axis.horizontal,
          children: listMyWidgets(list),
        ),
      ),
    );

  }


// ==========   Use for get data from firebase     ================

  getFirebaseData() async {
    isCallApi = true;
    setState(() {});
    tempList = await interestsRef.get();
    isCallApi = false;
    setState(() {});
  }

  /*
      assign intersts link color
   */
  bool getColor(String itemName) {
    bool val = false;
    if(widget.club !=null){

      for (var i = 0; i < selectedItemList.length; i++) {
        if (selectedItemList[i].title == itemName || selectedItemList.indexWhere((element) => element.title == itemName) > 0) {
          val = true;
          break;
        } else {
          val = false;
        }
      }
    }else{
      for (var i = 0; i < selectedItemList.length; i++) {
        if (selectedItemList[i].title == itemName || Get.find<UserController>().user.interests.contains(itemName)) {
          val = true;
          break;
        } else {
          val = false;
        }
      }
    }
    return val;
  }
}