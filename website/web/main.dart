import 'package:code_tanks/code_tanks_client.dart';

void main() async {
  final address = '127.0.0.1';
  final port = 9897;

  final client = ClientWebSocket(address, port);
  await client.start();

  client.on('error', (data) {
    print('error: $data');
  });
 
  StateManager(client)
    ..addStatesAndSetFields({
      'login': LoginState(),
      'register': RegisterState(),
      'play': PlayState(),
    })
    ..pushState('login');
}
