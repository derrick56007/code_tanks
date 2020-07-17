import 'dart:html';

import 'state.dart';

class StateManager {
  State currentState;

  final states = <String, State>{};

  Iterable<String> get keys => states.keys;

  void addAll(Map<String, State> _states) => states.addAll(_states);

  void pushState(String stateName) {
    if (!states.containsKey(stateName)) {
      print('No such state!');
      return;
    }

    print('pushed $stateName');
    currentState?.hide();

    currentState = states[stateName];
    currentState.show();
  }
}
