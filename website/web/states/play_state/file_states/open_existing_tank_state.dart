import 'dart:html';

import 'package:code_tanks/code_tanks_client.dart';

class OpenExistingTankState extends State {
  OpenExistingTankState(ClientWebSocket client, StateManager stateManager)
      : super(client, stateManager, querySelector('#open-existing-tank-state')) {
    querySelector('#cancel-open-existing-tank-btn').onClick.listen((_) {
      hide();
    });

    final ButtonElement submitOpenExistingTank = querySelector('#submit-open-existing-tank-btn');
    final existingTanksSelectList = SelectList(querySelector('#existing-tanks'), 'selected-tank', true);

    existingTanksSelectList.onChange = (prev) {
      submitOpenExistingTank.disabled = existingTanksSelectList.elementNotSelected;
    };

    submitOpenExistingTank.onClick.listen((_) {
      if (existingTanksSelectList.elementNotSelected) return;

      client.send('open_existing_tank', {
        'tank_name': existingTanksSelectList.selected.text,
      });
    });

    client.on('saved_tanks', (data) {
      final savedTanks = data['saved_tanks'];

      existingTanksSelectList.clear();
      submitOpenExistingTank.disabled = true;

      for (final tankName in savedTanks) {
        existingTanksSelectList.addSelectableWithHtml('<div class="selectable">$tankName</div>');
      }
    });
  }

  @override
  void hide() {
    stateElement.style.display = 'none';
  }

  @override
  void show() {
    stateElement
      ..style.display = ''
      ..click();
  }
}
