import 'dart:async';
import 'dart:html';

import 'package:code_tanks/code_tanks_client.dart';

class NewTankState extends State {
  final ButtonElement submitCreateTankBtn = querySelector('#submit-create-tank-btn');
  final InputElement newTankName = querySelector('#new-tank-name');
  final Element codeLanguageSelected = querySelector('#code-language-selected');

  StreamSubscription codeLangSub;

  NewTankState(ClientWebSocket client, StateManager stateManager)
      : super(client, stateManager, querySelector('#new-tank-state')) {
    querySelector('#cancel-create-tank-btn').onClick.listen((_) {
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
    stateElement.style.display = 'none';

    codeLangSub?.cancel();
  }

  @override
  void show() {
    stateElement.style.display = 'flex';

    submitCreateTankBtn.disabled = true;

    newTankName
      ..focus()
      ..click();

    codeLangSub = document.onClick.listen((_) {
      final tankName = newTankName.value.trim();
      final codeLanguage = codeLanguageSelected.text;

      submitCreateTankBtn.disabled = !validTankNameAndCodeLang(tankName, codeLanguage);
    });
  }
}
