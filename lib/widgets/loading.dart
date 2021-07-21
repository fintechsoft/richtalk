import 'package:roomies/util/style.dart';
import 'package:flutter/material.dart';

Widget loadingWidget(){
  return Center(
    child: Container(
      // width: 20,
      color: Style.AccentBrown,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );
}