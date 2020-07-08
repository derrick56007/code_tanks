import 'package:code_tanks/src/server/game_server/logic/components/position_component.dart';
import 'package:code_tanks/src/server/game_server/logic/components/velocity_component.dart';

import '../../../../../code_tanks_entity_component_system.dart';

class PhysicsSystem extends System {
  PhysicsSystem() : super({PositionComponent, VelocityComponent});

  @override
  Future<void> process(Entity entity) async {
    return;
  }
  
}