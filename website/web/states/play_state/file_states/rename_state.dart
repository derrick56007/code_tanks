import 'dart:html';

import 'package:code_tanks/code_tanks_client.dart';

class RenameState extends State {
  final InputElement renameTankName = querySelector('#rename-tank-name');

  String tankName;

  RenameState(ClientWebSocket client, StateManager stateManager)
      : super(client, stateManager, querySelector('#rename-tank-state')) {
    renameTankName.onInput.listen((_) {
      final ButtonElement submitRenameTankBtn = querySelector('#submit-rename-tank-btn');

      submitRenameTankBtn.disabled = renameTankName.value.trim().isEmpty;
    });

    querySelector('#cancel-rename-tank-btn').onClick.listen((_) {
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

    renameTankName
      ..focus()
      ..click();

    tankName = renameTankName.value.trim();
  }
}
