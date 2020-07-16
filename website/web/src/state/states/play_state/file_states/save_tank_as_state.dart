import 'dart:html';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class SaveTankAsState extends State {
  final Element saveTankState = querySelector('#save-as-tank-state');
  final InputElement saveAsTankName = querySelector('#save-as-tank-name');

  final Element cancelSaveAsTankBtn = querySelector('#cancel-save-as-tank-btn');
  final ButtonElement submitSaveAsTankBtn = querySelector('#submit-save-as-tank-btn');

  SaveTankAsState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager) {
    saveAsTankName.onInput.listen((_) {
      submitSaveAsTankBtn.disabled = saveAsTankName.value.trim().isEmpty;
    });

    cancelSaveAsTankBtn.onClick.listen((_) { 
      hide();
    });
  }

  @override
  void hide() {
    saveTankState.style.display = 'none';
  }

  @override
  void show() {
    saveTankState.style.display = 'flex';
    saveAsTankName
      ..value = ''
      ..focus()
      ..click();

    submitSaveAsTankBtn.disabled = true;
  }
}
