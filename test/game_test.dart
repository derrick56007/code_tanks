import 'package:code_tanks/src/common/test_socket.dart';
import 'package:code_tanks/src/server/game_server/logic/components/game_command/game_commands_component.dart';
import 'package:code_tanks/src/server/game_server/logic/game.dart';
import 'package:test/test.dart';

import 'package:code_tanks/code_tanks_dart_api.dart';


class Custom extends BaseTank {
  @override
  void run() {
    setRadarToRotateWithGun(true);

    ahead(2);
    rotateGun(2);
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    ahead(2);
  }

  @override
  void onScanTank(ScanTankEvent e) {
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    ahead(2);
  }
}

BaseTank createTank() => Custom();

void main() {
  group('simple test', () {
    Game game;
    const gameKeys = ['0', '1', '2'];

    // final gameServerSocket = TestSocket();

    setUp(() {
      game = Game('0', gameKeys);

      for (final key in gameKeys) {
        final socket = TestSocket();
        handleSocketAndBot(socket, Custom());
        game.addTank(key, socket);
      }
    });

    test('first test', () async {
      await game.world.updateAsync();

      for (final entity in game.world.idToEntity.values) {
        GameCommandsComponent pComp = entity.getComponent(GameCommandsComponent);
      
        expect(pComp.commandQueue.length, 11);
      }
    });

    test('second test', () async {
      for (var i = 0; i < 10; i++) {
        await game.world.updateAsync();
      }
      for (final entity in game.world.idToEntity.values) {
        GameCommandsComponent pComp = entity.getComponent(GameCommandsComponent);
      
        expect(pComp.commandQueue.length, 0);
      }      
      await game.world.updateAsync();
      for (final entity in game.world.idToEntity.values) {
        GameCommandsComponent pComp = entity.getComponent(GameCommandsComponent);
      
        expect(pComp.commandQueue.length, 11);
      }      
    });

    tearDown(() {
      //
    });
  });
}
