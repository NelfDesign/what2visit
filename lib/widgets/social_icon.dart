import 'package:flutter/material.dart';

class SocialIcon extends StatelessWidget {
  final IconData? iconSrc;
  final Color? color;
  final void Function()? press;

  SocialIcon({
    Key? key,
    this.iconSrc,
    this.press,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        padding: EdgeInsets.all(10),
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconSrc,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}