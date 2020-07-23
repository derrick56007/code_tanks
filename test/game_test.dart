import 'package:code_tanks/src/common/test_socket.dart';
import 'package:code_tanks/src/server/game_server/components/game_command/game_commands_component.dart';
import 'package:code_tanks/src/server/game_server/game.dart';
import 'package:test/test.dart';
import 'package:code_tanks/code_tanks_dart_api.dart';


class Custom extends BaseTank {
  @override
  void run() {
    setRadarToRotateWithGun(true);

    aheadBy(2);
    rotateGunBy(2);
    backBy(2);
    setRotateRadarBy(2);

    setRotateGunBy(2);
    aheadBy(2);
  }

  @override
  void onScanTank(ScanTankEvent e) {
    backBy(2);
    setRotateRadarBy(2);

    setRotateGunBy(2);
    aheadBy(2);
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
