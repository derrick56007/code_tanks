import 'dart:html';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class DeleteConfirmationState extends State {
  final Element deleteConfirmationState = querySelector('#delete-confirmation-state');

  // final Element deleteConfirmationTankName = querySelector('#delete-confirmation-tank-name');

  final Element cancelDeleteConfirmationBtn = querySelector('#cancel-delete-confirmation-tank-btn');

  DeleteConfirmationState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager) {
    cancelDeleteConfirmationBtn.onClick.listen((_) {
      hide();
    });
  }

  @override
  void hide() {
    deleteConfirmationState.style.display = 'none';
  }

  @override
  void show() {
    deleteConfirmationState
      ..style.display = 'flex'
      ..click();
  }
}
