import 'dart:math';

// ignore: avoid_relative_lib_imports
import '../lib/src/server/server_utils/angle.dart';

import 'package:test/test.dart';

void main() {
  group('simple test', () {
  

    setUp(() {

    });

    test('to degrees', () async {
      expect(pi.toDegrees(), 180);
    });

    test('to radians', () async {
      expect(180.toRadians(), pi);
    });    

    tearDown(() {
      //
    });
  });
}
