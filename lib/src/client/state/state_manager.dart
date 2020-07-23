import 'package:code_tanks/code_tanks_common.dart';

import 'state.dart';

class StateManager {
  State currentState;
  final CommonWebSocket client;

  final states = <String, State>{};

  StateManager(this.client);

  Iterable<String> get keys => states.keys;

  void addStatesAndSetFields(Map<String, State> _states) {
    states.addAll(_states);

    for (final state in _states.values) {
      state
        ..stateManager = this
        ..client = client
        ..init();
    }
  }

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
