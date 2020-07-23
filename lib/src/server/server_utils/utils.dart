import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;

class Utils {
static final chars = 'abcdefghijklmnopqrstuvwxyz0123456789'.codeUnits;

  static final Random _random = Random.secure();

  static String createRandomString(int length) {
    final values = List<int>.generate(length, (i) => chars[_random.nextInt(chars.length)]);

    return String.fromCharCodes(values);
  }

  static Future<Null> copyPath(String from, String to) async {
    await Directory(to).create(recursive: true);
    await for (final file in Directory(from).list(recursive: true)) {
      final copyTo = path.join(to, path.relative(file.path, from: from));
      if (file is Directory) {
        await Directory(copyTo).create(recursive: true);
      } else if (file is File) {
        await File(file.path).copy(copyTo);
      } else if (file is Link) {
        await Link(copyTo).create(await file.target(), recursive: true);
      }
    }
  }
}