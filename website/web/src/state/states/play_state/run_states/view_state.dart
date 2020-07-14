import 'dart:async';
import 'dart:html';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class ViewState extends State {
  final Element viewDiv = querySelector('#view-state');
  final ButtonElement closeViewBtn = querySelector('#close-view-btn');

  StreamSubscription closeViewSub;


  ViewState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager) {
    client //
      ..on('run_game_response', onRunGameResponse);
  }

  void onRunGameResponse(data) {
    // TODO validate data
    print('received frames');
    print(data);

    // runBtn.disabled = false;

    // buildBtn.disabled = false;
  }

  @override
  void hide() {
    viewDiv.style.display = 'none';

    closeViewSub?.cancel();
  }

  @override
  void show() {
    viewDiv.style.display = '';

    closeViewSub = closeViewBtn.onClick.listen((event) {
      stateManager.pushState('landing');
    });
  }
}
