import 'dart:html';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class RenameState extends State {

  final Element renameTankState = querySelector('#rename-tank-state');

  final InputElement renameTankName = querySelector('#rename-tank-name');

  final Element cancelRenameTankBtn = querySelector('#cancel-rename-tank-btn');
  final ButtonElement submitRenameTankBtn = querySelector('#submit-rename-tank-btn');

  String tankName;

  RenameState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager) {
    renameTankName.onInput.listen((_) { 
      submitRenameTankBtn.disabled = renameTankName.value.trim().isEmpty;
    });

    cancelRenameTankBtn.onClick.listen((_) { 
      hide();
    });
  }

  @override
  void hide() {
    renameTankState.style.display = 'none';
  }

  @override
  void show() {
    renameTankState.style.display = 'flex';

    renameTankName
      ..focus()
      ..click();

    tankName = renameTankName.value.trim();
  }
  
}