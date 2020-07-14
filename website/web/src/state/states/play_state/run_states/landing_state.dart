import 'dart:async';
import 'dart:html';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class LandingState extends State {
  final Element landingDiv = querySelector('#landing-state');
  final ButtonElement runBtn = querySelector('#run-btn');

  StreamSubscription runBtnSub;

  LandingState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager); 

  @override
  void hide() {
    landingDiv.style.display = 'none';

    runBtnSub?.cancel();
  }

  @override
  void show() {
    landingDiv.style.display = 'flex';


    runBtnSub = runBtn.onClick.listen((event) {
      // final msg = {
      //   'tank_names': ['custom', 'custom']
      // };

      // client.send('run_game', msg);
      stateManager.pushState('settings');

      // runBtn.blur();
      // buildBtn.disabled = true;
    });    
  }
  
}