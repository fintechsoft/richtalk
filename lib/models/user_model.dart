import 'dart:io';
/*
  type : Model
 */

class UserModel {
   String firstname;
   String lastname;
   String bio;
   String username;
   String uid;
   String phonenumber;
   String countrycode;
   String countryname;
   String imageurl;
   String profileImage;
   int lastAccessTime;
   int callerid;
   List<String> interests;
   List<String> followers;
   List<String> following;
   bool isNewUser = true;
   bool callmute = false;
   bool moderator = false;
   File imagefile;
   String usertype;
   int valume = 1;
   String activeroom = "";
   String firebasetoken = "";

  UserModel({
    this.valume,
    this.interests,
    this.firebasetoken,
    this.usertype,
    this.activeroom,
    this.bio,
    this.firstname,
    this.moderator,
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
    this.followers,
    this.following,
    this.lastAccessTime,
    this.isNewUser,
    this.callmute = true,
  });

  getName(){
    return this.firstname+" "+this.lastname;
  }

   Map<String, dynamic>  toMap({usertype = "host", callmute = true, callerid = 0}) {
       return {
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
    List<String> followers  = json["followers"] == null ? [] : List<String>.from(json["followers"].map((item)=> item));
    List<String> following  = json["following"] == null ? [] : List<String>.from(json["following"].map((item)=> item));
    List<String> interests  = json["interests"] == null ? [] : List<String>.from(json["interests"].map((item)=> item));

    return UserModel(
      lastname: json['lastname'],
      interests: interests,
      firstname: json['firstname'],
      activeroom: json['activeroom'] ?? "",
      callerid: json['callerid'] ?? 0,
      valume: json['valume'] ?? 0,
      callmute: json['callmute'] ?? false,
      username: json['username'],
      countrycode: json['countrycode'],
      firebasetoken: json['firebasetoken'],
      usertype: json['usertype'],
      uid: json['uid'],
      moderator: json['moderator'],
      bio: json['bio'] ?? "",
      countryname: json['countryname'],
      phonenumber: json['phonenumber'],
      imageurl: json['imageurl'],
      profileImage: json['profileImage'],
      lastAccessTime: json['lastAccessTime'],
      followers: followers,
      following: following,
      isNewUser: json['isNewUser'] ?? true,
    );
  }
}
