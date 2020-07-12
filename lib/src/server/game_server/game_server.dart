import 'dart:async';
import 'dart:io';

import 'package:code_tanks/code_tanks_server_common.dart';
import 'package:code_tanks/src/server/game_server/game_server_docker_commands.dart';
import 'package:code_tanks/src/server/game_server/logic/systems/render_system.dart';

import '../server_common/dummy_server.dart';
import 'logic/game.dart';

class GameServer extends DummyServer {
  final String address;
  final int port;

  final gameIdToGameInstance = <String, Game>{};
  final gameKeyToGameId = <String, String>{};

  final socketToGameKey = <ServerWebSocket, String>{};

  HttpServer server;
  StreamSubscription<HttpRequest> sub;

  GameServer(this.address, this.port, String authenticationServerAddress, int authenticationServerPort)
      : super('game', authenticationServerAddress, authenticationServerPort);

  @override
  void init() async {
    server = await HttpServer.bind(address, port);
    server.idleTimeout = null;
    sub = server.listen(_onRequest);

    authenticationSocket.on('run_game', onRunGame);

    await super.init();
  }

  Future<void> onRequestPre(HttpRequest req) async {}
  Future<void> onRequestPost(HttpRequest req) async {}

  void _onRequest(HttpRequest req) async {
    await onRequestPre(req);

    // handle websocket connection
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = ServerWebSocket.upgradeRequest(req);

      await socket.start();

      handleSocketStart(req, socket);

      await socket.done;

      handleSocketDone(req, socket);
    }

    await onRequestPost(req);
  }

  void handleSocketDone(HttpRequest req, ServerWebSocket socket) {
    final gameKey = socketToGameKey[socket];
    final gameId = gameKeyToGameId[gameKey];
    final game = gameIdToGameInstance[gameId];

    if (game != null) {
      game.onTankDisconnect(gameKey);
    }

    socketToGameKey.remove(socket);
  }

  Future close() async {
    await sub.cancel();

    print('$name server closed at $address:$port');
  }

  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    socket //
      ..on('game_instance_handshake', (data) => onGameInstanceHandshake(req, data, socket));
  }

  void onGameInstanceHandshake(HttpRequest req, Map data, ServerWebSocket socket) async {
    // TODO validate data

    final gameKey = data['game_key'];

    print('game key $gameKey');

    if (!isValidGameKey(gameKey) || socketToGameKey.containsKey(socket)) {
      print('game instance handshake failure');

      return;
    }

    final gameId = gameKeyToGameId[gameKey];
    final game = gameIdToGameInstance[gameId];

    socketToGameKey[socket] = gameKey;

    game.addTank(gameKey, socket);
    print('game instance handshake success');

    if (game.allTanksInGame()) {
      await game.runSimulation();

      RenderSystem renderSys = game.world.getSystemByType(RenderSystem);
      final allFrames = renderSys.frames.map((frame) => frame.toList()).toList(growable: false);

      final msg = {'frames': allFrames};

      authenticationSocket.send('run_game_response_$gameId', msg);

      for (final key in game.gameKeyToEntityId.keys) {
        await GameServerDockerCommands.killContainerByName(key);
      }
    }
  }

  bool isValidGameKey(String gameKey) => gameKeyToGameId.containsKey(gameKey);

  void onRunGame(data) async {
    // TODO validate data

    final gameKeyToTankIds = data['game_keys'];

    for (final tankId in gameKeyToTankIds.values) {
      final exitCode = await GameServerDockerCommands.pullFromRegistry(tankId);

      if (exitCode != 0) {
        print('error pulling $tankId');
        return;
      }
    }

    final gameId = data['game_id'];

    gameIdToGameInstance[gameId] = Game(gameId, gameKeyToTankIds.keys.toList());

    for (final gameKey in gameKeyToTankIds.keys) {
      final tankId = gameKeyToTankIds[gameKey];

      gameKeyToGameId[gameKey] = gameId;

      await GameServerDockerCommands.runTankContainer(gameKey, tankId);
    }

    // TODO done
    // gameAddressToGameInstance.remove(address);

    // await GameServerDockerCommands.removeDockerNetwork(networkId);
  }
}
