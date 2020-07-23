import '../components/collision/physics_component.dart';
import '../components/game_command/game_commands_component.dart';

import '../components/socket_component.dart';

import '../../../../code_tanks_entity_component_system.dart';
import 'mixins/handles_game_commands_response.dart';

class RunGameCommandSystem extends System with HandlesGameCommandsResponse {
  RunGameCommandSystem() : super({GameCommandsComponent, SocketComponent, PhysicsComponent});

  @override
  Future<void> process(Entity entity) async {
    SocketComponent socketComponent = entity.getComponent(SocketComponent);
    GameCommandsComponent gameCommandsComponent = entity.getComponent(GameCommandsComponent);

    // request update if entity has no commands
    if (gameCommandsComponent.commandQueue.isEmpty) {
      // TODO deal with timeout
      final updateDone = socketComponent.socket
          .onSingleAsync('run_game_commands_response', (data) => onGameCommandsResponse(data, entity));
      socketComponent.socket.send('run_game_commands_request');
      // print('sent run_game_commands_request');
      // print(socketComponent.socket);
      // socketComponent.socket.send('derp');
      await updateDone;
    }
  }

}