import 'package:code_tanks/code_tanks_common.dart';
import 'package:code_tanks/src/server/game_server/components/collision/collider_component.dart';

import '../../../code_tanks_entity_component_system.dart';

import 'components/collision/health_component.dart';
import 'components/collision/vector_2d.dart';
import 'components/game_command/game_commands_component.dart';
import 'components/game_event/game_event_component.dart';
import 'components/render_component.dart';
import 'components/scanner_component.dart';
import 'components/socket_component.dart';
import 'components/collision/physics_component.dart';

import 'components/tank_utilities_component.dart';
import 'systems/apply_game_commands_system.dart';
import 'systems/game_event_system.dart';
import 'systems/run_game_command_system.dart';
import 'systems/render_system.dart';
import 'systems/physics_system.dart';
import 'systems/scanner_system.dart';
import '../../common/render_type.dart';

class Game {
  final String id;

  final gameKeyToEntityId = <String, int>{};

  final world = World();

  final gameKeysAdded = <String>{};

  Game(this.id, List<String> gameKeys) {
    gameKeys.forEach(initializeTank);

    world
      ..addSystem(RenderSystem())
      ..addSystem(RunGameCommandSystem())
      ..addSystem(ApplyGameCommandSystem())
      ..addSystem(PhysicsSystem())      
      ..addSystem(ScannerSystem())
      ..addSystem(GameEventSystem());
  }

  int count = 1;

  void initializeTank(String gameKey) {
    // TODO randomize position
    final position = Vector2D()..features[0] = count * 10;
    final tankRect = CTRect(10, 10);

    count++;

    final entity = world.createEntity()
      ..addComponent(RenderComponent(RenderType.tank))
      ..addComponent(HealthComponent())
      ..addComponent(PhysicsComponent(position))
      ..addComponent(ColliderComponent(tankRect))
      ..addComponent(GameCommandsComponent())
      ..addComponent(ScannerComponent())
      ..addComponent(GameEventComponent())
      ..addComponent(TankUtilitiesComponent());

    gameKeyToEntityId[gameKey] = entity.id;
  }

  void onTankDisconnect(String gameKey) {}

  void addTank(String gameKey, CommonWebSocket socket) {
    if (!isValidGameKey(gameKey)) {
      print('error adding tank');
      return;
    }

    gameKeysAdded.add(gameKey);

    world.idToEntity[gameKeyToEntityId[gameKey]].addComponent(SocketComponent(socket));

    print('added tank');
  }

  bool allTanksInGame() => gameKeysAdded.length == gameKeyToEntityId.length;

  bool isValidGameKey(String gameKey) => gameKeyToEntityId.containsKey(gameKey);

  Future<void> runSimulation() async {
    print('started simulation');

    for (var i = 0; i < 1000; i++) {
      print('update $i');
      await world.updateAsync();
    }

    print('finished simulation');
  }
}