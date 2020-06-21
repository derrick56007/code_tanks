import 'src/client.dart';

void main() async {
  final address = '127.0.0.1';
  final port = 9897;

  final client = ClientWebSocket(address, port);
  await client.start();

  client.on('error', (data) {
    print('error: $data');
  });

  StateManager.shared.addAll({
    'login': LoginState(client),
    'register': RegisterState(client),
    'play': PlayState(client)
  });
  
  StateManager.shared.pushState('login');  
}
