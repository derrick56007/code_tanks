import 'dart:io';

import 'dummy_socket.dart';
import 'custom.dart' as custom;
import 'common_websocket.dart';
import 'code_tanks_api.dart';

void main() async {

  final gameKey = Platform.environment['GAME_KEY'];

  // TODO replace with game server address
  const url = 'ws://host.docker.internal:9899';

  final socket = DummySocket(url);
  final bot = custom.createTank();

  handleSocketAndBot(socket, bot);

  print('game instance connecting to $url');

  await socket.start();
  print('game instance connected');  

  final data = {'game_key': gameKey};
  socket.send('game_instance_handshake', data);
}

void handleSocketAndBot(socket, BaseTank bot) {

  void onUpdateRequest(_) {
    print('received update request');
    bot.run();
    final msg = { 'commands': bot.currentCommands };
    socket.send('update_response', msg);
    bot.currentCommands.clear();
  }

  void onEvent(data) {

  }

  socket //
    ..on('update_request', onUpdateRequest)
    ..on('event', onEvent);  
}
