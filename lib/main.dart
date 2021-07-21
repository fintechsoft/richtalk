import 'package:roomies/util/style.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bindings.dart';
import 'services/authenticate.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roomies',
      theme: ThemeData(
        scaffoldBackgroundColor: Style.LightBrown,
        fontFamily: "RobotoRegular",
        appBarTheme: AppBarTheme(
          color: Style.LightBrown,
          textTheme: TextTheme(
            bodyText1: TextStyle(
              fontSize: 21,
              fontFamily: "InterBold"
            ),
          ),
          elevation: 0.0,
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
        ),
      ),
      initialBinding: AuthBinding(),
      home: AuthService().handleAuth(),
    );
  }
}
