import 'dummy_socket.dart';
import 'custom.dart' as custom;

void main() async {
  final bot = custom.createTank();

  const url = 'ws://0.0.0.0:9899';

  final socket = DummySocket(url);

  socket //
    ..on('type', (data) {});

  await socket.start();
}
