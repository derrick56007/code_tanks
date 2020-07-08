import 'package:code_tanks/src/server/game_server/logic/commands/game_command.dart';
import 'package:code_tanks/src/server/game_server/logic/components/player_event_component.dart';
import 'package:code_tanks/src/server/game_server/logic/components/socket_component.dart';

import '../../../../../code_tanks_entity_component_system.dart';

class PlayerEventSystem extends System {
  PlayerEventSystem() : super({PlayerEventComponent, SocketComponent});

  @override
  Future<void> process(Entity entity) async {
    SocketComponent socketComponent = entity.getComponent(SocketComponent);
    PlayerEventComponent playerEventComponent = entity.getComponent(PlayerEventComponent);

    // request update if entity has no commands
    if (playerEventComponent.commandQueue.isEmpty) {
      // TODO deal with timeout
      final updateDone = socketComponent.socket
          .onSingleAsync('update_response', (data) => onUpdateResponse(data, playerEventComponent));
      socketComponent.socket.send('update_request');
      await updateDone;
    }

    return;
  }

  void onUpdateResponse(dynamic data, PlayerEventComponent playerEventComponent) {
    print('received update response');
    // TODO validate data

    // TODO validate commands from universal api
    final commands = data['commands'];

    var count = 0;
    for (final command in commands) {
      final commandType = command['command_type'];
      final commandArg = command['command_arg'];

      // TODO catch errors

      final generatedCommands = GameCommand.fromStringWithVal(commandType, commandArg);
      count += generatedCommands.length;
      playerEventComponent.commandQueue.addAllCommands(generatedCommands);
    }

    print('processed $count');
  }
}