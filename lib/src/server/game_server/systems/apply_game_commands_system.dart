import '../../../../code_tanks_entity_component_system.dart';

import '../components/collision/physics_component.dart';
import '../components/game_command/game_command_name.dart';
import '../components/game_command/game_commands_component.dart';
import '../components/tank_utilities_component.dart';

class ApplyGameCommandSystem extends System {
  ApplyGameCommandSystem() : super({GameCommandsComponent, PhysicsComponent, TankUtilitiesComponent});

  @override
  Future<void> process(Entity entity) async {
    GameCommandsComponent gameCommandsComp = entity.getComponent(GameCommandsComponent);
    PhysicsComponent physComp = entity.getComponent(PhysicsComponent);
    TankUtilitiesComponent tankComp = entity.getComponent(TankUtilitiesComponent);

    for (final command in gameCommandsComp.commandQueue.popNextCommands()) {
      // TODO calculate proper velocities
      switch (command.name) {
        case GameCommandName.aheadBy:
          physComp.velocity = command.val;
          break;
        case GameCommandName.backBy:
          physComp.velocity = command.val;
          break;
        case GameCommandName.rotateTankBy:
          physComp.angularVelocity = command.val;
          break;
        case GameCommandName.rotateGunBy:
          tankComp.gunAngularVelocity = command.val;
          break;
        case GameCommandName.rotateRadarBy:
          tankComp.radarAngularVelocity = command.val;
          break;          
        case GameCommandName.setRadarToRotateWithGun:
          tankComp.radarRotatesWithGun = command.val;
          break;
        case GameCommandName.setGunToRotateWithTank:
          tankComp.gunRotatesWithTank = command.val;
          break;
        case GameCommandName.fireWithPower:
          // TODO
          break;
        case GameCommandName.requestInfo:
          // TODO
          break;
        default:
          throw UnimplementedError('no implementation for command $command');
      }
    }

    return;
  }
}
