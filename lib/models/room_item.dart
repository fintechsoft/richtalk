import 'package:roomies/models/models.dart';

class RoomItem{
  final String image;
  final String text;
  final Club club;
  final String selectedMessage;

  RoomItem({this.image,this.text,this.club,this.selectedMessage});

  factory RoomItem.fromJson(Map map) {
    return RoomItem(
        image: map['image'],
        text: map['text'],
        club: map['club'],
        selectedMessage: map['selectedMessage'],
    );
  }
  List<RoomItem> lobbyBottomSheets = [];
  List<RoomItem> getItems(){
    Map map = {
      'image': 'assets/images/open.png',
      'text': 'Open',
      'club': null,
      "location": false,
      'selectedMessage': 'Start a room open to everyone',
    };
    RoomItem roomItem = RoomItem.fromJson(map);
    lobbyBottomSheets.add(roomItem);
    Map map1 = {
      'image': 'assets/images/social.png',
      'text': 'Social',
      'club': null,
      "location": false,
      'selectedMessage': 'Start a room with people I follow',
    };
    RoomItem roomItem1 = RoomItem.fromJson(map1);
    lobbyBottomSheets.add(roomItem1);


    Map map2 = {
      'image': 'assets/images/closed.png',
      'text': 'Closed',
      'club': null,
      "location": false,
      'selectedMessage': 'Start a room for people I choose',
    };
    RoomItem roomItem2 = RoomItem.fromJson(map2);
    lobbyBottomSheets.add(roomItem2);


    Map map3 = {
      'image': 'assets/images/closed.png',
      'text': 'By Location',
      'club': null,
      "location": true,
      'selectedMessage': 'Start a room for within your location',
    };
    RoomItem roomItem3 = RoomItem.fromJson(map3);
    lobbyBottomSheets.add(roomItem3);
    return lobbyBottomSheets;
  }
}