import 'dart:html';

import '../../select_list.dart';
import '../state.dart';

class SettingsState extends State {
  SettingsState() : super(querySelector('#settings-state'));

  @override
  void hide() {
    stateElement.style.display = 'none';
  }

  @override
  void show() async {
    stateElement.style.display = 'flex';

    client.send('get_built_tanks');
  }

  @override
  void init() {
    final ButtonElement startBtn = querySelector('#start-btn');

    final builtTanksSelectList = SelectList(querySelector('#settings-left-pane'), 'selected-tank', true);
    final tanksToRunSelectList = SelectList(querySelector('#settings-right-pane'), 'selected-tank', true);
    tanksToRunSelectList.onChange = (_) {
      startBtn.disabled = tanksToRunSelectList.length <= 1;
    };

    client.on('built_tanks', (data) {
      print('received built tanks $data');

      builtTanksSelectList.clear();
      tanksToRunSelectList.clear();

      final tankNames = data['built_tanks'];

      for (final tankName in tankNames) {
        builtTanksSelectList.addSelectableWithHtml('<div class="selectable">$tankName</div>');
      }
    });

    querySelector('#add-btn').onClick.listen((_) {
      if (builtTanksSelectList.elementNotSelected) return;

      tanksToRunSelectList.addSelectableWithHtml('<div class="selectable">${builtTanksSelectList.selected.text}</div>');
    });

    querySelector('#remove-btn').onClick.listen((_) {
      if (tanksToRunSelectList.elementNotSelected) return;

      tanksToRunSelectList.removeSelected(selectPrevious: true);
    });

    querySelector('#cancel-btn').onClick.listen((_) => stateManager.pushState('landing'));

    startBtn.onClick.listen((_) {
      final tankNames = tanksToRunSelectList.parentListElement.children.map((e) => e.text).toList(growable: false);

      // TODO think about hard limit of num of tanks
      if (tankNames.length > 1 && tankNames.length < 10) {
        client.send('run_game', {
          'tank_names': tankNames,
        });

        stateManager.pushState('loading');
      }
    });
  }
}
