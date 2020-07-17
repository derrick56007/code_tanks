import 'package:code_tanks/code_tanks_client.dart';

import 'states/login_state.dart';
import 'states/play_state/play_state.dart';
import 'states/register_state.dart';

void main() async {
  final address = '127.0.0.1';
  final port = 9897;

  final client = ClientWebSocket(address, port);
  await client.start();

  client.on('error', (data) {
    print('error: $data');
  });
 
  final stateManager = StateManager();

  stateManager
    ..addAll({
      'login': LoginState(client, stateManager),
      'register': RegisterState(client, stateManager),
      'play': PlayState(client, stateManager)
    })
    ..pushState('login');
}
