import 'dart:math';

extension Angle on num {
  num toDegrees() => this * 180 / pi;
  num toRadians() => this * pi / 180;
}