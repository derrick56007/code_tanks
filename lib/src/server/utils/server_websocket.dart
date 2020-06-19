import 'dart:convert';
import 'dart:io';

import 'package:code_tanks/src/common/common_websocket.dart';

class ServerWebSocket extends CommonWebSocket {
  final HttpRequest _req;

  WebSocket _webSocket;

  ServerWebSocket.upgradeRequest(this._req);

  @override
  void send(String type, [message]) {
    if (message == null) {
      _webSocket.add(jsonEncode(type));

      return;
    }

    _webSocket.add(jsonEncode([type, message]));
  }

  @override
  Future start() async {
    _webSocket = await WebSocketTransformer.upgrade(_req)
      ..listen(onData);

    done = _webSocket.done;
  }

}