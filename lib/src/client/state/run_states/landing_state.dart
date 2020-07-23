import 'dart:html';

import '../state.dart';

class LandingState extends State {
  LandingState()
      : super(querySelector('#landing-state'));

  @override
  void hide() {
    stateElement.style.display = 'none';
  }

  @override
  void show() {
    stateElement.style.display = 'flex';
  }

  @override
  void init() {
    querySelector('#run-btn').onClick.listen((_) {
      stateManager.pushState('settings');
    });
  }
}
