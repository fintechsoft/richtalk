import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
class UserProfileImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final String type;
  final Color bordercolor;

  const UserProfileImage({
    Key key,
    @required this.imageUrl,
    this.size = 48.0,
    this.type,
    this.bordercolor = const Color(0xFFFFFFFF),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2 - size / 18),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          border: Border.all(color: bordercolor ?? Color(0xFFFFFFFF), width: type =="header" ? 0 : 5),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size / 2 - size / 18),
              topRight: Radius.circular(size / 2 - size / 18),
              bottomRight: Radius.circular(size / 2 - size / 18),
              bottomLeft: Radius.circular(size / 2 - size / 18)
          ),
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              imageUrl,
            ),
            fit: BoxFit.cover,
          ),

        ),

      ),
      // child: Image.network(
      //   imageUrl,
      //   height: size,
      //   width: size,
      //   fit: BoxFit.cover,
      // ),
    );
  }
}