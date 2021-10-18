import 'package:get/get.dart';
import 'package:richtalk/models/models.dart';
/*
  type : Class
  packages used: Getx
  function: this is the controller class that listens to room object changes
 */
class CurrentRoomController extends GetxController {
  Rx<Room> _room = Rx<Room>();

  Room get room => _room.value;
  set room(Room room) => this._room.value = room;
  String get roomid => _room.value.roomid;
}