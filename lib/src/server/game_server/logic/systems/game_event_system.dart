import 'package:code_tanks/src/server/game_server/logic/components/game_command/game_commands_component.dart';
import 'package:code_tanks/src/server/game_server/logic/components/game_event/game_event_component.dart';
import 'package:code_tanks/src/server/game_server/logic/components/socket_component.dart';

import '../../../../../code_tanks_entity_component_system.dart';
import 'mixins/handles_game_commands_response.dart';

class GameEventSystem extends System with HandlesGameCommandsResponse {
  GameEventSystem() : super({GameEventComponent, GameCommandsComponent, SocketComponent});

  @override
  Future<void> process(Entity entity) async {
    // SocketComponent socketComponent = entity.getComponent(SocketComponent);

    // // TODO deal with timeout

    // final updateDone = socketComponent.socket
    //     .onSingleAsync('event_commands_response', (data) => onGameCommandsResponse(data, entity));
    // socketComponent.socket.send('event_commands_request');
    // await updateDone;
  }
  
}