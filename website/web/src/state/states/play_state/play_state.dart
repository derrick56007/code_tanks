import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:codemirror/codemirror.dart';

import '../../../client.dart';
import '../../../client_web_socket/client_websocket.dart';
import '../../state.dart';
import 'file_states/delete_confirmation_state.dart';
import 'file_states/new_tank_state.dart';
import 'file_states/open_existing_tank_state.dart';
import 'file_states/rename_state.dart';
import 'file_states/save_tank_as_state.dart';
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

  final ButtonElement submitSaveAsTankBtn = querySelector('#submit-save-as-tank-btn');

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
      ..setLineNumbers(false)
      ..setReadOnly(true)
      ..refresh();

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
        'open-existing': OpenExistingTankState(client, fileStateManager),
        'save-as-tank': SaveTankAsState(client, fileStateManager),
        'delete-confirmation': DeleteConfirmationState(client, fileStateManager),
        'rename': RenameState(client, fileStateManager),
      });

    newTankBtn.onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();
      fileStateManager.pushState('new-tank');
    });

    openBtn.onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      client.send('get_saved_tanks');

      fileStateManager.pushState('open-existing');
    });

    Element currentTab;

    void closeTab(Element tabToClose) {
      final idx = tabContainer.children.indexOf(tabToClose);
      tabToClose.remove();

      if (tabContainer.children.isNotEmpty) {
        final prevIdx = max(idx - 1, 0);
        tabContainer.children[prevIdx].click();
      } else {
        editor
          ..getDoc().setValue('')
          ..setLineNumbers(false)
          ..setReadOnly(true)
          ..focus()
          ..refresh();

        editorElement.click();

        currentTab = null;
        currentTankName = null;

        saveBtn.disabled = true;
        buildBtn.disabled = true;
      }
    }

    final tankNameToCode = <String, String>{};

    client
      ..on('open_existing_tank_success', (data) {
        // final code = data['code'];
        tankNameToCode[data['tank_name']] = data['code'];

        fileStateManager.currentState?.hide();

        saveBtn.disabled = false;
        buildBtn.disabled = false;

        final tab = Element.html('''
          <div class="tab selected-tab">
            <div>${data['tank_name']}</div>
            <i id="close-tab-btn" class="material-icons mdc-button__icon tab-icon">
              close
            </i>
          </div>
        ''');
        tab.querySelector('#close-tab-btn').onClick.listen((e) {
          e.stopImmediatePropagation();
          e.stopPropagation();
          closeTab(tab);
        });

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
              ..setLineNumbers(true)
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

    makeCopyBtn.onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (currentTankName != null) {
        final msg = {'tank_name': currentTankName};

        print(msg);

        client.send('make_tank_copy', msg);
      }
    });

    submitSaveAsTankBtn.onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      final InputElement saveAsTankName = querySelector('#save-as-tank-name');

      if (currentTankName != null) {
        final msg = {
          'tank_name': currentTankName,
          'new_tank_name': saveAsTankName.value.trim(),
        };

        client.send('save_tank_as', msg);
      }
    });

    saveAsBtn.onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (currentTankName == null) {
        return;
      }

      fileStateManager.pushState('save-as-tank');
    });

    closeFileBtn.onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (currentTab != null) {
        closeTab(currentTab);
      }
    });

    deleteBtn.onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (currentTab != null) {
        querySelector('#delete-confirmation-tank-name').text = currentTankName;
        fileStateManager.pushState('delete-confirmation');
      }
    });

    querySelector('#submit-delete-confirmation-tank-btn').onClick.listen((_) {
      final tankToDelete = currentTankName;
      closeTab(currentTab);

      client.send('delete_tank', {'tank_name': tankToDelete});

      fileStateManager.currentState?.hide();
    });

    final InputElement renameTankName = querySelector('#rename-tank-name');
    Element tabToRename;
    String tankToRename;

    renameBtn.onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (currentTab != null) {
        tankToRename = currentTankName;
        tabToRename = currentTab;
        renameTankName.value = currentTankName;

        fileStateManager.pushState('rename');
      }
    });

    final ButtonElement submitRenameTankBtn = querySelector('#submit-rename-tank-btn');

    submitRenameTankBtn.onClick.listen((_) {

      if (tankToRename != null) {
        client.send('rename_tank', {
          'tank_name': tankToRename,
          'new_tank_name': renameTankName.value.trim(),
        });

        closeTab(tabToRename);
        tabToRename = null;
        tankToRename = null;

        fileStateManager.currentState?.hide();
      }
    });

    querySelectorAll('.modal-backdrop').onClick.listen((_) {
        fileStateManager.currentState?.hide();
    });
  }

  void onBuildDone(data) {
    // final success = data['success'];

    buildBtn.disabled = false;
  }

  void onLogData(data) {
    final line = data['line'];

    final lineElement = Element.html('<div class="log">$line</div>');

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
  }
 
  @override
  void hide() {
    playCard.style.display = 'none';

    buildBtnSub?.cancel();
  }
}
