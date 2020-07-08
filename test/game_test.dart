import 'package:code_tanks/src/common/test_socket.dart';
import 'package:code_tanks/src/server/game_server/logic/components/player_event_component.dart';
import 'package:code_tanks/src/server/game_server/logic/game.dart';
import 'package:test/test.dart';
import '../assets/dart/run.dart' as dart_run;

import '../assets/dart/code_tanks_api.dart';

class Custom extends BaseTank {
  @override
  void onDetectRobot(DetectRobotEvent e) {
    // TODO: implement onDetectRobot
  }

  @override
  void run() {
    setRadarToRotateWithGun(true);

    ahead(2);
    rotateGun(2);
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    rotateGun(-2);
  }
}

BaseTank createTank() => Custom();

void main() {
  group('simple test', () {
    Game game;
    const gameKeys = ['0', '1', '2'];

    // final gameServerSocket = TestSocket();

    setUp(() {
      game = Game(0, gameKeys);

      for (final key in gameKeys) {
        final socket = TestSocket();
        dart_run.handleSocketAndBot(socket, Custom());
        game.addTankAndStartGameIfAllTanksInGame(key, socket);
      }
    });

    test('first test', () async {
      await game.world.updateAsync();

      for (final entity in game.world.idToEntity.values) {
        PlayerEventComponent pComp = entity.getComponent(PlayerEventComponent);
      
        expect(pComp.commandQueue.length, 11);
      }
    });

    test('second test', () async {
      for (var i = 0; i < 10; i++) {
        await game.world.updateAsync();
      }
      for (final entity in game.world.idToEntity.values) {
        PlayerEventComponent pComp = entity.getComponent(PlayerEventComponent);
      
        expect(pComp.commandQueue.length, 0);
      }      
      await game.world.updateAsync();
      for (final entity in game.world.idToEntity.values) {
        PlayerEventComponent pComp = entity.getComponent(PlayerEventComponent);
      
        expect(pComp.commandQueue.length, 11);
      }      
    });

    tearDown(() {
      //
    });
  });
}
