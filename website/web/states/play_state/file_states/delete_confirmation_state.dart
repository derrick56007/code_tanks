import 'dart:html';

import 'package:code_tanks/code_tanks_client.dart';

class DeleteConfirmationState extends State {
  DeleteConfirmationState(ClientWebSocket client, StateManager stateManager)
      : super(client, stateManager, querySelector('#delete-confirmation-state')) {
    querySelector('#cancel-delete-confirmation-tank-btn').onClick.listen((_) {
      hide();
    });
  }

  @override
  void hide() {
    stateElement.style.display = 'none';
  }

  @override
  void show() {
    stateElement
      ..style.display = 'flex'
      ..click();
  }
}
