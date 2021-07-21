
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/room/add_co_host.dart';
import 'package:roomies/pages/room/upcoming_roomsreen.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/utils.dart';
import 'package:intl/intl.dart';
import 'package:roomies/widgets/widgets.dart';


List<UserModel> hosts = [Get.find<UserController>().user];
userClickCallBack(UserModel user) {
  if (!hosts.contains(user)) hosts.add(user);
}
void addCoHost(BuildContext context, StateSetter mystate) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        )),
    builder: (context) {
      return AddCoHostScreen(
          clickCallback: userClickCallBack, mystate: mystate);
    },
  ).whenComplete(() {
    print('Hey there, I\'m calling after hide bottomSheet');
  });
}

Future<Widget> createUpcomingRoomSheet(BuildContext context,bool keyboardup,
    [UpcomingRoom roomm]) async {
  if (roomm != null) {

    eventcontroller.text = roomm.title;
    descriptioncontroller.text = roomm.description;
    datedisplay = roomm.eventdate;
    timedisplay = roomm
        .timedisplay; // DateTime.fromMillisecondsSinceEpoch(roomm.eventtime).hour.toString()+":"+DateTime.fromMillisecondsSinceEpoch(roomm.eventtime).minute.toString();
    publish = true;
    timeseconds = roomm.eventtime;
  }

  return await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Style.LightGrey,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      ),
    ),
    builder: (context) {
      return StatefulBuilder(
          builder: (BuildContext context, StateSetter mystate) {
            return Container(
              color: Style.LightGrey,
              padding:
              const EdgeInsets.only(top: 10, right: 20, left: 20, bottom: 20),
              height: MediaQuery.of(context).size.height * 0.85,
              child: loading
                  ? Center(
                child: CircularProgressIndicator(),
              )
                  : SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style:
                              TextStyle(fontSize: 20, color: Colors.red),
                            ),
                          ),
                          Text(
                            "NEW EVENT",
                            style: TextStyle(fontSize: 21),
                          ),
                          GestureDetector(
                            onTap: publish == false
                                ? null
                                : () async {
                              print("loading " + loading.toString());
                              mystate(() => {loading = true});

                              DateTime now = DateTime.now();
                              if (datedisplay.isEmpty) {
                                datedisplay = DateFormat('EEE, d MMMM')
                                    .format(now);
                              }
                              if (timedisplay.isEmpty) {
                                timedisplay =
                                    DateFormat('kk:mm aa').format(now);
                                timeseconds =
                                    now.microsecondsSinceEpoch;
                              }

                              if (roomm != null) {
                                Database().updateUpcomingEvent(
                                    eventcontroller.text,
                                    datedisplay,
                                    timeseconds,
                                    timedisplay,
                                    descriptioncontroller.text,
                                    roomm.roomid,
                                    hosts);
                              } else {
                                Database().addUpcomingEvent(
                                    eventcontroller.text,
                                    datedisplay,
                                    timeseconds,
                                    timedisplay,
                                    descriptioncontroller.text,
                                    hosts);
                              }

                              mystate(() => {loading = false});
                              Navigator.pop(context);
                              timedisplay = "";
                              datedisplay = "";
                              descriptioncontroller.text = "";
                              eventcontroller.text = "";
                              publish = false;
                            },
                            child: Text(
                              roomm != null ? "Save" : "Publish",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: publish == true
                                      ? Colors.green
                                      : Colors.grey),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                        decoration: new BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                controller: eventcontroller,
                                maxLength: null,
                                onChanged: (val) {
                                  print(val.isEmpty.toString());
                                  if (val.isEmpty) {
                                    mystate(() {
                                      publish = false;
                                    });
                                  } else {
                                    mystate(() {
                                      publish = true;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                    hintStyle: TextStyle(
                                      fontSize: 16,
                                    ),
                                    hintText: "Event Name",
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    fillColor: Colors.white),
                                keyboardType: TextInputType.text,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Divider(),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "With ",
                                    style: (TextStyle(fontSize: 18)),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: ScrollPhysics(),
                                      itemBuilder: (lc, index) {
                                        return Column(
                                          children: [
                                            Container(
                                              margin:
                                              EdgeInsets.only(bottom: 10),
                                              child: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      RoundImage(
                                                        url: hosts[index]
                                                            .imageurl,
                                                        width: 30,
                                                        height: 30,
                                                        borderRadius: 15,
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        hosts[index]
                                                            .getName(),
                                                        style: (TextStyle(
                                                            fontSize: 16)),
                                                      ),
                                                    ],
                                                  ),
                                                  if (Get.find<
                                                      UserController>()
                                                      .user
                                                      .uid !=
                                                      hosts[index].uid)
                                                    InkWell(
                                                        onTap: () {
                                                          hosts.removeAt(
                                                              index);
                                                          mystate(() {});
                                                        },
                                                        child: Icon(
                                                            Icons.cancel))
                                                ],
                                              ),
                                            ),
                                            if (hosts.length - 1 != index)
                                              Divider()
                                          ],
                                        );
                                      },
                                      itemCount: hosts.length,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(),
                            InkWell(
                              onTap: () {
                                addCoHost(context, mystate);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 15, top: 10),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Add a Co-host or Guest",
                                      style: (TextStyle(fontSize: 16)),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_right_rounded,
                                      size: 30,
                                      color: Colors.grey,
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        )),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: new BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              mystate(() {
                                showdatecalendarpicker =
                                !showdatecalendarpicker;
                                showtimecalendarpicker = false;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Date",
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontFamily: "RobotoLight",
                                        color: Colors.black),
                                  ),
                                  Text(
                                      datedisplay.isEmpty
                                          ? "Today"
                                          : datedisplay,
                                      style: TextStyle(
                                          fontSize: 21,
                                          fontFamily: "RobotoLight",
                                          color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Divider(),
                          SizedBox(
                            height: 5,
                          ),
                          showdatecalendarpicker
                              ? Container(
                            height: 300,
                            child: CupertinoDatePicker(
                              initialDateTime: DateTime.now(),
                              use24hFormat: false,
                              onDateTimeChanged: (val) {
                                int timeInMillis =
                                    val.microsecondsSinceEpoch;
                                var date =
                                DateTime.fromMillisecondsSinceEpoch(
                                    timeInMillis);
                                var formattedDate =
                                DateFormat("EE").format(date);
                                var formattedDate2 =
                                DateFormat("MMMM").format(date);
                                mystate(() => {
                                  datedisplay = (formattedDate +
                                      ", " +
                                      val.day.toString() +
                                      " " +
                                      formattedDate2)
                                });
                              },
                              mode: CupertinoDatePickerMode.date,
                            ),
                          )
                              : Container(),
                          InkWell(
                            onTap: () {
                              mystate(() {
                                showtimecalendarpicker =
                                !showtimecalendarpicker;
                                showdatecalendarpicker = false;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Time",
                                    style: TextStyle(
                                        fontSize: 21,
                                        fontFamily: "RobotoLight",
                                        color: Colors.black),
                                  ),
                                  Text(
                                      timedisplay.isEmpty
                                          ? "6:00"
                                          : timedisplay,
                                      style: TextStyle(
                                          fontSize: 21,
                                          fontFamily: "RobotoLight",
                                          color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          showtimecalendarpicker
                              ? Container(
                            height: 300,
                            child: CupertinoDatePicker(
                              initialDateTime: DateTime.now(),
                              use24hFormat: false,
                              onDateTimeChanged: (val) {
                                print(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        val.millisecondsSinceEpoch));
                                mystate(() => {
                                  timedisplay = new DateFormat(
                                      "h:m aa")
                                      .format(DateTime
                                      .fromMillisecondsSinceEpoch(
                                      val.millisecondsSinceEpoch))
                                });
                                print(timedisplay);
                                timeseconds =
                                    val.millisecondsSinceEpoch;
                              },
                              mode: CupertinoDatePickerMode.time,
                            ),
                          )
                              : Container(),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: new BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      height: 200,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: TextFormField(
                        controller: descriptioncontroller,
                        maxLines: null,
                        decoration: InputDecoration(
                            hintStyle: TextStyle(
                              fontSize: 20,
                            ),
                            hintText: 'Description',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            fillColor: Colors.white),
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    roomm == null
                        ? Container()
                        : InkWell(
                      onTap: () {
                        var alert = new CupertinoAlertDialog(
                          title: new Text('Are you sure?'),
                          content: new Text(
                              'deleting this event will remove it from upcoming for all users'),
                          actions: <Widget>[
                            new CupertinoDialogAction(
                                child: const Text('Delete Event'),
                                isDestructiveAction: true,
                                onPressed: () async {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  mystate(() => {loading = true});
                                  await upcomingroomsRef
                                      .doc(roomm.roomid)
                                      .delete();
                                  mystate(() => {loading = false});
                                }),
                            new CupertinoDialogAction(
                                child: const Text('Never Mind'),
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
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.white),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Delete Event",
                                style: (TextStyle(
                                    fontSize: 16, color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
    },
  );
}