import 'dart:html';

import 'package:code_tanks/code_tanks_client.dart';

class SaveTankAsState extends State {
  final InputElement saveAsTankName = querySelector('#save-as-tank-name');

  final ButtonElement submitSaveAsTankBtn = querySelector('#submit-save-as-tank-btn');

  SaveTankAsState(ClientWebSocket client, StateManager stateManager)
      : super(client, stateManager, querySelector('#save-as-tank-state')) {
    saveAsTankName.onInput.listen((_) {
      submitSaveAsTankBtn.disabled = saveAsTankName.value.trim().isEmpty;
    });

    querySelector('#cancel-save-as-tank-btn').onClick.listen((_) {
      hide();
    });
  }

  @override
  void hide() {
    stateElement.style.display = 'none';
  }

  @override
  void show() {
    stateElement.style.display = 'flex';
    saveAsTankName
      ..value = ''
      ..focus()
      ..click();

    submitSaveAsTankBtn.disabled = true;
  }
}
