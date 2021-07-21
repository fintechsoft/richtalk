import 'package:roomies/models/models.dart';
import 'package:roomies/pages/room/upcoming_roomsreen.dart';
import 'package:roomies/pages/room/room_screen.dart';
import 'package:roomies/util/configs.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:get/get.dart';

class DynamicLinkService {

  /*
    generate sharing dynamic link
   */
  Future<String> createGroupJoinLink(String groupId, [type]) async {
    final DynamicLinkParameters parameters =  DynamicLinkParameters(
      uriPrefix: deeplinkuriPrefix,
      link: Uri.parse('$websitedomain/?groupid=$groupId&type=$type'),
      androidParameters: AndroidParameters(
        packageName: packagename,
      ),
      // NOT ALL ARE REQUIRED ===== HERE AS AN EXAMPLE =====
      iosParameters: IosParameters(
        bundleId: packagename,
        minimumVersion: '3.3',
        appStoreId: '1529768550',
      ),
    );

    final ShortDynamicLink dynamicUrl = await parameters.buildShortLink();
    return dynamicUrl.shortUrl.toString();
  }

  /*
      when link is clicked, this function handles the link and redirects user to the app if its installed
      or if its not installed its redirected to the website link attached to firebase dynamic links
   */
  Future handleDynamicLinks() async {
    // 1. Get the initial dynamic link if the app is opened with a dynamic link
    final PendingDynamicLinkData data =
    await FirebaseDynamicLinks.instance.getInitialLink();

    // 2. handle link that has been retrieved
    _handleDeepLink(data);

    // 3. Register a link callback to fire if the app is opened up from the background
    // using a dynamic link.
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          // 3a. handle link that has been retrieved
          _handleDeepLink(dynamicLink);
        }, onError: (OnLinkErrorException e) async {
    });
  }


  /*
      handle dynamic link redirection logic
   */
  Future<void> _handleDeepLink(PendingDynamicLinkData data) async {
    final Uri deepLink = data?.link;
    if (deepLink != null) {
      var groupid = deepLink.queryParameters['groupid'];

      //check if the shared link is an upcoming room
      if(deepLink.queryParameters['type'] =="upcomingroom"){
        roomsRef.doc(groupid).get().then((value) async {
          if(value.exists){
            Get.to(()=>RoomScreen(roomid: groupid));
          }else{
            upcomingroomsRef.doc(groupid).get().then((value) async {
              if(value.exists){
                UpcomingRoom room = UpcomingRoom.fromJson(value);
                Get.to(()=> UpcomingRoomScreen(room:room));
              }
            });
          }
        });
      }else{
        var groupid = deepLink.queryParameters['groupid'];
        roomsRef.doc(groupid).get().then((value) async {
          if(value.exists){
            Room room = Room.fromJson(value);
            Get.to(()=>RoomScreen(roomid: groupid, room: room,));
          }
        });
      }
    }
  }
}