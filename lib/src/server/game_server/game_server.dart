import 'dart:async';
import 'dart:io';

import '../../../code_tanks_server_common.dart';

class GameServer {
  final String address;
  final int port;
  final String authenticationServerUrl;
  final DummySocket authenticationSocket;

  HttpServer server;
  StreamSubscription<HttpRequest> sub;

  GameServer(this.address, this.port, this.authenticationServerUrl): authenticationSocket = DummySocket(authenticationServerUrl);

  void init() async {
    server = await HttpServer.bind(address, port);
    server.idleTimeout = null;

    sub = server.listen(onRequest);

    print('game server started at $address:$port');

    await authenticationSocket.start();
    print('connected to authentication server $authenticationServerUrl');
    authenticationSocket.send('game_server_handshake');
    print('sent handshake');
  }

  void onRequest(HttpRequest req) async {

    // handle websocket connection
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = ServerWebSocket.upgradeRequest(req);

      await socket.start();

      handleSocketStart(socket);

      await socket.done;

      handleSocketDone(socket);
    }
  }

  void handleSocketStart(ServerWebSocket socket) {
    // socket;
  }

  void handleSocketDone(ServerWebSocket socket) {}

  Future close() async {
    await sub.cancel();

    print('game server closed at $address:$port');
  }
}
