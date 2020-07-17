import 'dart:async';
import 'dart:html';

import 'package:code_tanks/code_tanks_client.dart';
import 'package:codemirror/codemirror.dart';

import 'file_states/delete_confirmation_state.dart';
import 'file_states/new_tank_state.dart';
import 'file_states/open_existing_tank_state.dart';
import 'file_states/rename_state.dart';
import 'file_states/save_tank_as_state.dart';

import 'run_states/landing_state.dart';
import 'run_states/settings_state.dart';
import 'run_states/view_state.dart';

class PlayState extends State {
  final ButtonElement buildBtn = querySelector('#build-btn');
  final ButtonElement saveBtn = querySelector('#save-btn');

  final Element editorElement = querySelector('#editor');

  final options = <String, String>{'mode': 'javascript', 'theme': 'monokai'};

  CodeMirror editor;

  PlayState(ClientWebSocket client, StateManager sm) : super(client, sm, querySelector('#play-card')) {
    editor = CodeMirror.fromElement(editorElement, options: options)
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

    querySelector('#new-tank-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();
      fileStateManager.pushState('new-tank');
    });

    querySelector('#open-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      client.send('get_saved_tanks');

      fileStateManager.pushState('open-existing');
    });

    final tankNameToCode = <String, String>{};

    final tabSelectList = SelectList(querySelector('#tab-container'), 'selected-tab', false);
    tabSelectList.onChange = (prev) {
      if (prev != null) {
        tankNameToCode[prev.id] = editor.getDoc().getValue();
      }

      if (tabSelectList.elementNotSelected) {
        editor
          ..getDoc().setValue('')
          ..setLineNumbers(false)
          ..setReadOnly(true);
      } else {
        final code = tankNameToCode[tabSelectList.selected.id];

        editor
          ..getDoc().setValue(code)
          ..setLineNumbers(true)
          ..setReadOnly(false);
      }

      editor
        ..focus()
        ..refresh();
    };

    client
      ..on('log', onLogData)
      ..on('build_done', onBuildDone)
      ..on('open_existing_tank_success', (data) {
        tankNameToCode[data['tank_name']] = data['code'];

        fileStateManager.currentState?.hide();

        saveBtn.disabled = false;
        buildBtn.disabled = false;

        final tab = tabSelectList.addSelectableWithHtml('''
          <div id="${data['tank_name']}" class="tab selected-tab">
            <div>${data['tank_name']}</div>
            <i id="close-tab-btn" class="material-icons mdc-button__icon tab-icon">
              close
            </i>
          </div>
        ''');
        tab.querySelector('#close-tab-btn').onClick.listen((e) {
          e.stopImmediatePropagation();
          e.stopPropagation();
          tabSelectList.remove(tab, selectPrevious: true);
        });
        tab.click();
      })
      ..on('open_existing_tank_failure', (data) {
        print('open_existing_tank_failure');
      });

    saveBtn.onClick.listen((_) {
      saveBtn.disabled = true;

      final code = editor.getDoc().getValue();

      client.send('save_tank', {
        'code': code,
        'tank_name': tabSelectList.selected.id,
      });

      Timer(const Duration(seconds: 1), () {
        saveBtn.disabled = false;
      });
    });

    querySelector('#make-a-copy-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (tabSelectList.elementNotSelected) return;

      client.send('make_tank_copy', {
        'tank_name': tabSelectList.selected.text,
      });
    });

    querySelector('#submit-save-as-tank-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      final InputElement saveAsTankName = querySelector('#save-as-tank-name');

      if (tabSelectList.elementNotSelected) return;

      client.send('save_tank_as', {
        'tank_name': tabSelectList.selected.text,
        'new_tank_name': saveAsTankName.value.trim(),
      });
    });

    querySelector('#save-as-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (tabSelectList.elementNotSelected) return;

      fileStateManager.pushState('save-as-tank');
    });

    querySelector('#close-file-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (tabSelectList.elementNotSelected) return;
      tabSelectList.removeSelected(selectPrevious: true);
    });

    querySelector('#delete-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (tabSelectList.elementNotSelected) return;
      querySelector('#delete-confirmation-tank-name').text = tabSelectList.selected.text;
      fileStateManager.pushState('delete-confirmation');
    });

    querySelector('#submit-delete-confirmation-tank-btn').onClick.listen((_) {
      final tankToDelete = tabSelectList.selected.text;
      tabSelectList.removeSelected(selectPrevious: true);

      client.send('delete_tank', {'tank_name': tankToDelete});

      fileStateManager.currentState?.hide();
    });

    final InputElement renameTankName = querySelector('#rename-tank-name');

    querySelector('#rename-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (tabSelectList.elementNotSelected) return;

      renameTankName.value = tabSelectList.selected.text;

      fileStateManager.pushState('rename');
    });

    querySelector('#submit-rename-tank-btn').onClick.listen((_) {
      if (tabSelectList.elementNotSelected) return;
      client.send('rename_tank', {
        'tank_name': tabSelectList.selected.text,
        'new_tank_name': renameTankName.value.trim(),
      });

      tabSelectList.removeSelected(selectPrevious: true);

      fileStateManager.currentState?.hide();
    });

    querySelectorAll('.modal-backdrop').onClick.listen((_) {
      fileStateManager.currentState?.hide();
    });

    buildBtn.onClick.listen((event) {
      if (tabSelectList.elementNotSelected) return;

      client.send('build_code', {
        'code': editor.getDoc().getValue(),
        'tank_name': tabSelectList.selected.text,
      });

      buildBtn.disabled = true;
    });
  }

  void onBuildDone(data) {
    // final success = data['success'];

    buildBtn.disabled = false;
  }

  void onLogData(data) {
    final line = data['line'];

    final lineElement = Element.html('<div class="log">$line</div>');

    final logOutput = querySelector('#log-output');

    logOutput
      ..children.add(lineElement)
      ..scrollTop = logOutput.scrollHeight;
  }

  @override
  void show() {
    stateElement.style.display = 'flex';
  }

  @override
  void hide() {
    stateElement.style.display = 'none';
  }
}
