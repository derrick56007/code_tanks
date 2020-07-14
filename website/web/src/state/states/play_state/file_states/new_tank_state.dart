import 'dart:async';
import 'dart:html';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class NewTankState extends State {
  final Element newTankState = querySelector('#new-tank-state');

  final Element cancelCreateTankBtn = querySelector('#cancel-create-tank-btn');
  final ButtonElement submitCreateTankBtn = querySelector('#submit-create-tank-btn');
  final InputElement newTankName = querySelector('#new-tank-name');
  final Element codeLanguageSelected = querySelector('#code-language-selected');

  StreamSubscription codeLangSub;

  NewTankState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager) {
    cancelCreateTankBtn.onClick.listen((_) {
      hide();
    });

    submitCreateTankBtn.onClick.listen((event) {
      final tankName = newTankName.value.trim();
      final codeLanguage = codeLanguageSelected.text;

      if (validTankNameAndCodeLang(tankName, codeLanguage)) {

        final msg = {
          'tank_name': tankName,
          'code_language': codeLanguage,
        };

        client.send('create_new_tank', msg);
      }
    });
  }

  bool validTankNameAndCodeLang(String name, String lang) => name.trim().isNotEmpty && lang.trim().isNotEmpty;

  @override
  void hide() {
    newTankState.style.display = 'none';

    codeLangSub?.cancel();
  }

  @override
  void show() {
    newTankState.style.display = 'flex';

    submitCreateTankBtn.disabled = true;

    newTankName
      ..focus()
      ..click();


    codeLangSub = document.onClick.listen((_) { 
      final tankName = newTankName.value.trim();
      final codeLanguage = codeLanguageSelected.text;

      if (validTankNameAndCodeLang(tankName, codeLanguage)) {
        submitCreateTankBtn.disabled = false;
      } else {
        submitCreateTankBtn.disabled = true;
      }
    });

  }
}
