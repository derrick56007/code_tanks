import 'dart:io';

import 'package:code_tanks/code_tanks_server.dart';
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
        'language': 'en',
        'code_language': 'dart',
        'code': '''
main() {
  print("derp");
}
'''
      });
    });
  });
}
