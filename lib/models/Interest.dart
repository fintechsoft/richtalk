import 'package:flutter/material.dart';
import 'package:get/get.dart';
/*
  type : Model
 */
class Interest extends GetxController{
  String title;
  bool active;
  String id;
  IconData icon;
  Color bgcolor = Colors.red;
  Color txtcolor = Colors.white;

  get txtucolor => txtcolor.value;

  Interest({this.title, this.active,this.id,this.icon,this.bgcolor,this.txtcolor});

  factory Interest.fromJson(json) {
    print(json.id);
    return Interest(
      id: json.id,
      title: json.id,
    );
  }
  factory Interest.fromJson2(String name, String index) {
    return Interest(
      id: index,
      title: name,
    );
  }

}