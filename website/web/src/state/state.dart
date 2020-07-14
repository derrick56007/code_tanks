import '../client.dart';
import '../client_web_socket/client_websocket.dart';

abstract class State {
  final ClientWebSocket client;
  final StateManager stateManager;

  State(this.client, this.stateManager);

  void show();
  void hide();
}