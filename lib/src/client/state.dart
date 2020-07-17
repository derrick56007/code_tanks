import 'dart:html';

import 'client_websocket.dart';
import 'state_manager.dart';

abstract class State {
  final ClientWebSocket client;
  final StateManager stateManager;

  final Element stateElement;

  State(this.client, this.stateManager, this.stateElement);

  void show();
  void hide();
}