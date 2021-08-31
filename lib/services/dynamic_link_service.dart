import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/util/configs.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/clubs/view_club.dart';
import 'package:roomies/pages/home/profile_page.dart';
import 'package:roomies/pages/room/upcoming_roomsreen.dart';
import 'package:roomies/pages/room/room_screen.dart';
import 'package:roomies/services/database.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:get/get.dart';

class DynamicLinkService {
  /*
    generate sharing dynamic link
   */
  Future<String> createGroupJoinLink(String groupId, [type]) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
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

    _handleDeepLink(data);

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          _handleDeepLink(dynamicLink);
        },
        onError: (OnLinkErrorException e) async {});
  }

  /*
      handle dynamic link redirection logic
   */
  Future<void> _handleDeepLink(PendingDynamicLinkData data) async {
    final Uri deepLink = data?.link;
    if (deepLink != null) {
      var groupid = deepLink.queryParameters['groupid'];

      //check if the shared link is an upcoming room
      if (deepLink.queryParameters['type'] == "upcomingroom") {
        roomsRef.doc(groupid).get().then((value) async {
          if (value.exists) {
            Get.to(() => RoomScreen(roomid: groupid));
          } else {
            upcomingroomsRef.doc(groupid).get().then((value) async {
              if (value.exists) {
                UpcomingRoom room = UpcomingRoom.fromJson(value);
                Get.to(() => UpcomingRoomScreen(room: room));
              }
            });
          }
        });
      } //check if the shared link is an upcoming room
      else if (deepLink.queryParameters['type'] == "profile") {
        print(groupid);
        usersRef.where("username", isEqualTo: groupid).get().then((value) async {
          if (value.docs.length > 0) {
            Get.to(
              () => ProfilePage(
                profile: UserModel.fromJson(value.docs[0].data()),
                fromRoom: false,
              ),
            );
          }
        });
      }//check if the shared link is an club
      else if (deepLink.queryParameters['type'] == "club") {
        print(groupid);
        clubRef.doc(groupid).get().then((value) async {
          if (value.exists) {
            Get.to(
              () => ViewClub(
                club: Club.fromJson(value)
              ),
            );
          }
        });
      } else {
        var groupid = deepLink.queryParameters['groupid'];
        roomsRef.doc(groupid).get().then((value) async {
          if (value.exists) {
            Room room = Room.fromJson(value);

            //leave any existing room
            await Database().leaveActiveRoom();

            //add user to a room
            await Database().addUserToRoom(
                room: room,
                role: ClientRole.Audience,
                user: Get.find<UserController>().user);
            Get.to(() => RoomScreen(
                  roomid: groupid,
                  room: room,
                ));
          }
        });
      }
    }
  }
}
