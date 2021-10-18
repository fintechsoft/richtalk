import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:richtalk/controllers/controllers.dart';
import 'package:richtalk/models/models.dart';
import 'package:richtalk/pages/clubs/select_hsost_club.dart';
import 'package:richtalk/pages/room/add_co_host.dart';
import 'package:richtalk/pages/room/upcoming_roomsreen.dart';
import 'package:richtalk/services/database.dart';
import 'package:richtalk/util/utils.dart';
import 'package:richtalk/widgets/widgets.dart';
import 'package:intl/intl.dart';

//ignore: must_be_immutable
class NewUpcomingRoom extends StatefulWidget {
   UpcomingRoom roomm;
   Club club;
   String from;

  NewUpcomingRoom({this.roomm, this.from, this.club});

  @override
  _NewUpcomingRoomState createState() => _NewUpcomingRoomState();
}

class _NewUpcomingRoomState extends State<NewUpcomingRoom> {
  List<UserModel> hosts = [Get.find<UserController>().user];

  userClickCallBack(UserModel user) {
    if (!hosts.contains(user)) hosts.add(user);
    setState(() {});
  }

  void addCoHost(BuildContext context, StateSetter setState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(15),
        topRight: Radius.circular(15),
      )),
      builder: (context) {
        return AddCoHostScreen(clickCallback: userClickCallBack);
      },
    ).whenComplete(() {
      print('Hey there, I\'m calling after hide bottomSheet');
    });
  }

  setselectedclub(Club club) {
    widget.club = club;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.roomm != null) {
      eventcontroller.text = widget.roomm.title;
      descriptioncontroller.text = widget.roomm.description;
      datedisplay = widget.roomm.eventdate;
      timedisplay = widget.roomm
          .timedisplay; // DateTime.fromMillisecondsSinceEpoch(roomm.eventtime).hour.toString()+":"+DateTime.fromMillisecondsSinceEpoch(roomm.eventtime).minute.toString();
      publish = true;
      timeseconds = widget.roomm.eventtime;
    }
    print("hosts ${hosts.length}");

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset : false,
      body: Container(
        padding:
            const EdgeInsets.only(top: 30, right: 20, left: 20, bottom: 20),
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
                              style: TextStyle(fontSize: 20, color: Style.pinkAccent),
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
                                    setState(() => {loading = true});

                                    DateTime now = DateTime.now();
                                    if (datedisplay.isEmpty) {
                                      datedisplay =
                                          DateFormat('EEE, d MMMM').format(now);
                                    }
                                    if (timedisplay.isEmpty) {
                                      timedisplay =
                                          DateFormat('kk:mm aa').format(now);
                                      timeseconds = now.microsecondsSinceEpoch;
                                    }

                                    if (widget.roomm != null) {
                                      Database().updateUpcomingEvent(
                                          eventcontroller.text,
                                          datedisplay,
                                          timeseconds,
                                          timedisplay,
                                          descriptioncontroller.text,
                                          widget.roomm.roomid,
                                          hosts,
                                          widget.club);
                                    } else {
                                      Database().addUpcomingEvent(
                                          eventcontroller.text,
                                          datedisplay,
                                          timeseconds,
                                          timedisplay,
                                          descriptioncontroller.text,
                                          hosts,
                                          widget.club);
                                    }

                                    setState(() => {loading = false});
                                    Navigator.pop(context);
                                    timedisplay = "";
                                    datedisplay = "";
                                    descriptioncontroller.text = "";
                                    eventcontroller.text = "";
                                    publish = false;
                                  },
                            child: Text(
                              widget.roomm != null ? "Save" : "Publish",
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
                                    setState(() {
                                      publish = false;
                                    });
                                  } else {
                                    setState(() {
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
                                                        txt: hosts[index].firstname,
                                                        txtsize: 10,
                                                        width: 30,
                                                        height: 30,
                                                        borderRadius: 15,
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Text(
                                                        hosts[index].getName(),
                                                        style: (TextStyle(
                                                            fontSize: 16)),
                                                      ),
                                                    ],
                                                  ),
                                                  if (Get.find<UserController>()
                                                          .user
                                                          .uid !=
                                                      hosts[index].uid)
                                                    InkWell(
                                                        onTap: () {
                                                          hosts.removeAt(index);
                                                          setState(() {});
                                                        },
                                                        child:
                                                            Icon(Icons.cancel))
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
                                addCoHost(context, setState);
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 15, top: 10),
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
                              setState(() {
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
                                      setState(() => {
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
                              setState(() {
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
                                      print(DateTime.fromMillisecondsSinceEpoch(
                                          val.millisecondsSinceEpoch));
                                      setState(() => {
                                            timedisplay = new DateFormat(
                                                    "h:m aa")
                                                .format(DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        val.millisecondsSinceEpoch))
                                          });
                                      print(timedisplay);
                                      timeseconds = val.millisecondsSinceEpoch;
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
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15.0)),
                              ),
                              context: context,
                              builder: (context) {
                                //3
                                return StatefulBuilder(builder:
                                    (BuildContext context,
                                        StateSetter setState) {
                                  return SelectHostClub(
                                      selectedclub: widget.club,
                                      setselectedclub: setselectedclub);
                                });
                              });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Host Club",
                                style: (TextStyle(fontSize: 18)),
                              ),
                              Row(
                                children: [
                                  Text(
                                    widget.club != null
                                        ? widget.club.title
                                        : "None",
                                    style: (TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    )),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_right_rounded,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
                    widget.roomm == null
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
                                        setState(() => {loading = true});
                                        await upcomingroomsRef
                                            .doc(widget.roomm.roomid)
                                            .delete();
                                        setState(() => {loading = false});
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
                                          fontSize: 16, color: Style.pinkAccent)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}
