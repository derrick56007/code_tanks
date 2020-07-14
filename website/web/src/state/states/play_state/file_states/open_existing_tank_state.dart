import 'dart:html';

import '../../../../client_web_socket/client_websocket.dart';
import '../../../state.dart';
import '../../../state_manager.dart';

class OpenExistingTankState extends State {
  final Element openExistingTankState = querySelector('#open-existing-tank-state');

  final Element cancelOpenExistingTank = querySelector('#cancel-open-existing-tank-btn');
  final ButtonElement submitOpenExistingTank = querySelector('#submit-open-existing-tank-btn');

  final Element existingTanks = querySelector('#existing-tanks');

  OpenExistingTankState(ClientWebSocket client, StateManager stateManager) : super(client, stateManager) {
    cancelOpenExistingTank.onClick.listen((_) {
      hide();
    });

    Element selected;
    String selectedTankName;

    submitOpenExistingTank.onClick.listen((_) {
      if (selected != null) {
        final msg = {
          'tank_name': selectedTankName,
        };

        client.send('open_existing_tank', msg);
      }
    });

    client.on('saved_tanks', (data) {
      final savedTanks = data['saved_tanks'];

      existingTanks.children.clear();
      submitOpenExistingTank.disabled = true;

      for (final tankName in savedTanks) {
        final el = Element.html('<div class="selectable">$tankName</div>');

        el.onClick.listen((_) {
          selected?.classes?.remove('selected-tank');

          if (selected != el) {
            selected = el;
            selectedTankName = tankName;
            selected.classes.add('selected-tank');
            submitOpenExistingTank.disabled = false;
          } else {
            selected = null;
            selectedTankName = null;
            submitOpenExistingTank.disabled = true;
          }
        });

        existingTanks.children.add(el);
      }
    });
  }

  @override
  void hide() {
    openExistingTankState.style.display = 'none';
  }

  @override
  void show() {
    openExistingTankState.style.display = '';

    client.send('get_saved_tanks');
  }
}
