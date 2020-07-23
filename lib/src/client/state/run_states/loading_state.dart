import 'dart:html';

import '../state.dart';

class LoadingState extends State {
  LoadingState()
      : super(querySelector('#loading-state'));

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
    // TODO: implement init
  }
}
