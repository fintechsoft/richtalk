import 'package:flutter/material.dart';

Widget noDataWidget(String text, {String fontfamily =  "InterMedium", double fontsize = 14}) {
  return Center(child: Text(text, style: TextStyle(fontFamily: fontfamily, fontSize: fontsize),));
}