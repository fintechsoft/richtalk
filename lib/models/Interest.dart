import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:richtalk/util/style.dart';
/*
  type : Model
 */
class Interest extends GetxController{
  String title;
  bool active;
  String id;
  IconData icon;
  Color bgcolor = Style.pinkAccent;
  Color txtcolor = Colors.white;

  get txtucolor => txtcolor.value;

  Interest({this.title, this.active,this.id,this.icon,this.bgcolor,this.txtcolor});

  factory Interest.fromJson(json) {
    return Interest(
      id: json.id,
      title: json.id,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      "id": this.id,
      "title": this.title,
    };
  }

  factory Interest.fromJson2(String name, String index) {
    return Interest(
      id: index,
      title: name,
    );
  }

}