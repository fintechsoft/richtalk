import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roomies/models/Interest.dart';
import 'package:roomies/models/room.dart';
/*
  type : Model
 */

class UserModel {
  String firstname;
  bool sendfewernotifications;
  String lastname;
  bool online;
  String bio;
  String username;
  Room activeRoom;
  String uid;
  String phonenumber;
  String countrycode;
  String countryname;
  String imageurl;
  String profileImage;
  int lastAccessTime;
  int callerid;
  List<Interest> interests;
  List<String> followers;
  List<String> clubs;
  List<String> following;
  bool isNewUser = true;
  bool callmute = false;
  bool moderator = false;
  bool subroomtopic = false;
  bool subtrend = false;
  bool subothernot = false;
  bool pausenotifications = false;
  File imagefile;
  String usertype;
  int valume = 1;
  String activeroom = "";
  String firebasetoken = "";
  Timestamp pausedtime;

  UserModel({
    this.sendfewernotifications,
    this.valume,
    this.subroomtopic,
    this.pausenotifications,
    this.subothernot,
    this.subtrend,
    this.interests,
    this.firebasetoken,
    this.usertype,
    this.clubs,
    this.activeroom,
    this.bio,
    this.firstname,
    this.moderator,
    this.online,
    this.lastname,
    this.countrycode,
    this.uid,
    this.countryname,
    this.username,
    this.callerid,
    this.phonenumber,
    this.imagefile,
    this.imageurl,
    this.profileImage,
    this.activeRoom,
    this.followers,
    this.following,
    this.lastAccessTime,
    this.isNewUser,
    this.pausedtime,
    this.callmute = true,
  });

  getName() {
    return this.firstname + " " + this.lastname;
  }

  Map<String, dynamic> toMap(
      {usertype = "host", callmute = true, callerid = 0}) {
    return {
      "sendfewernotifications": sendfewernotifications,
      "pausenotifications": pausenotifications,
      "pausedtime": pausedtime,
      "subothernot": subothernot,
      "subtrend": subtrend,
      "subroomtopic": subroomtopic,
      "valume": valume,
      "firebasetoken": firebasetoken,
      "lastname": lastname,
      "bio": bio,
      "firstname": firstname,
      "uid": uid,
      "usertype": usertype,
      "activeroom": activeroom,
      "callerid": callerid,
      "callmute": callmute,
      "moderator": moderator,
      "username": this.username,
      "countrycode": countrycode,
      "countryname": countryname,
      "phonenumber": phonenumber,
      "imageurl": imageurl,
      "profileImage": imageurl,
      "isNewUser": isNewUser,
    };
  }

  factory UserModel.fromJson(json) {
    List<String> followers = json["followers"] == null
        ? []
        : List<String>.from(json["followers"].map((item) => item));
    List<String> following = json["following"] == null
        ? []
        : List<String>.from(json["following"].map((item) => item));

    List<String> clubs = json["clubs"] == null
        ? []
        : List<String>.from(json["clubs"].map((item) => item));

    List<Interest> interests = [];//json["interests"] == null
        // ? []
        // : List<Interest>.from(json["interests"].map((item) {
        //     return new Interest.fromJson2(item["title"], item["id"]);
        //   }));
    return UserModel(
      lastname: json['lastname'],
      clubs: clubs,
      subothernot: json['subothernot'] ?? false,
      sendfewernotifications: json['sendfewernotifications'] ?? false,
      pausenotifications: json['pausenotifications'] ?? false,
      pausedtime: json['pausedtime'] ?? null,
      subtrend: json['subtrend'] ?? false,
      subroomtopic: json['subroomtopic'] ?? false,
      interests: interests,
      firstname: json['firstname'],
      activeroom: json['activeroom'] ?? "",
      callerid: json['callerid'] ?? 0,
      valume: json['valume'] ?? 0,
      callmute: json['callmute'] ?? false,
      online: json['online'] ?? false,
      username: json['username'],
      countrycode: json['countrycode'],
      firebasetoken: json['firebasetoken'],
      usertype: json['usertype'],
      uid: json['uid'],
      moderator: json['moderator'],
      bio: json['bio'] ?? "",
      countryname: json['countryname'],
      phonenumber: json['phonenumber'],
      imageurl: json['imageurl'] ?? "",
      profileImage: json['profileImage'] ?? "",
      lastAccessTime: json['lastAccessTime'],
      followers: followers,
      following: following,
      isNewUser: json['isNewUser'] ?? true,
    );
  }
}
