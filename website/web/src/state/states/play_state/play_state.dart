import 'dart:async';
import 'dart:html';

import 'package:codemirror/codemirror.dart';

import '../../../client.dart';
import '../../../client_web_socket/client_websocket.dart';
import '../../state.dart';
import 'file_states/new_tank_state.dart';
import 'file_states/open_existing_tank_state.dart';
import 'run_states/landing_state.dart';
import 'run_states/settings_state.dart';
import 'run_states/view_state.dart';

class PlayState extends State {
  final Element playCard = querySelector('#play-card');

  final ButtonElement buildBtn = querySelector('#build-btn');
  final ButtonElement saveBtn = querySelector('#save-btn');

  // file buttons
  final Element newTankBtn = querySelector('#new-tank-btn');
  final Element openBtn = querySelector('#open-btn');
  final Element makeCopyBtn = querySelector('#make-a-copy-btn');
  final Element renameBtn = querySelector('#rename-btn');
  final Element saveAsBtn = querySelector('#save-as-btn');
  final Element deleteBtn = querySelector('#delete-btn');
  final Element closeFileBtn = querySelector('#close-file-btn');

  final Element tabContainer = querySelector('#tab-container');

  final Element editorElement = querySelector('#editor');
  final Element logOutput = querySelector('#log-output');
  final InputElement newTankName = querySelector('#new-tank-name');

  final options = <String, String>{'mode': 'javascript', 'theme': 'monokai'};

  CodeMirror editor;

  StreamSubscription buildBtnSub;

  String currentTankName;

  PlayState(ClientWebSocket client, StateManager sm) : super(client, sm) {
    client //
      ..on('log', onLogData)
      ..on('build_done', onBuildDone);

    editor = CodeMirror.fromElement(editorElement, options: options);
    editor
      ..setLineNumbers(true)
      ..setReadOnly(true);

    final runStateManager = StateManager();
    runStateManager
      ..addAll({
        'landing': LandingState(client, runStateManager),
        'settings': SettingsState(client, runStateManager),
        'view': ViewState(client, runStateManager),
      })
      ..pushState('landing');

    final fileStateManager = StateManager();
    fileStateManager
      ..addAll({
        'new-tank': NewTankState(client, fileStateManager),
        'open-existing': OpenExistingTankState(client, stateManager),
      });

    newTankBtn.onClick.listen((e) {
      fileStateManager.pushState('new-tank');
      e.stopImmediatePropagation();
      e.stopPropagation();
    });

    openBtn.onClick.listen((e) {
      fileStateManager.pushState('open-existing');
      e.stopImmediatePropagation();
      e.stopPropagation();
    });

    Element currentTab;

    final tankNameToCode = <String, String>{};

    client
      ..on('open_existing_tank_success', (data) {
        // final code = data['code'];
        tankNameToCode[data['tank_name']] = data['code'];

        fileStateManager.currentState?.hide();

        saveBtn.disabled = false;
        buildBtn.disabled = false;

        final tab = Element.html('<div class="tab selected-tab">${data['tank_name']}</div>');
        tab.onClick.listen((_) {
          if (currentTab != tab) {
            if (currentTankName != null) {
              tankNameToCode[currentTankName] = editor.getDoc().getValue();
            }

            currentTab?.classes?.remove('selected-tab');

            currentTab = tab;
            currentTab.classes.add('selected-tab');

            currentTankName = data['tank_name'];

            final code = tankNameToCode[currentTankName];

            editor
              ..getDoc().setValue(code)
              ..setReadOnly(false)
              ..focus()
              ..refresh();            
          }
        });
        tabContainer.children.add(tab);
        tab.click();
      })
      ..on('open_existing_tank_failure', (data) {
        print('open_existing_tank_failure');
      });

    saveBtn.onClick.listen((_) {
      saveBtn.disabled = true;

      final code = editor.getDoc().getValue();

      final msg = {'code': code, 'tank_name': currentTankName};

      client.send('save_tank', msg);

      Timer(const Duration(seconds: 1), () {
        saveBtn.disabled = false;
      });
    });

    makeCopyBtn.onClick.listen((e) {});
  }

  void onBuildDone(data) {
    // TODO validate data

    final success = data['success'];

    buildBtn.disabled = false;
  }

  // void onRunGameResponse(data) {
  //   // TODO validate data
  //   print('received frames');
  //   print(data);

  //   runBtn.disabled = false;

  //   buildBtn.disabled = false;
  // }

  void onLogData(data) {
    // TODO validate data

    final line = data['line'];

    final lineElement = Element.html('<div class="log">$line</div>');

    // TODO formatted logs
    logOutput
      ..children.add(lineElement)
      ..scrollTop = logOutput.scrollHeight;
  }

  @override
  void show() {
    playCard.style.display = 'flex';

    buildBtnSub = buildBtn.onClick.listen((event) {
      if (buildBtn.disabled || currentTankName == null) {
        return;
      }
      final code = editor.getDoc().getValue();

      final msg = {'code': code, 'tank_name': currentTankName};

      client.send('build_code', msg);

      buildBtn.disabled = true;
    });

    // editor.focus();
    // editor.refresh();
  }

  @override
  void hide() {
    playCard.style.display = 'none';

    buildBtnSub?.cancel();
  }
}
