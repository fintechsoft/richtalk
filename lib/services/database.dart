import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/Notifications/push_nofitications.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/models/models.dart';
import 'package:roomies/pages/home/home_page.dart';
import 'package:roomies/pages/room/upcoming_roomsreen.dart';
import 'package:roomies/util/firebase_refs.dart';
import 'package:roomies/util/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/io_client.dart';
import 'package:path/path.dart';

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

      if (update == true) {
        Reference storageReferance = FirebaseStorage.instance.ref();
        storageReferance
            .child(Get.find<UserController>().user.imageurl)
            .delete()
            .then((_) => print(
                'Successfully deleted ${Get.find<UserController>().user.imageurl} storage item'));
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
      "uid": id,
      "lastname": user.lastname,
      "bio": "",
      "host": false,
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
      "phonenumber": FirebaseAuth.instance.currentUser.phoneNumber,
      "profileImage": user.imageurl,
      "isNewUser": true,
      "lastAccessTime": DateTime.now().microsecondsSinceEpoch,
    };
    await usersRef.doc(id).set(data);
    Get.to(() => HomePage());
  }

  createRoom(
      {UserModel userData,
      String topic,
      String type,
      String roomid,
      List<UserModel> users}) async {

    //GENERATE AGORA TOKEN
    if (users != null && users.length > 0) {
      if(users.indexWhere((element) => element.uid == userData.uid) == -1) users.add(userData);
    }

    return await getCallToken(userData.uid, "0").then((token) async {
      if (token != null) {
        //CREATING A ROOM
        var ref = await roomsRef.add(
          {
            'title': topic.isEmpty ? '${userData.username}\'s Room' : topic,
            "ownerid": userData.uid,
            'users': users != null && users.length > 0
                ? users
                    .map((e) => e.toMap(
                        usertype: e.uid == userData.uid ? "host" : "others"))
                    .toList()
                : [
                    userData.toMap(
                      callmute: false,
                    )
                  ],
            "raisedhands": [],
            'handsraisedby': 1,
            'roomtype': type,
            'token': token,
            'speakerCount': 1,
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

        //SEND NOTIFICATION
        PushNotificationsManager().sendFcmMessageToTopic(
            title: "$topic is happening right now",
            message: "By ${Get.find<UserController>().user.getName()}",
            topic: "all");

        return ref;
      }
    });
  }

  addUsertoUpcomingRoom(UpcomingRoom room) async {
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

    Get.to(() => UpcomingRoomScreen());
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
      var url = Uri.parse(
          '$tokenpath/generaltokenkoodle?channel=$channel&uid=$uid');
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
    await usersRef.doc(Get.find<AuthController>().user.uid).update({
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
      "followers": FieldValue.arrayUnion([Get.find<AuthController>().user.uid])
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
  }

  //follow user
  unFolloUser(String otherId) async {
    await usersRef.doc(Get.find<AuthController>().user.uid).update({
      "following ": FieldValue.arrayRemove([otherId])
    });
    await usersRef.doc(otherId).update({
      "followers": FieldValue.arrayRemove([Get.find<AuthController>().user.uid])
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
    if (!Get.find<UserController>()
        .user
        .following
        .contains(Get.find<UserController>().user.uid))
      Get.find<UserController>()
          .user
          .following
          .add(Get.find<UserController>().user.uid);
    print(Get.find<UserController>().user.following);
    return limit == -1
        ? usersRef
            .where("uid", whereNotIn: Get.find<UserController>().user.following)
            .snapshots()
            .map(_usersFromFirebase)
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
  static Stream<List<UserModel>> getWeFollowEachOther() {
    if(Get.find<UserController>().user.following.length >0){
      return usersRef
          .where("uid", whereIn: Get.find<UserController>().user.following)
          .snapshots()
          .map(_usersFromFirebase);
    }
    return null;

  }

  static List<UserModel> _usersFromFirebase(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) => UserModel.fromJson(e.data())).toList();
  }

  //ADD UPCOMING EVENT
  addUpcomingEvent(String title, String datedisplay, int timeseconds,
      String timedisplay, String description, List<UserModel> hosts) async {
    print({
      "title": title,
      "eventdate": datedisplay,
      "eventtime": timeseconds,
      "timedisplay": timedisplay,
      "users": hosts.map((i) => i.toMap()).toList(),
      "description": description,
      "userid": Get.find<AuthController>().user.uid,
      "started": false,
      "published_date": FieldValue.serverTimestamp()
    });
    await upcomingroomsRef.add({
      "title": title,
      "eventdate": datedisplay,
      "eventtime": timeseconds,
      "timedisplay": timedisplay,
      "users": hosts
          .map((i) => i.toMap(
              usertype: i.uid != Get.find<AuthController>().user.uid
                  ? "speaker"
                  : "host"))
          .toList(),
      "description": description,
      "userid": Get.find<AuthController>().user.uid,
      "started": false,
      "published_date": FieldValue.serverTimestamp()
    });

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

  //UPDATE UPCOMING EVENT
  updateUpcomingEvent(
      String title,
      String datedisplay,
      int timeseconds,
      String timedisplay,
      String description,
      String roomid,
      List<UserModel> hosts) async {
    await upcomingroomsRef.doc(roomid).update({
      "title": title,
      "eventdate": datedisplay,
      "eventtime": timeseconds,
      "timedisplay": timedisplay,
      "users": hosts.map((i) => i.toMap()).toList(),
      "description": description,
      "userid": Get.find<AuthController>().user.uid,
      "started": false,
      "published_date": FieldValue.serverTimestamp()
    });
  }

  //ADD EVENT ACTIVITY

  addActivity(Map<String, dynamic> data) {
    activitiesRef.add(data);
  }
}
