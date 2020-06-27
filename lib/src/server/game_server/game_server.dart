import 'dart:async';
import 'dart:io';

import 'package:code_tanks/code_tanks_server_common.dart';
import 'package:code_tanks/src/server/game_server/game_server_docker_commands.dart';
import 'package:code_tanks/src/server/server_utils/utils.dart';

import '../server_common/dummy_server.dart';
import 'logic/game.dart';

class GameServer extends DummyServer {
  final String address;
  final int port;
  // address to name
  // final gameAddressToGameInstance = <String, Game>{};
  // final gameKeyToGameAddress = <String, String>{};
  final gameKeyToGameInstance = <String, Game>{};
  final socketToGameInstance = <ServerWebSocket, Game>{};

  HttpServer server;
  StreamSubscription<HttpRequest> sub;

  GameServer(this.address, this.port, String authenticationServerAddress,
      int authenticationServerPort)
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
    final game = socketToGameInstance[socket];

    if (game != null) {
      game.onTankDisconnect(socket);
    }
  }

  Future close() async {
    await sub.cancel();

    print('$name server closed at $address:$port');
  }

  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    socket.on('game_instance_handshake',
        (data) => onGameInstanceHandshake(req, data, socket));
  }

  void onGameInstanceHandshake(HttpRequest req, data, ServerWebSocket socket) {
    // TODO validate data

    final gameKey = data['game_key'];

    print('game key $gameKey');

    if (!isValidGameKey(gameKey) || socketToGameInstance.containsKey(socket)) {
      print('game instance handshake failure');

      return;
    }
    // final address = gameKeyToGameAddress.remove(gameKey);

    // final game = gameAddressToGameInstance[address];
    final game = gameKeyToGameInstance[gameKey];

    socketToGameInstance[socket] = game;

    game.addTank(socket, gameKey);
    print('game instance handshake success');
  }

  bool isValidGameKey(String gameKey) {
    // final address = req.connectionInfo.remoteAddress.address;

    return gameKeyToGameInstance.containsKey(gameKey);
  }

  // bool requestFromGameInstance(HttpRequest req) {
  //   final address = req.connectionInfo.remoteAddress.address;

  //   return gameAddressToGameInstance.containsKey(address);
  // }

  void onRunGame(data) async {
    // TODO validate data

    // final tankIds = data['tank_ids'];
    final gameKeyToTankIds = data['game_keys'];

    for (final tankId in gameKeyToTankIds.values) {
      final exitCode = await GameServerDockerCommands.pullFromRegistry(tankId);

      if (exitCode != 0) {
        print('error pulling $tankId');
        return;
      }
    }

    // String networkId;

    // do {
    //   networkId = Utils.createRandomString(10);
    // } while (
    //     (await GameServerDockerCommands.createDockerNetwork(networkId)) != 0);

    // final address = await GameServerDockerCommands.getNetworkIp(networkId);

    // for (final gameKey in gameKeyToTankIds.keys) {
    //   gameKeyToGameAddress[gameKey] = address;
    // }

    final gameId = data['game_id'];

    final game = Game(address, gameId, gameKeyToTankIds.keys.toList());

    for (final gameKey in gameKeyToTankIds.keys) {
      final tankId = gameKeyToTankIds[gameKey];

      gameKeyToGameInstance[gameKey] = game;

      await GameServerDockerCommands.runTankContainer(gameKey, tankId);
    }

    // TODO done
    // gameAddressToGameInstance.remove(address);

    // await GameServerDockerCommands.removeDockerNetwork(networkId);
  }
}
