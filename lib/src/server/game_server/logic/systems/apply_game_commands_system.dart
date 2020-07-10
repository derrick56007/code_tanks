import 'package:code_tanks/code_tanks_entity_component_system.dart';
import 'package:code_tanks/src/server/game_server/logic/components/collision/physics_component.dart';
import 'package:code_tanks/src/server/game_server/logic/components/game_command/game_commands_component.dart';

class ApplyGameCommandSystem extends System {
  ApplyGameCommandSystem() : super({GameCommandsComponent, PhysicsComponent});

  @override
  Future<void> process(Entity entity) async {
    GameCommandsComponent pComp = entity.getComponent(GameCommandsComponent);

    final commands = pComp.commandQueue.popNextCommands();
    // print('popped $commands');

    return;
  }
  
}