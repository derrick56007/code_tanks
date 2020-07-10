import 'package:code_tanks/src/common/test_socket.dart';
import 'package:test/test.dart';

void main() {
  group('simple test', () {
    final testSocket = TestSocket();

    setUp(() {
      void derp() async {
        await testSocket.onSingleAsync('test', (data) {
          print(data);
        });
      }

      derp();
      testSocket.onSingleAsync('test2', (data) {
        print(data);
      });
    });

    test('first test', () async {
      testSocket.send('test', 'derp');
      testSocket.send('test', 'derp2');
      testSocket.send('test2', 'derp3');
      testSocket.send('test2', 'derp23');
    });

    test('second test', () async {
      final updateDone = testSocket.onSingleAsync('update', (data) {
        print('received update');
      });
      testSocket.send('update');
      await updateDone;
      print('done');
    });

    tearDown(() {
      //
    });
  });
}
