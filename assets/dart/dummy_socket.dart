import 'dart:convert';
import 'dart:io';

import 'common_websocket.dart';

class DummySocket extends CommonWebSocket {
  final String url;
  WebSocket socket;

  DummySocket(this.url);

  @override
  void send(String type, [message]) {
    if (message == null) {
      socket.add(type);

      return;
    } 

    socket.add(jsonEncode([type, message]));
  }

  @override
  Future start() async {
    socket = await WebSocket.connect(url);

    done = socket.done;
  }
}