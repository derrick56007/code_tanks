import 'src/client.dart';

void main() async {
  final address = '0.0.0.0';
  final port = 9896;

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
  
  print('login');
  StateManager.shared.pushState('login');  
}
