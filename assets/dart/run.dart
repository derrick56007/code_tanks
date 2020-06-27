import 'dart:io';

import 'dummy_socket.dart';
import 'custom.dart' as custom;

void main() async {

  final gameKey = Platform.environment['GAME_KEY'];

  // TODO replace with game server address
  const url = 'ws://host.docker.internal:9899';

  final socket = DummySocket(url);

  final bot = custom.createTank();

  void onGameSetup(data) {
    //
  }

  socket //
    ..on('game_setup', onGameSetup);

  print('game instance connecting to $url');

  await socket.start();
  print('game instance connected');  

  final data = {'game_key': gameKey};
  socket.send('game_instance_handshake', data);
}
