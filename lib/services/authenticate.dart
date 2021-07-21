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

  /// This method is used to login the user
  ///  `AuthCredential`(`_phoneAuthCredential`) is needed for the signIn method
  /// After the signIn method from `AuthResult` we can get `FirebaserUser`(`_firebaseUser`)
  signIn(BuildContext context, AuthCredential authCreds) async {
    try {
      var result = await FirebaseAuth.instance.signInWithCredential(authCreds);
      if (result.user != null) {
        Database().getUserProfile(result.user.uid).then((value){
          Get.put(UserController()).user = value;
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
      return null;
    }



  }

  /// get the `smsCode` from the user
  /// when used different phoneNumber other than the current (running) device
  /// we need to use OTP to get `phoneAuthCredential` which is inturn used to signIn/login
  Future signInWithOTP(BuildContext context, smsCode, verId) async {
    PhoneAuthCredential authCreds = PhoneAuthProvider.credential(verificationId: verId, smsCode: smsCode);
    try {
      var result = await FirebaseAuth.instance.signInWithCredential(authCreds);
      if (result.user != null) {
        Database().getUserProfile(result.user.uid).then((value){
          Get.put(UserController()).user = value;
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
      return "null";
    }
  }
}