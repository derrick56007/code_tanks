import 'dart:async';
import 'dart:html';

import '../../client_web_socket/client_websocket.dart';
import '../state.dart';

class PlayState extends State {
  final Element playCard = querySelector('#play-card');

  final ButtonElement buildBtn = querySelector('#build-btn');
  final ButtonElement runBtn = querySelector('#run-btn');

  final Element editorElement = querySelector('#editor');
  final Element logOutput = querySelector('#log-output');

  StreamSubscription buildBtnSub;
  StreamSubscription runBtnSub;

  PlayState(ClientWebSocket client) : super(client) {
    client
    ..on('log', (data) => onLogData(data))
    ..on('build_done', (data) => onBuildDone(data));
  }

  void onBuildDone(data) {
    // TODO validate data

    final success = data['success'];

    if (success) {
      runBtn.disabled = false;
    }

    buildBtn.disabled = false;
  }

  void onLogData(data) {
    // TODO validate data

    final line = data['line'];

    final lineElement = Element.html('<div class="log">$line</div>');

    // TODO formatted logs
    logOutput
      ..children.add(lineElement)
      ..parent.scrollTop = logOutput.parent.scrollHeight;
  }

  @override
  void show() {
    playCard.style.display = '';

    buildBtnSub = buildBtn.onClick.listen((event) {
      if (!buildBtn.disabled) {
        final code = editorElement.text;
        final codeLang = 'dart'; // TODO fix placeholder
        final tankName = 'custom'; // TODO fix placeholder

        final msg = {
          'code': code,
          'code_language': codeLang,
          'tank_name': tankName
        };

        client.send('build_code', msg);
      }

      // buildBtn.blur();
      buildBtn.disabled = true;
    });

    runBtnSub = runBtn.onClick.listen((event) {
      if (!runBtn.disabled) {}

      // runBtn.blur();
      runBtn.disabled = true;
    });
  }

  @override
  void hide() {
    playCard.style.display = 'none';

    buildBtnSub?.cancel();
    runBtnSub?.cancel();
  }
}
