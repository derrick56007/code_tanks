import 'dart:html';

import 'package:code_tanks/code_tanks_client.dart';

class LandingState extends State {
  LandingState(ClientWebSocket client, StateManager stateManager)
      : super(client, stateManager, querySelector('#landing-state')) {
    querySelector('#run-btn').onClick.listen((_) {
      stateManager.pushState('settings');
    });
  }

  @override
  void hide() {
    stateElement.style.display = 'none';
  }

  @override
  void show() {
    stateElement.style.display = 'flex';
  }
}
