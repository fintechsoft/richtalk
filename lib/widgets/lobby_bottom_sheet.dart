import 'package:roomies/models/models.dart';
import 'package:roomies/widgets/round_button.dart';
import 'package:roomies/util/style.dart';
import 'package:roomies/widgets/round_image.dart';
import 'package:flutter/material.dart';
import 'package:roomies/pages/room/followers_match_grid_sheet.dart';

List lobbyBottomSheets = [
  {
    'image': 'assets/images/open.png',
    'text': 'Open',
    'selectedMessage': 'Start a room open to everyone',
  },
  {
    'image': 'assets/images/social.png',
    'text': 'Social',
    'selectedMessage': 'Start a room with people I follow',
  },
  {
    'image': 'assets/images/closed.png',
    'text': 'Closed',
    'selectedMessage': 'Start a room for people I choose',
  },
];

class LobbyBottomSheet extends StatefulWidget {
  final Function onButtonTap;
  final Function onChange;

  const LobbyBottomSheet({Key key, this.onButtonTap, this.onChange})
      : super(key: key);

  @override
  _LobbyBottomSheetState createState() => _LobbyBottomSheetState();
}

class _LobbyBottomSheetState extends State<LobbyBottomSheet> {
  var selectedButtonIndex = 0;
  var _textFieldController = new TextEditingController();
  final TextEditingController textController = new TextEditingController();
  List<UserModel> roomusers = [];

  final globalScaffoldKey = GlobalKey<ScaffoldState>();

  callback(List<UserModel> users) {
    roomusers = users;
    globalScaffoldKey.currentState.setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: globalScaffoldKey,
      padding: const EdgeInsets.only(
        top: 10,
        right: 20,
        left: 20,
        bottom: 20,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          InkWell(
            onTap: () {
              addTopicDialog(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
              ),
              alignment: Alignment.centerRight,
              child: Text(
                '+ Add a Topic',
                style: TextStyle(
                  color: Style.AccentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0, len = 3; i < len; i++)
                InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    setState(() {
                      selectedButtonIndex = i;
                    });
                    widget.onChange(
                        lobbyBottomSheets[selectedButtonIndex]['text']);
                  },
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                        color: i == selectedButtonIndex
                            ? Style.SelectedItemGrey
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: i == selectedButtonIndex
                              ? Style.SelectedItemBorderGrey
                              : Colors.transparent,
                        )),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: RoundImage(
                            width: 80,
                            height: 80,
                            borderRadius: 20,
                            path: lobbyBottomSheets[i]['image'],
                          ),
                        ),
                        Text(
                          lobbyBottomSheets[i]['text'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Divider(
            thickness: 1,
            height: 60,
            indent: 20,
            endIndent: 20,
          ),
          Text(
            lobbyBottomSheets[selectedButtonIndex]['selectedMessage'],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 20,
          ),
          lobbyBottomSheets[selectedButtonIndex]['text'] == "Closed" &&
                  roomusers.length == 0
              ? CustomButton(
                  color: Style.AccentGreen,
                  onPressed: () {
                    showModalBottomSheet(
                        backgroundColor: Colors.white,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(15.0)),
                        ),
                        context: context,
                        builder: (context) {
                          //3
                          return StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState) {
                            return DraggableScrollableSheet(
                                expand: false,
                                builder: (BuildContext context,
                                    ScrollController scrollController) {
                                  return Container(
                                      padding: EdgeInsets.only(top: 20),
                                      child: FollowerMatchGridPage(
                                        callback: callback,
                                        title: "With...",
                                        fromroom: false,
                                      ));
                                });
                          });
                        });
                  },
                  text: 'Choose People',
                )
              : CustomButton(
                  color: Style.AccentGreen,
                  onPressed: () {
                    widget.onButtonTap(
                        lobbyBottomSheets[selectedButtonIndex]['text'],
                        _textFieldController.text,
                        roomusers);
                  },
                  text: '🎉 Let\'s go',
                )
        ],
      ),
    );
  }

//dialog for adding a topic
  Future<void> addTopicDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add a Topic', style: TextStyle(fontSize: 16)),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'e.g what if every body in the world loved each other?',
                  style: TextStyle(fontSize: 13),
                )
              ],
            ),
            content: TextField(
              onChanged: (value) {
                setState(() {});
              },
              controller: _textFieldController,
              decoration: InputDecoration(),
            ),
            actions: <Widget>[
              TextButton(
                child: Container(
                    color: Colors.red,
                    child: Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.white),
                    )),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
              TextButton(
                child: Container(
                    color: Colors.red,
                    child: Text(
                      'SET TOPIC',
                      style: TextStyle(color: Colors.white),
                    )),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }
}
