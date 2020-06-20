import 'dart:html';

import 'state.dart';

class StateManager {
  static final shared = StateManager._internal();

  final _states = <String, State>{};

  StateManager._internal() {
    window.onPopState.listen((PopStateEvent e) {
      final stateName = e.state.toString();

      _showState(stateName);
    });
  }

  Iterable<String> get keys => _states.keys;

  void addAll(Map<String, State> states) => _states.addAll(states);

  void pushState(String stateName) {
    if (!_states.containsKey(stateName)) {
      print('No such state!');
      return;
    }

    _showState(stateName);
  }

  void _showState(String stateName) {
    if (!_states.containsKey(stateName)) {
      print('No such state!');
      return;
    }

    _states.entries
        .where((e) => e.key != stateName)
        .forEach((e) => e.value.hide());

    _states[stateName].show();
  }
}
