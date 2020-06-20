import '../client_web_socket/client_websocket.dart';

abstract class State {
  final ClientWebSocket client;

  State(this.client);

  void show();
  void hide();
}