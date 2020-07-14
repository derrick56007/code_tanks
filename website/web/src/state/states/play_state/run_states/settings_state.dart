import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:web_gl';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class SettingsState extends State {
  final Element settingsDiv = querySelector('#settings-state');
  final ButtonElement cancelBtn = querySelector('#cancel-btn');
  final ButtonElement startBtn = querySelector('#start-btn');
  final Element settingsLeftPane = querySelector('#settings-left-pane');
  final Element settingsRightPane = querySelector('#settings-right-pane');

  final ButtonElement addBtn = querySelector('#add-btn');
  final ButtonElement removeBtn = querySelector('#remove-btn');

  StreamSubscription cancelBtnSub;
  StreamSubscription startBtnSub;
  StreamSubscription addBtnSub;
  StreamSubscription removeBtnSub;

  SettingsState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager);

  @override
  void hide() {
    settingsDiv.style.display = 'none';

    cancelBtnSub?.cancel();
    startBtnSub?.cancel();
    addBtnSub?.cancel();
    removeBtnSub?.cancel();
  }

  @override
  void show() async {
    client.send('get_built_tanks');

    await client.onSingleAsync('built_tanks', (data) {
      print('received built tanks $data');

      settingsLeftPane.children.clear();
      settingsRightPane.children.clear();

      // TODO validate data
      final tankNames = data['built_tanks'];

      Element addSelected;
      String addSelectedName;

      for (final name in tankNames) {
        final el = Element.html('<div class="selectable">$name</div>');

        el.onClick.listen((event) {
          addSelected?.classes?.remove('selected-tank');

          if (addSelected != el) {
            addSelected = el;
            addSelectedName = name;
            addSelected.classes.add('selected-tank');
          } else {
            addSelected = null;
          }
        });

        settingsLeftPane.children.add(el);
      }

      Element removeSelected;

      addBtnSub = addBtn.onClick.listen((_) {
        if (addSelected != null) {
          final el = Element.html('<div>$addSelectedName</div>');

          el.onClick.listen((_) {
            removeSelected?.classes?.remove('selected-tank');

            if (removeSelected != el) {
              removeSelected = el;
              removeSelected.classes.add('selected-tank');
            } else {
              removeSelected = null;
            }
          });

          settingsRightPane.children.add(el);
        }
      });

      removeBtnSub = removeBtn.onClick.listen((_) {
        if (removeSelected != null) {
          final idx = settingsRightPane.children.indexOf(removeSelected);

          settingsRightPane.children.remove(removeSelected);
          removeSelected = null;

          if (settingsRightPane.children.isNotEmpty) {
            final prevIdx = max(idx - 1, 0);

            settingsRightPane.children[prevIdx].click();
          }
        }
      });
    });

    settingsDiv.style.display = 'flex';

    cancelBtnSub = cancelBtn.onClick.listen((_) {
      stateManager.pushState('landing');
    });

    startBtnSub = startBtn.onClick.listen((_) {
      final tankNames = settingsRightPane.children.map((e) => e.text).toList(growable: false);

      // TODO think about hard limit of num of tanks
      if (tankNames.length > 1 && tankNames.length < 10) {
        final msg = {
          'tank_names': tankNames
        };

        print(msg);

        client.send('run_game', msg);

        stateManager.pushState('view');
      }
    });
  }
}
