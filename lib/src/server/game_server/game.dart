import 'package:code_tanks/code_tanks_common.dart';
import 'package:code_tanks/code_tanks_kdtree.dart';
import 'package:code_tanks/src/server/game_server/components/collision/collider_component.dart';

import '../../../code_tanks_entity_component_system.dart';

import 'components/collision/health_component.dart';
import '../server_utils/vector_2d.dart';
import 'components/game_command/game_commands_component.dart';
import 'components/game_event_component.dart';
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

    // set up walls

    const worldWidth = 300;
    const worldHeight = 300;

    final wallShapes = <CTRect>[
      CTRect(worldWidth, 1), // top wall
      CTRect(worldWidth, 1), // bot wall
      CTRect(1, worldHeight), // left wall
      CTRect(1, worldHeight) // right wall
    ];

    final wallPositions = <Vector2D>[
      Vector2D() // top wall
        ..features[0] = 0
        ..features[1] = 0,
      Vector2D() // bot wall
        ..features[0] = 0
        ..features[1] = worldHeight,
      Vector2D() // left wall
        ..features[0] = 0
        ..features[1] = 0,
      Vector2D() // right wall
        ..features[0] = worldWidth
        ..features[1] = 0
    ];

    for (var i = 0; i < 4; i++) {
      world.createEntity()
        ..addComponent(PhysicsComponent(wallPositions[i]))
        ..addComponent(ColliderComponent(wallShapes[i], CollisionMask.wall, CollisionMask.none));
    }
  }

  int count = 0;

  static const width = 800;
  static const height = 600;

  // TODO better position implementation
  final positions = <Tuple<num, num>>[
    Tuple(width / 4, height / 4),
    Tuple(width * 3 / 4, height * 3 / 4),
    Tuple(width / 4, height * 3 / 4),
    Tuple(width * 3 / 4, height / 4),
  ];

  void initializeTank(String gameKey) {
    // TODO randomize position
    final position = Vector2D()
      ..features[0] = positions[count].first
      ..features[1] = positions[count].second;

    final tankShape = CTCircle(40);

    count++;

    final tankCollisionBitMask = CollisionMask.tank | CollisionMask.bullet | CollisionMask.wall;

    final entity = world.createEntity()
      ..addComponent(RenderComponent(RenderType.tank))
      ..addComponent(HealthComponent())
      ..addComponent(PhysicsComponent(position))
      ..addComponent(ColliderComponent(tankShape, CollisionMask.tank, tankCollisionBitMask))
      ..addComponent(GameCommandsComponent())
      ..addComponent(ScannerComponent())
      ..addComponent(GameEventComponent())
      ..addComponent(TankUtilitiesComponent());

    gameKeyToEntityId[gameKey] = entity.id;
  }

  void onTankDisconnect(String gameKey) {
    print('tank disconnected');
  }

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
      // print('update $i');
      await world.updateAsync();
    }

    print('finished simulation');
  }
}
