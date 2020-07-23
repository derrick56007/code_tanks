import 'dart:html';

import 'package:code_tanks/code_tanks_common.dart';

import '../client_websocket.dart';
import 'state_manager.dart';

abstract class State {
  CommonWebSocket client;
  StateManager stateManager;

  final Element stateElement;

  State(this.stateElement);

  void init();
  void show();
  void hide();
}