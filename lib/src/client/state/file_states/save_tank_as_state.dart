import 'dart:html';

import '../state.dart';

class SaveTankAsState extends State {
  final InputElement saveAsTankName = querySelector('#save-as-tank-name');

  final ButtonElement submitSaveAsTankBtn = querySelector('#submit-save-as-tank-btn');

  SaveTankAsState()
      : super(querySelector('#save-as-tank-state'));

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

  @override
  void init() {
    saveAsTankName.onInput.listen((_) {
      submitSaveAsTankBtn.disabled = saveAsTankName.value.trim().isEmpty;
    });

    querySelector('#cancel-save-as-tank-btn').onClick.listen((_) {
      hide();
    });
  }
}
