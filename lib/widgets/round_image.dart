import 'package:flutter/material.dart';

class RoundImage extends StatelessWidget {
  final String url;
  final String path;
  final String txt;
  final double width;
  final double height;
  final double txtsize;
  final EdgeInsets margin;
  final double borderRadius;

  const RoundImage({Key key,this.txtsize = 23, this.txt,this.url = "", this.path = "", this.margin, this.width = 40, this.height = 40, this.borderRadius = 40}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        image: url.isNotEmpty || path.isNotEmpty ? DecorationImage(
          image: path.isNotEmpty ? AssetImage(path) : NetworkImage(url),
          fit: BoxFit.cover,
        ) : null,
      ),
      child:url.isEmpty ?  Center(child: Text(txt !=null && txt.length>0 ? txt.substring(0, 2).toUpperCase() : "", style: TextStyle(fontSize: txtsize, color: Colors.black, fontFamily: "InterBold"),)) : null,
    );
  }
}
