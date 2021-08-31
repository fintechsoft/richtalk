import 'dart:convert';
import 'dart:io';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:roomies/Notifications/push_nofitications.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/util/configs.dart';
import 'package:roomies/functions/functions.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/home/select_interests.dart';
import 'package:roomies/pages/room/upcoming_roomsreen.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/io_client.dart';
import 'package:path/path.dart';
import 'package:roomies/widgets/widgets.dart';

class Database {
  //get profile user data
  Future<UserModel> getUserProfile(String id) async {
    return await usersRef.doc(id).get().then((value) {
      if (value.exists) {
        UserModel user = UserModel.fromJson(value.data());
        return user;
      }
      return null;
    });
  }
  //get profile user data
  Future<UserModel> getUserProfileByPhone(String phone) async {
    return await usersRef.where("phonenumber", isEqualTo: phone).get().then((value) {
      if(value.docs.length > 0){
        UserModel user = UserModel.fromJson(value.docs[0].data());
        return user;
      }
      return null;
    });
  }

  //upload image to firebase store and then returns image url
  uploadImage(String id, {bool update = false}) async {
    UserModel user = Get.find<OnboardingController>().onboardingUser;
    if (user.imagefile != null) {
      String fileName = basename(user.imagefile.path);
      Reference firebaseSt =
          FirebaseStorage.instance.ref().child('profile/$fileName');
      UploadTask uploadTask = firebaseSt.putFile(user.imagefile);

      await uploadTask.whenComplete(() async {
        String storagePath = await firebaseSt.getDownloadURL();
        user.imageurl = storagePath;

      });

      try{
        //remove previous image
        if(update == true){
          if(Get.find<UserController>().user.imageurl ==null || Get.find<UserController>().user.imageurl.isEmpty) return;
          updateProfileData(Get.find<UserController>().user.uid, {
            "imageurl" : user.imageurl
          });
          String link = Get.find<UserController>().user.imageurl;
          link =  link.split("/")[7];
          link = link.replaceAll("%20"," ");
          link = link.replaceAll("%2C", ",");
          link = link.substring(0, link.indexOf('.jpg'));
          link = link.replaceAll("%2F", "/");
          Reference storageReferance = FirebaseStorage.instance.ref();
          storageReferance
              .child("/"+link+".jpg")
              .delete()
              .then((_) => print(
              'Successfully deleted ${Get.find<UserController>().user.imageurl} storage item'));

        }
      }catch(e){
        print("error deleting and updating the profile image");
      }

    }else{
      user.imageurl = "";
    }
  }
  //upload image to firebase store and then returns image url
  uploadClubImage(String clubid, {bool update = false, File file, String previousurl = ""}) async {
    if (file != null) {
      String fileName = basename(file.path);
      print(fileName);
      Reference firebaseSt =
      FirebaseStorage.instance.ref().child('clubicons/$fileName');
      UploadTask uploadTask = firebaseSt.putFile(file);

      await uploadTask.whenComplete(() async {
        String storagePath = await firebaseSt.getDownloadURL();
        updateClub(clubid, {
          "iconurl": storagePath,
        });
      });

      //delete previous icon url
      if(previousurl.isNotEmpty){

        String link = previousurl;
        link =  link.split("/")[7];
        link = link.replaceAll("%20"," ");
        link = link.replaceAll("%2C", ",");
        link = link.substring(0, link.indexOf('.jpg'));
        link = link.replaceAll("%2F", "/");
        if (update == true) {
          Reference storageReferance = FirebaseStorage.instance.ref();
          storageReferance
              .child("/"+link+".jpg")
              .delete()
              .then((_) => print(
              'Successfully deleted ${Get.find<UserController>().user.imageurl} storage item'));
        }
      }
    }
  }

  //create user profile with the extra data and save them in firestore
  Future createUserInfo(String id) async {
    UserModel user = Get.find<OnboardingController>().onboardingUser;
    await uploadImage(id);
    var data = {
      "username": user.username,
      "firstname": user.firstname,
      "pausenotifications": user.pausenotifications,
      "uid": id,
      "lastname": user.lastname,
      "bio": "",
      "host": false,
      "subroomtopic": true,
      "subtrend": true,
      "subothernot": true,
      "online": true,
      "moderator": false,
      "callerid": 0,
      "valume": 0,
      "callmute": false,
      "followers": [],
      "following": [],
      "imageurl": user.imageurl,
      "countrycode": user.countrycode,
      "firebasetoken": await FirebaseMessaging.instance.getToken(),
      "countryname": user.countryname,
      "phonenumber": FirebaseAuth.instance.currentUser.email !=null && FirebaseAuth.instance.currentUser.email.isNotEmpty ? "+"+FirebaseAuth.instance.currentUser.email.split('@')[0] : FirebaseAuth.instance.currentUser.phoneNumber,
      "profileImage": user.imageurl,
      "interests": [],
      "isNewUser": true,
      "lastAccessTime": DateTime.now().microsecondsSinceEpoch,
      "membersince": DateTime.now().microsecondsSinceEpoch,
    };
    await usersRef.doc(id).set(data);
    FirebaseMessaging.instance.subscribeToTopic("all");
    Get.to(() => InterestsPick(
      title: "Add your interests so we can begin to personalize Roomies for you. Interests are private to you",
      showbackarrow: false,
      fromsignup: true,
    ));
  }

  //leave any existing room
  leaveActiveRoom({BuildContext context}) async {
    await getUserProfile(Get.find<UserController>().user.uid)
        .then((value) async {
      if (value.activeroom.isNotEmpty) {
        Room myroom = await Database().getRoomDetails(value.activeroom);
        if (myroom != null) {
          await Functions.leaveChannel(
              quit: false, room: myroom, currentUser: value, context: context);
        }
      }
    });
  }

  //check if followed by the speaks
  bool followedBySpeakersCheck(Room room) {
    List<String> ff = [];
    for (var j = 0; j < room.users.length; j++) {
      UserModel element = room.users[j];
      if (element.usertype == "speaker" || element.usertype == "host") {
        print(Get.find<UserController>().user.followers);
        if (Get.find<UserController>().user.followers.contains(element.uid)) {
          ff.add(element.uid);
        }
      }
    }
    if (ff.length > 0) {
      return true;
    } else {
      return false;
    }
  }

  createRoom(
      {UserModel userData,
      String topic,
      String type,
      String roomid,
      List<UserModel> users,
      BuildContext context,
      String clubid,
      String clubname}) async {
    //leave any existing room
    await leaveActiveRoom();

    //GENERATE AGORA TOKEN
    if (users != null && users.length > 0) {
      if (users.indexWhere((element) => element.uid == userData.uid) == -1)
        users.add(userData);
    }

    return await getCallToken(userData.uid, "0").then((token) async {
      if (token != null) {
        //CREATING A ROOM
        var ref = await roomsRef.add(
          {
            'title': topic.isEmpty ? '' : topic,
            "ownerid": userData.uid,
            'users': users != null && users.length > 0
                ? users
                    .map((e) => e.toMap(
                        usertype: e.uid == userData.uid ? "host" : "others",
                        callmute: e.uid == userData.uid ? false : true))
                    .toList()
                : [
                    userData.toMap(
                      callmute: false,
                    )
                  ],
            "raisedhands": [],
            'handsraisedby': 1,
            'clubname': clubname,
            'clubid': clubid,
            'roomtype': type,
            'token': token,
            'speakerCount': 1,
            "created_time": DateTime.now().microsecondsSinceEpoch,
          },
        );

        //log activity
        Get.find<UserController>().user.following.forEach((element) {
          var data2 = {
            "imageurl": Get.find<UserController>().user.imageurl,
            "name": Get.find<UserController>().user.getName(),
            "message": " started a new room",
            'to': element,
            "time": FieldValue.serverTimestamp(),
          };
          addActivity(data2);
        });

        //update my active room
        updateProfileData(
            Get.find<UserController>().user.uid, {"activeroom": ref.id});

        //SEND NOTIFICATION TO FOLLOWING
        sendNotificationToMyFollowing(Get.find<UserController>().user);
        return ref;
      }
    });
  }

  //send notification to my following
  //check if they want to be sent notification
  sendNotificationToMyFollowing(UserModel following) {
    usersRef
        .where("following", arrayContainsAny: [following.uid])
        .where("subroomtopic", isEqualTo: true)
        .get()
        .then((value) {
          print("sending to ${value.docs.length}");
          if (value.docs.length > 0) {
            List<String> users = [];
            value.docs.forEach((element) {
              users.add(element.data()["firebasetoken"]);
            });
            print(users);
            PushNotificationsManager().callOnFcmApiSendPushNotifications(
                users, "${following.username} $rooomstarted", "");
          }
        });
  }

  addUsertoUpcomingRoom(UpcomingRoom room, {fromhome = false}) async {
    UserModel myProfile = Get.put(UserController()).user;

    upcomingroomsRef.doc(room.roomid).set({
      "users": FieldValue.arrayUnion([myProfile.toMap(usertype: "others")]),
    }, SetOptions(merge: true));

    Get.snackbar("", "Share Link Copied To Clipboard",
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 0,
        margin: EdgeInsets.all(0),
        backgroundColor: Colors.green,
        colorText: Colors.white,
        messageText: Text.rich(TextSpan(
          children: [
            TextSpan(
              text: "Added to " + room.title + " room successfully",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )));
    if (fromhome == false) {
      Get.to(() => UpcomingRoomScreen());
    }
  }

  removeUserFromUpcomingRoom(UpcomingRoom room) async {
    print("removeUserFromUpcomingRoom");
    UserModel myProfile = Get.put(UserController()).user;
    if (myProfile.uid != room.userid) {
      room.users.removeAt(
          room.users.indexWhere((element) => element.uid == myProfile.uid));
      upcomingroomsRef.doc(room.roomid).update({
        "users": room.users.map((i) => i.toMap()).toList(),
      });
    }
  }

  //update room data

  updateRoomData(String roomid, data) {
    roomsRef.doc(roomid).update(data);
  }

  //update profile data

  updateProfileData(String userid, data) {
    usersRef.doc(userid).update(data);
  }

  //getupcoming

  //Generate agora channel token,
  //the script to generate this is a nodejs script
  getCallToken(String channel, String uid) async {
    try {
      final ioc = new HttpClient();
      ioc.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      final http = new IOClient(ioc);
      print('$tokenpath?channel=$channel&uid=$uid');
      var url = Uri.parse('$tokenpath?channel=$channel&uid=$uid');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)["token"];
      } else {
        throw Exception('Failed to load token');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  //follow user
  folloUser(UserModel otherUser) async {
    await usersRef.doc(Get.find<UserController>().user.uid).update({
      "following": FieldValue.arrayUnion([otherUser.uid])
    });

    //follow userlog activity

    var data1 = {
      "imageurl": Get.find<UserController>().user.imageurl,
      "name": "",
      'to': Get.find<UserController>().user.uid,
      "message": "you started following ${otherUser.getName()}",
      "time": FieldValue.serverTimestamp(),
    };
    addActivity(data1);

    await usersRef.doc(otherUser.uid).update({
      "followers": FieldValue.arrayUnion([Get.find<UserController>().user.uid])
    });

    //followed userlog activity

    var data2 = {
      "imageurl": Get.find<UserController>().user.imageurl,
      "name": Get.find<UserController>().user.getName(),
      "message": " started following you",
      'to': otherUser.uid,
      "time": FieldValue.serverTimestamp(),
    };

    addActivity(data2);
    String title = "🙂 👋 New Follower";
    String msg =
        "${Get.find<UserController>().user.getName()} started following you";
    PushNotificationsManager().callOnFcmApiSendPushNotifications(
        [otherUser.firebasetoken], title, msg);
  }

  //follow user
  unFolloUser(String otherId) async {
    await usersRef.doc(Get.find<UserController>().user.uid).update({
      "following": FieldValue.arrayRemove([otherId])
    });

    await usersRef.doc(otherId).update({
      "followers": FieldValue.arrayRemove([Get.find<UserController>().user.uid])
    });
  }

  //invite user to a user
  inviteUserToClub(Club club, UserModel userModel) async {
    await clubRef.doc(club.id).update({
      "invited": FieldValue.arrayUnion([userModel.uid])
    });

    //follow userlog activity

    var data1 = {
      "imageurl": Get.find<UserController>().user.imageurl,
      "name":
          "${Get.find<UserController>().user.firstname + " " + Get.find<UserController>().user.lastname}",
      "type": "clubinvite",
      "actionkey": club.id,
      "actioned": false,
      'to': userModel.uid,
      "message": " invited you to join ${club.title} club",
      "time": FieldValue.serverTimestamp(),
    };
    addActivity(data1);

    String title = "🙂 👋 New Club Invite";
    String msg =
        "${Get.find<UserController>().user.getName()} invite you to ${club.title} club";
    PushNotificationsManager().callOnFcmApiSendPushNotifications(
        [userModel.firebasetoken], title, msg);
  }

  //invite user to a club
  unInviteUser(Club club, UserModel userModel) async {
    await clubRef.doc(club.id).update({
      "invited": FieldValue.arrayRemove([userModel.uid])
    });
  }

  //invite user to a club
  static acceptClubInvite(String clubid) async {
    await clubRef.doc(clubid).update({
      "members": FieldValue.arrayUnion([Get.find<UserController>().user.uid]),
    });
  }

  //invite user to a club
  static activityUpdate(String id, data) async {
    await activitiesRef.doc(id).update(data);
  }

  //get room details
  Future<Room> getRoomDetails(String roomid) {
    return roomsRef.doc(roomid).get().then((value) {
      if (value.exists == true) {
        return Room.fromJson(value);
      }
      return null;
    });
  }

  //GET UPCOMING ROOMS
  static getEvents(String show, [int limit]) {
    return show == "mine"
        ? upcomingroomsRef
            .where("userid", isEqualTo: Get.find<UserController>().user.uid)
            .orderBy("eventtime", descending: true)
            .snapshots()
        : limit == null
            ? upcomingroomsRef
                .orderBy("eventtime", descending: true)
                .snapshots()
            : upcomingroomsRef
                .orderBy("eventtime", descending: true)
                .limit(limit)
                .snapshots();
  }

  //GET INTERESTS
  static Stream<List<Interest>> getInterests() {
    return interestsRef.snapshots().map(_interestsFromFirebase);
  }

  static List<Interest> _interestsFromFirebase(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) => Interest.fromJson(e)).toList();
  }

  //GET USERS TO FOLLOW
  static Stream<List<UserModel>> getUsersToFollow([int limit]) {
    return limit == -1
        ? usersRef.snapshots().map(_usersFromFirebase)
        : usersRef.limit(limit).snapshots().map(_usersFromFirebase);
  }

  //GET PEOPLE I FOLLOW
  static Stream<List<UserModel>> getAmFollow() {
    return usersRef
        .where("uid", whereIn: Get.find<UserController>().user.following)
        .snapshots()
        .map(_usersFromFirebase);
  }

  //GET PEOPLE WE FOLLOW EACH OTHER
  static Stream<List<UserModel>> getmyFollowers() {
    if (Get.find<UserController>().user.following.length > 0) {
      return usersRef
          .where("followers",
              arrayContains: Get.find<UserController>().user.uid)
          .snapshots()
          .map(_usersFromFirebase);
    }
    return null;
  }

  static List<UserModel> _usersFromFirebase(QuerySnapshot querySnapshot) {
    print(querySnapshot.docs.length);
    return querySnapshot.docs.map((e) => UserModel.fromJson(e.data())).toList();
  }

  //add user to a room

  addUserToRoom({Room room, ClientRole role, UserModel user}) async {
    //ADD USE TO ROOM

    print("addUserToRoom ${user.toMap()}");

    await Database().updateRoomData(room.roomid, {
      "users": FieldValue.arrayUnion([user.toMap(usertype: "others")]),
    });
    //UPDDATE USER ACTIVE ROOM
    await Database().updateProfileData(user.uid, {"activeroom": room.roomid});
  }

  //ADD UPCOMING EVENT
  addUpcomingEvent(
      String title,
      String datedisplay,
      int timeseconds,
      String timedisplay,
      String description,
      List<UserModel> hosts,
      Club club) async {
    var ref = await upcomingroomsRef.add({
      "title": title,
      "eventdate": datedisplay,
      "eventtime": timeseconds,
      "timedisplay": timedisplay,
      "clubid": club != null ? club.id : "",
      "clubname": club != null ? club.title : "",
      "users": hosts
          .map((i) => i.toMap(
              usertype: i.uid != Get.find<UserController>().user.uid
                  ? "speaker"
                  : "host"))
          .toList(),
      "description": description,
      "userid": Get.find<UserController>().user.uid,
      "started": false,
      "published_date": FieldValue.serverTimestamp()
    });

    //update club with the room attached to it

    //update club with the room attached to it
    if (club != null) {
      updateClub(club.id, {
        "rooms": FieldValue.arrayUnion([ref.id])
      });
    }

    var data = {
      "imageurl": Get.find<UserController>().user.imageurl,
      "name": Get.find<UserController>().user.getName(),
      "message": "Scheduled '$title' for $datedisplay",
      "time": FieldValue.serverTimestamp(),
    };
    Get.find<UserController>()
        .user
        .following
        .add(Get.find<UserController>().user.uid);
    Get.find<UserController>().user.following.forEach((element) {
      data["to"] = element;
      addActivity(data);
    });

    PushNotificationsManager().sendFcmMessageToTopic(
        title:
            "Event calendar for $datedisplay - $timedisplay ${eventcontroller.text}",
        message: descriptioncontroller.text,
        topic: all);
  }

  //update club
  static updateClub(clubid, data) {
    clubRef.doc(clubid).update(data);
  }

  //ADD CLUB
  addClub(
      {String title,
      String description,
      bool allowfollowers,
      bool membercanstartrooms,
      bool membersprivate,
      List<Interest> selectedTopicsList, File image}) async {


    return await clubRef
        .where("title",
        isEqualTo: title)
        .get()
        .then((value) async {
      if (value.docs.length > 0) {
        topTrayPopup(
            "a club with that name already exists");
      } else {
        var ref = await clubRef.add({
          "title": title,
          "members":
              FieldValue.arrayUnion([Get.find<UserController>().user.uid]),
          "invited": [],
          "topics": selectedTopicsList.map((i) => i.toMap()).toList(),
          "description": description,
          "ownerid": Get.find<UserController>().user.uid,
          "published_date": FieldValue.serverTimestamp(),
          "allowfollowers": allowfollowers,
          "membercanstartrooms": membercanstartrooms,
          "membersprivate": membersprivate
        });

        await clubRef.doc(ref.id).update({
          "uid" : ref.id
        });

        await updateProfileData(Get.find<UserController>().user.uid, {
          "clubs": FieldValue.arrayUnion([ref.id])
        });

        //upload club image icon

        if(image !=null){
          await uploadClubImage(ref.id, file: image);
        }

        return ref;
      }

    });
  }

  //UPDATE UPCOMING EVENT
  updateUpcomingEvent(
      String title,
      String datedisplay,
      int timeseconds,
      String timedisplay,
      String description,
      String roomid,
      List<UserModel> hosts,
      Club club) async {
    await upcomingroomsRef.doc(roomid).update({
      "title": title,
      "eventdate": datedisplay,
      "eventtime": timeseconds,
      "clubid": club.id,
      "clubname": club.title,
      "timedisplay": timedisplay,
      "users": hosts.map((i) => i.toMap()).toList(),
      "description": description,
      "userid": Get.find<AuthController>().user.uid,
      "started": false,
      "published_date": FieldValue.serverTimestamp()
    });

    //update club with the room attached to it
    updateClub(club.id, {
      "rooms": FieldValue.arrayUnion([roomid])
    });
  }

  //ADD EVENT ACTIVITY

  addActivity(Map<String, dynamic> data) {
    activitiesRef.add(data);
  }

  void sendNotificationToUsersiFollow(String title, String msg) {
    Get.find<UserController>().user.followers.forEach((element) {
      usersRef.doc(element).get().then((value) {
        if (value.exists) {
          // UserModel user = UserModel.fromJson(value);
          PushNotificationsManager().callOnFcmApiSendPushNotifications(
              [value.data()['firebasetoken']], title, msg);
        }
      });
    });
  }

  //

  //clubs fact from firebase
  static List<Club> _clubsFromFirebase(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) => Club.fromJson(e)).toList();
  }

  static List<UpcomingRoom> _upcomingroomsFromFirebase(
      QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) => UpcomingRoom.fromJson(e)).toList();
  }

  //get club rooms
  static Stream<List<UpcomingRoom>> getClubUpcomingRooms(Club club) {
    print(club.id);
    return upcomingroomsRef
        .where("clubid", isEqualTo: club.id)
        .snapshots()
        .map(_upcomingroomsFromFirebase);
  }

  //get my clubs
  static Stream<List<Club>> getMyClubs(String id) {
    return clubRef
        .where("members",
            arrayContainsAny: [id])
        .orderBy("published_date", descending: true)
        .snapshots()
        .map(_clubsFromFirebase);
  }

  static getClubDetails(Club club) {
    return clubRef.doc(club.id).snapshots().listen((e) => Club.fromJson(e));
  }

  getClubByIdDetails(String id) async {
    print("getClubByIdDetails");
    return await clubRef.doc(id).get().then((e) {
      print("getClubByIdDetails ${e.data()}");
      return Club.fromJson(e);
    });
  }

  static Future<int> clubCheck(String title) async {
    return await clubRef.where("title", isEqualTo: title).snapshots().length;
  }

  static getusersInaClub(Club club) {
    return usersRef
        .where("uid", whereIn: club.members)
        .snapshots()
        .map(_usersFromFirebase);
  }

  static Future<int>  checkUsername(String text) async{
    return await usersRef.where("username", isEqualTo: text).get().then((value) {
      return value.docs.length;
    });
  }

  static friendsToFollow() {
    return usersRef
        .where("countrycode", isEqualTo: Get.put(UserController()).user.countrycode)
        .where("uid", isNotEqualTo: FirebaseAuth.instance.currentUser.uid)
        // .orderBy("membersince", descending: true)
        .snapshots().map(_usersFromFirebase);
  }

  static Stream<List<UserModel>> searchUser(String txt){
    if(txt.isEmpty) return usersRef.where("username", isLessThanOrEqualTo: txt).snapshots().map(_usersFromFirebase);
    if(txt.isNotEmpty) return usersRef.where("username", isGreaterThanOrEqualTo: txt).snapshots().map(_usersFromFirebase);
    return null;
  }

  static Stream<List<Club>> searchClub(String txt){
    if(txt.isEmpty) return clubRef.where("title", isLessThanOrEqualTo: txt).snapshots().map(_clubsFromFirebase);
    if(txt.isNotEmpty) return clubRef.where("title", isGreaterThanOrEqualTo: txt).snapshots().map(_clubsFromFirebase);
    return null;
  }



  //follow club
  static followClub(Club club) async {
    await clubRef.doc(club.id).update({
      "followers": FieldValue.arrayUnion([Get.find<UserController>().user.uid])
    });
  }

  //follow user
  static unFolloClub(Club club) async {
    await clubRef.doc(club.id).update({
      "followers": FieldValue.arrayRemove([Get.find<UserController>().user.uid])
    });
  }

  static  leaveClub(Club club) async {
    await clubRef.doc(club.id).update({
      "members": FieldValue.arrayRemove([Get.find<UserController>().user.uid]),
    });
  }

  static getClubFollowers(Club club) {
    if(club.followers.length > 0){

      return usersRef
          .where("uid", whereIn: club.followers)
          .snapshots()
          .map(_usersFromFirebase);
    }
    return null;
  }
}
