import 'package:flutter/material.dart';
import 'package:flutter_device_type/flutter_device_type.dart';

class ButtonCTA extends StatelessWidget {
  @required
  final String? title;
  final Brightness brightness;
  final bool enabled;
  final bool orangeDelete;
  final num? size;
  final onTap;
  final Icon? icon;
  final double? width;
  final double? fontSize;

  ButtonCTA(
      {Key? key,
        this.title,
        this.size,
        this.brightness = Brightness.light,
        this.onTap,
        this.enabled = true,
        this.orangeDelete = false,
        this.icon,
        this.width,
        this.fontSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              orangeDelete ? Colors.red : Colors.blue,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(size?.toDouble() ?? 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              this.icon != null
                  ? Container(
                  width: this.title != null && width! > 300 ? width! * .25 : width! * .2,
                  padding:(this.title != null && width! > 300) ? EdgeInsets.only(left: 50) : null,
                  child: this.icon)
                  : SizedBox(
                width: 0,
              ),
              SizedBox(
                width: (this.icon != null && this.title != null && Device.screenWidth > 440) ? 20 : 10,
                //width: 0,
              ),
              this.title != null
                  ? Container(
                width: this.icon != null
                    ? width! > 300 ? width! * .75 : width! * .7
                    : null,
                child: Text(
                  this.title!,
                  style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.white),
                  textAlign: TextAlign.start,
                ),
              )
                  : SizedBox(
                width: 0,
              ),
            ],
          ),
        ),
      ),
      onTap: enabled ? this.onTap : null,
    );
  }
}
