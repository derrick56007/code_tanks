import 'dart:async';
import 'dart:io';

import 'package:code_tanks/code_tanks_server_common.dart';
import 'package:code_tanks/src/server/game_server/game_server_docker_commands.dart';
import 'package:code_tanks/src/server/server_utils/utils.dart';
import 'package:quiver/collection.dart';

import '../server_common/dummy_server.dart';
import 'logic/game.dart';

class GameServer extends DummyServer {
  final String address;
  final int port;
  // address to name
  // final gameAddressToGameInstance = <String, Game>{};
  // final gameKeyToGameAddress = <String, String>{};
  final gameIdToGameInstance = BiMap<String, Game>();
  final gameKeyToGameId = BiMap<String, String>();

  BiMap<String, ServerWebSocket> get gameKeyToSocket => socketToGameKey.inverse;

  final socketToGameKey = BiMap<ServerWebSocket, String>();

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
    ..on('game_instance_handshake', (data) => onGameInstanceHandshake(req, data, socket))
    ..on('game_event', (data) => onPlayerEvent);
  }

  void onPlayerEvent(Map data) {
    final gameKey = data['game_key'];
    final gameId = gameKeyToGameId[gameKey];
    final game = gameIdToGameInstance[gameId];

    final event = data['event'];

    // TODO validate events

    game.onPlayerEvent(gameKey, event);
  }

  void onGameInstanceHandshake(HttpRequest req, Map data, ServerWebSocket socket) {
    // TODO validate data

    final gameKey = data['game_key'];

    print('game key $gameKey');

    if (!isValidGameKey(gameKey) || socketToGameKey.containsKey(socket)) {
      print('game instance handshake failure');

      return;
    }
    // final address = gameKeyToGameAddress.remove(gameKey);

    // final game = gameAddressToGameInstance[address];
    final gameId = gameKeyToGameId[gameKey];
    final game = gameIdToGameInstance[gameId];

    socketToGameKey[socket] = gameKey;

    game.addTankAndStartGameIfAllTanksInGame(gameKey, socket);
    print('game instance handshake success');
  }

  bool isValidGameKey(String gameKey) {
    // final address = req.connectionInfo.remoteAddress.address;

    return gameKeyToGameId.containsKey(gameKey);
  }

  // bool requestFromGameInstance(HttpRequest req) {
  //   final address = req.connectionInfo.remoteAddress.address;

  //   return gameAddressToGameInstance.containsKey(address);
  // }

  void onRunGame(Map data) async {
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
