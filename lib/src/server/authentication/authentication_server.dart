import 'dart:async';
import 'dart:io';

import 'package:code_tanks/code_tanks_common.dart';
import 'package:code_tanks/src/server/utils/server_websocket.dart';

class AuthenticationServer {
  final String address;
  final int port;
  final List<String> gameServerAddresses;
  final List<String> buildServerAddresses;

  HttpServer server;
  StreamSubscription<HttpRequest> sub;

  final gameServerSockets = <String, ServerWebSocket>{};
  final buildServerSockets = <String, ServerWebSocket>{};

  AuthenticationServer(
      this.address, this.port, this.gameServerAddresses, this.buildServerAddresses) {
    print('game server urls: $gameServerAddresses');
    print('build server urls: $buildServerAddresses');
  }

  void init() async {
    server = await HttpServer.bind(address, port);
    server.idleTimeout = null;

    sub = server.listen(onRequest);

    print('auth server started at $address:$port');
  }

  void onRequest(HttpRequest req) async {
    // handle websocket connection
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = ServerWebSocket.upgradeRequest(req);

      await socket.start();

      handleSocketStart(req, socket);

      await socket.done;

      handleSocketDone(socket);
    }
  }

  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    socket
      ..on('game_server_handshake', () {
        final address = req.connectionInfo.remoteAddress.address;

        print('handshake from game server $address');

        if (!gameServerAddresses.contains(address)) {
          print('address is not a valid game server $address');
          return;
        }

        if (gameServerSockets.containsKey(address)) {
          print('game server already connected: $address');
          return;
        }

        gameServerSockets[address] = socket;
        print('game server handshake success');
      })
      ..on('build_server_handshake', () {
        final address = req.connectionInfo.remoteAddress.address;

        print('handshake from build server $address');

        if (!buildServerAddresses.contains(address)) {
          print('address is not a valid build server $address');
          return;
        }
        if (buildServerSockets.containsKey(address)) {
          print('build server already connected: $address');
          return;
        }

        buildServerSockets[address] = socket;
        print('build server handshake success');
      })
      ..on('register', onRegister)
      ..on('login', onLogin);
  }

  void handleSocketDone(ServerWebSocket socket) {
    if (gameServerSockets.containsValue(socket)) {
      gameServerSockets.remove(socket);
    }

    if (buildServerSockets.containsValue(socket)) {
      buildServerSockets.remove(socket);
    }
  }

  Future close() async {
    await sub.cancel();

    print('authentication server closed at $address:$port');
  }

  void onRegister(data) {}

  void onLogin(data) {}
}
