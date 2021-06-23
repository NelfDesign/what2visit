import 'package:flutter/material.dart';
import 'package:flutter_device_type/flutter_device_type.dart';

class SocialIcon extends StatelessWidget {
  final IconData? iconSrc;
  final Color? color;
  final Function? press;

  SocialIcon({
    Key? key,
    this.iconSrc,
    this.press,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => press,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        padding: EdgeInsets.all(10),
        height: Device.screenWidth > 440 ? 70 : 50,
        width: Device.screenWidth > 440 ? 70 : 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconSrc,
          color: Colors.white,
        ),
      ),
    );
  }
}