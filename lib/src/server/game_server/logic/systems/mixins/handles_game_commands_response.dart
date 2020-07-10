
import 'package:code_tanks/src/server/game_server/logic/components/game_command/game_command.dart';
import 'package:code_tanks/src/server/game_server/logic/components/game_command/game_commands_component.dart';

import '../../../../../../code_tanks_entity_component_system.dart';

mixin HandlesGameCommandsResponse on System {

  void onGameCommandsResponse(dynamic data, Entity entity) {
    // print('received update response');
    // TODO validate data

    // TODO validate commands from universal api
    final commands = data['commands'];

    GameCommandsComponent gameCommandsComponent = entity.getComponent(GameCommandsComponent);

    // var count = 0;
    const initialDepth = 0;
    var depth = initialDepth;
    if (gameCommandsComponent.commandQueue.isNotEmpty) {
      depth = gameCommandsComponent.commandQueue.peekNextCommands().first.commandDepth + 1;
    }

    for (final command in commands.reversed) {
      final commandType = command['command_type'];
      final commandArg = command['command_arg'];

      // TODO catch errors

      final generatedCommands = GameCommand.commandsfromStringWithVal(commandType, commandArg);
      for (final generatedCommand in generatedCommands) {
        generatedCommand.commandDepth = depth;
      }

      // count += generatedCommands.length;
      
      gameCommandsComponent.commandQueue.addAllCommands(generatedCommands);
    }

    // print('processed $count');
  }
}