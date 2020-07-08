import 'package:code_tanks/code_tanks_entity_component_system.dart';
import '../components/player_event_component.dart';
import '../components/velocity_component.dart';

class ApplyPlayerCommandSystem extends System {
  ApplyPlayerCommandSystem() : super({PlayerEventComponent, VelocityComponent});

  @override
  Future<void> process(Entity entity) async {
    PlayerEventComponent pComp = entity.getComponent(PlayerEventComponent);

    final commands = pComp.commandQueue.popNextCommands();
    print('popped $commands');

    return;
  }
  
}