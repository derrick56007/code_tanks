import 'dart:async';
import 'dart:html';

import '../../select_list.dart';
import '../state.dart';
import 'package:codemirror/codemirror.dart';

import '../file_states/delete_confirmation_state.dart';
import '../file_states/new_tank_state.dart';
import '../file_states/open_existing_tank_state.dart';
import '../file_states/rename_state.dart';
import '../file_states/save_tank_as_state.dart';

import '../run_states/landing_state.dart';
import '../run_states/loading_state.dart';
import '../run_states/settings_state.dart';
import '../run_states/view_state.dart';
import '../state_manager.dart';

class PlayState extends State {
  final ButtonElement buildBtn = querySelector('#build-btn');
  final ButtonElement saveBtn = querySelector('#save-btn');

  final options = <String, String>{
    'mode': 'javascript',
    'theme': 'monokai',
  };

  PlayState() : super(querySelector('#play-card'));

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

  @override
  void init() {
    final editor = CodeMirror.fromElement(querySelector('#editor'), options: options)
      ..setLineNumbers(false)
      ..setReadOnly(true)
      ..refresh();

    StateManager(client)
      ..addStatesAndSetFields({
        'landing': LandingState(),
        'settings': SettingsState(),
        'loading': LoadingState(),
        'view': ViewState(),
      })
      ..pushState('landing');

    final fileStateManager = StateManager(client)
      ..addStatesAndSetFields({
        'new-tank': NewTankState(),
        'open-existing': OpenExistingTankState(),
        'save-as-tank': SaveTankAsState(),
        'delete-confirmation': DeleteConfirmationState(),
        'rename': RenameState(),
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
        // save content of previous tab for later
        tankNameToCode[prev.id] = editor.getDoc().getValue();
      }

      if (tabSelectList.elementNotSelected) {
        editor
          ..getDoc().setValue('')
          ..setLineNumbers(false)
          ..setReadOnly(true);
      } else {
        // load the contents of particular tab
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
        tab
          ..querySelector('#close-tab-btn').onClick.listen((e) {
            e.stopImmediatePropagation();
            e.stopPropagation();
            tabSelectList.remove(tab, selectPrevious: true);
          })
          ..click();
      })
      ..on('open_existing_tank_failure', (data) {
        print('open_existing_tank_failure');
      });

    saveBtn.onClick.listen((_) {
      saveBtn.disabled = true;

      client.send('save_tank', {
        'code': editor.getDoc().getValue(),
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
        'tank_name': tabSelectList.selected.id,
      });
    });

    querySelector('#submit-save-as-tank-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      final InputElement saveAsTankName = querySelector('#save-as-tank-name');

      if (tabSelectList.elementNotSelected) return;

      client.send('save_tank_as', {
        'tank_name': tabSelectList.selected.id,
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
      querySelector('#delete-confirmation-tank-name').text = tabSelectList.selected.id;
      fileStateManager.pushState('delete-confirmation');
    });

    querySelector('#submit-delete-confirmation-tank-btn').onClick.listen((_) {
      final tankToDelete = tabSelectList.selected.id;
      tabSelectList.removeSelected(selectPrevious: true);

      client.send('delete_tank', {'tank_name': tankToDelete});

      fileStateManager.currentState?.hide();
    });

    final InputElement renameTankName = querySelector('#rename-tank-name');

    querySelector('#rename-btn').onClick.listen((e) {
      e.stopImmediatePropagation();
      e.stopPropagation();

      if (tabSelectList.elementNotSelected) return;

      renameTankName.value = tabSelectList.selected.id;

      fileStateManager.pushState('rename');
    });

    querySelector('#submit-rename-tank-btn').onClick.listen((_) {
      if (tabSelectList.elementNotSelected) return;
      client.send('rename_tank', {
        'tank_name': tabSelectList.selected.id,
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
        'tank_name': tabSelectList.selected.id,
      });

      buildBtn.disabled = true;
    });
  }
}
