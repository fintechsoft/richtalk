import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:roomies/controllers/controllers.dart';
import 'package:roomies/pages/home/home_page.dart';
import 'package:roomies/pages/onboarding/full_name_page.dart';
import 'package:roomies/pages/onboarding/welcome_page.dart';
import 'package:roomies/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthService {
  /// returns the initial screen depending on the authentication results
  handleAuth() {
    if(FirebaseAuth.instance.currentUser == null){
      return WelcomeScreen();
    }
    return FutureBuilder(
      future: Database().getUserProfile(FirebaseAuth.instance.currentUser.uid),
      builder: (BuildContext context, snapshot) {
        print(snapshot.error);
        if(snapshot.connectionState== ConnectionState.waiting){
          return Scaffold(
            body: Center(
              child: Container(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        if (snapshot.hasData ==true) {
          Get.put(UserController()).user = snapshot.data;
          return HomePage();
        } else {
          return FullNamePage();
        }
      },
    );
  }

  /// This method is used to logout the `FirebaseUser`
  signOut() {
    FirebaseAuth.instance.signOut();
    Get.to(() => WelcomeScreen());
  }


  /// get the `smsCode` from the user
  /// when used different phoneNumber other than the current (running) device
  /// we need to use OTP to get `phoneAuthCredential` which is inturn used to signIn/login
  Future signInWithEmail(String phone) async {
    String email = phone.isNotEmpty ? phone.substring(1)+"@gmail.com" : "";
    // PhoneAuthCredential authCreds = PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    try {
      var result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: phone);
      if (result.user != null) {
        Database().getUserProfile(result.user.uid).then((value) async {
          Get.put(UserController()).user = value;
          await Database().updateProfileData(result.user.uid, {
            "firebasetoken" : await FirebaseMessaging.instance.getToken()
          });
          if(value !=null){
            return Get.offAll(()=>HomePage());
          }else{
            return Get.to(()=>FullNamePage());
          }
        });
      } else {
        print("Error");
      }
    }catch(e){
      print("here ${e.toString()}");
      registerUser(email: email, password: phone);
      return "null";
    }
  }


  /// PRODUCTION SIGNIN IN WITH PHONE NUMBER
  Future signInWithOTP(verId, smsCode,[String phone]) async {
    PhoneAuthCredential authCreds = PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    try {
      print("authCreds ${authCreds}");

      var result = await FirebaseAuth.instance.signInWithCredential(authCreds);
      if (result.user != null) {
        FirebaseAuth.instance.currentUser.delete();
        signInWithEmail(phone);
      } else {
        print("Error");
      }
    }catch(e){
      print("here ${e.toString()}");
      return "null";
    }
  }

  registerUser({String email, String password}) async{
     await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password).then((value){
       print("after registration ${value.user.email}");
      return Get.to(()=>FullNamePage());
    });
  }
}