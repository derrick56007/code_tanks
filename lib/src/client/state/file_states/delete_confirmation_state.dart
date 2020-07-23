import 'dart:html';

import '../state.dart';

class DeleteConfirmationState extends State {
  DeleteConfirmationState()
      : super(querySelector('#delete-confirmation-state'));

  @override
  void hide() {
    stateElement.style.display = 'none';
  }

  @override
  void show() {
    stateElement
      ..style.display = 'flex'
      ..click();
  }

  @override
  void init() {
    querySelector('#cancel-delete-confirmation-tank-btn').onClick.listen((_) {
      hide();
    });
  }
}
