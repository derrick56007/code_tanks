import 'dart:async';
import 'dart:html';

import '../state.dart';

class NewTankState extends State {
  final ButtonElement submitCreateTankBtn = querySelector('#submit-create-tank-btn');
  final InputElement newTankName = querySelector('#new-tank-name');
  final Element codeLanguageSelected = querySelector('#code-language-selected');

  StreamSubscription codeLangSub;

  NewTankState() : super(querySelector('#new-tank-state'));

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

  @override
  void init() {
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
}
