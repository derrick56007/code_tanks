import '../components/collision/physics_component.dart';
import '../components/game_command/game_commands_component.dart';
import '../components/game_event/game_event_component.dart';
import '../components/socket_component.dart';

import '../../../../code_tanks_entity_component_system.dart';
import 'mixins/handles_game_commands_response.dart';

class GameEventSystem extends System with HandlesGameCommandsResponse {
  GameEventSystem() : super({GameEventComponent, GameCommandsComponent, SocketComponent, PhysicsComponent});

  @override
  Future<void> process(Entity entity) async {
    SocketComponent socketComponent = entity.getComponent(SocketComponent);
    GameEventComponent gameEventComponent = entity.getComponent(GameEventComponent);

    for (final gameEvent in gameEventComponent.gameEvents) {
    // // TODO deal with timeout

      final updateDone =
          socketComponent.socket.onSingleAsync('event_commands_response', (data) => onGameCommandsResponse(data, entity));
      socketComponent.socket.send('event_commands_request', gameEvent.toJson());
      await updateDone;
    }

  }
}
