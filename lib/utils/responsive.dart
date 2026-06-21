import 'package:flutter/widgets.dart';

class Responsive {
  // width percentage: call Responsive.wp(context, 0.5) -> 50% of screen width
  static double wp(BuildContext context, double fraction) {
    final w = MediaQuery.of(context).size.width;
    return w * fraction;
  }

  // height percentage: call Responsive.hp(context, 0.3) -> 30% of screen height
  static double hp(BuildContext context, double fraction) {
    final h = MediaQuery.of(context).size.height;
    return h * fraction;
  }

  // font scaling based on a baseline width (375 is iPhone 8 baseline)
  // call Responsive.fs(context, 16) -> scaled font size
  static double fs(BuildContext context, double fontSize) {
    final w = MediaQuery.of(context).size.width;
    return fontSize * (w / 375.0);
  }
}
