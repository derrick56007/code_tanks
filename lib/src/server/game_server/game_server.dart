import 'dart:io';

import 'package:code_tanks/src/server/server_common/control_server.dart';

import '../../../code_tanks_server_common.dart';

class GameServer extends ControlServer {
  GameServer(String address, int port, String authenticationServerAddress,
      int authenticationServerPort)
      : super('game', address, port, authenticationServerAddress,
            authenticationServerPort);

  @override
  void handleSocketDone(HttpRequest req, ServerWebSocket socket) {
    // TODO: implement handleSocketDone
  }

  @override
  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    // TODO: implement handleSocketStart
  }
}
