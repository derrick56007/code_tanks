import 'dart:html';

import '../state.dart';

class RenameState extends State {
  final InputElement renameTankName = querySelector('#rename-tank-name');

  String tankName;

  RenameState()
      : super(querySelector('#rename-tank-state'));

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

  @override
  void init() {
    renameTankName.onInput.listen((_) {
      final ButtonElement submitRenameTankBtn = querySelector('#submit-rename-tank-btn');

      submitRenameTankBtn.disabled = renameTankName.value.trim().isEmpty;
    });

    querySelector('#cancel-rename-tank-btn').onClick.listen((_) {
      hide();
    });
  }
}
