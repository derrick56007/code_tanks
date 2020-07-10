import 'dart:async';
import 'dart:html';

import 'package:codemirror/codemirror.dart';

import '../../client_web_socket/client_websocket.dart';
import '../state.dart';

class PlayState extends State {
  final Element playCard = querySelector('#play-card');

  final ButtonElement buildBtn = querySelector('#build-btn');
  final ButtonElement runBtn = querySelector('#run-btn');

  final Element editorElement = querySelector('#editor');
  final Element logOutput = querySelector('#log-output');

  final options = <String, String>{'mode': 'javascript', 'theme': 'monokai'};

  CodeMirror editor;

  StreamSubscription buildBtnSub;
  StreamSubscription runBtnSub;

  PlayState(ClientWebSocket client) : super(client) {
    client
      ..on('log', onLogData)
      ..on('build_done',  onBuildDone)
      ..on('run_game_response', onRunGameResponse);

    editor = CodeMirror.fromElement(editorElement, options: options);
    editor.setLineNumbers(true);
    editor.getDoc().setValue('''
import 'code_tanks_api.dart';

class Custom extends BaseTank {
  @override
  void run() {
    setRadarToRotateWithGun(true);

    ahead(2);
    rotateGun(2);
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    ahead(2);
  }

  @override
  void onScanTank(ScanTankEvent e) {
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    ahead(2);
  }
}

BaseTank createTank() => Custom();''');
    editor.refresh();
  }

  void onBuildDone(data) {
    // TODO validate data

    final success = data['success'];

    if (success) {
      runBtn.disabled = false;
    }

    buildBtn.disabled = false;
  }

  void onRunGameResponse(data) {
    // TODO validate data
    print('received frames');
    print(data);

    runBtn.disabled = false;

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
      if (buildBtn.disabled) {
        return;
      }
      final code = editor.getDoc().getValue();
      final codeLang = 'dart'; // TODO fix placeholder
      final tankName = 'custom'; // TODO fix placeholder

      final msg = {'code': code, 'code_language': codeLang, 'tank_name': tankName};

      client.send('build_code', msg);

      // buildBtn.blur();
      buildBtn.disabled = true;
    });

    runBtnSub = runBtn.onClick.listen((event) {
      if (runBtn.disabled) {
        return;
      }

      final msg = {
        'tank_names': ['custom']
      };

      client.send('run_game', msg);

      // runBtn.blur();
      runBtn.disabled = true;
      buildBtn.disabled = true;
    });

    editor.focus();
    editor.refresh();
  }

  @override
  void hide() {
    playCard.style.display = 'none';

    buildBtnSub?.cancel();
    runBtnSub?.cancel();
  }
}
