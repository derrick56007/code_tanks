import 'dart:async';
import 'dart:io';

import '../../../code_tanks_server_common.dart';

abstract class BaseServer {
  final String name;
  final String address;
  final int port;

  HttpServer server;
  StreamSubscription<HttpRequest> sub;

  BaseServer(this.name, this.address, this.port);

  void init() async {
    server = await HttpServer.bind(address, port);
    server.idleTimeout = null;
    sub = server.listen(_onRequest);

    print('$name server started at $address:$port');
  }

  Future<void> onRequestPre(HttpRequest req) async {}
  Future<void> onRequestPost(HttpRequest req) async {}

  void _onRequest(HttpRequest req) async {
    await onRequestPre(req);

    // handle websocket connection
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      final socket = ServerWebSocket.upgradeRequest(req);

      await socket.start();

      handleSocketStart(socket);

      await socket.done;

      handleSocketDone(socket);
    }

    await onRequestPost(req);
  }

  void handleSocketStart(ServerWebSocket socket);

  void handleSocketDone(ServerWebSocket socket);

  Future close() async {
    await sub.cancel();

    print('$name server closed at $address:$port');
  }
}
