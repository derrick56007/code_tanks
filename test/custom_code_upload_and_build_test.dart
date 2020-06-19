import 'dart:io';

import 'package:code_tanks/code_tanks_common.dart';
import 'package:test/test.dart';

void main() {
  final address = '0.0.0.0';
  final port = 9898;

  group('Simple Test', () {
    DummySocket socket;

    setUp(() async {

      socket = DummySocket('ws://$address:$port');
      await socket.start();
    });

    test('First Test', () {
      socket.on('code_upload_success', (data) async {
        expect(socket != null, isTrue);
      });

      socket.send('code_upload', {
        'name': 'DoNothingTank',
        'language': 'en',
        'code_language': 'dart',
        'code': '''
import 'code_tanks_api.dart';

class Custom extends BaseTank {
  @override
  void onDetectRobot(DetectRobotEvent e) {
    // TODO: implement onDetectRobot
  }

  @override
  void tick() {
    // TODO: implement tick
  }
  
}

BaseTank createTank() => Custom();
'''
      });
    });
  });
}
