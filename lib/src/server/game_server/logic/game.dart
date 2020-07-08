import 'package:code_tanks/code_tanks_common.dart';

import '../../../../code_tanks_entity_component_system.dart';

import 'components/render_component.dart';
import 'components/socket_component.dart';
import 'components/health_component.dart';
import 'components/player_event_component.dart';
import 'components/position_component.dart';
import 'components/velocity_component.dart';

import 'systems/apply_player_commands_system.dart';
import 'systems/physics_system.dart';
import 'systems/player_event_system.dart';
import 'systems/render_system.dart';
import 'systems/bullet_system.dart';

class Game {
  final int id;

  final gameKeyToEntityId = <String, int>{};

  final world = World();

  final gameKeysAdded = <String>{};

  Game(this.id, List<String> gameKeys) {
    gameKeys.forEach(initializeTank);

    world
      ..addSystem(RenderSystem())
      ..addSystem(PlayerEventSystem())
      ..addSystem(ApplyPlayerCommandSystem())
      ..addSystem(PhysicsSystem())
      ..addSystem(BulletSystem());
  }

  void initializeTank(String gameKey) {
    final entity = world.createEntity()
      ..addComponent(RenderComponent())
      ..addComponent(HealthComponent())
      ..addComponent(PositionComponent())
      ..addComponent(VelocityComponent())
      ..addComponent(PlayerEventComponent());

    gameKeyToEntityId[gameKey] = entity.id;
  }

  void onTankDisconnect(String gameKey) {}

  void addTankAndStartGameIfAllTanksInGame(String gameKey, CommonWebSocket socket) {
    if (!isValidGameKey(gameKey)) {
      print('error adding tank');
      return;
    }

    gameKeysAdded.add(gameKey);

    world.idToEntity[gameKeyToEntityId[gameKey]].addComponent(SocketComponent(socket));

    print('added tank');

    if (allTanksInGame()) {
      startGame();
    }
  }

  bool allTanksInGame() => gameKeysAdded.length == gameKeyToEntityId.length;

  bool isValidGameKey(String gameKey) => gameKeyToEntityId.containsKey(gameKey);

  void startGame() {
    print('started game');
  }

  void onPlayerEvent(String gameKey, Map event) {
    final entity = world.createEntity();
    entity.addComponent(PlayerEventComponent());
  }
}

// class TankStates {}

// class PlayerInfo {
//   final String gameKey;
//   final String userId;
//   final String tankId;

//   PlayerInfo(this.gameKey, this.userId, this.tankId);
// }
