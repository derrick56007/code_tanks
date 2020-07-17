import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:code_tanks/code_tanks_common.dart';

class ClientWebSocket extends CommonWebSocket {
  WebSocket _webSocket;

  bool _connected = false;

  bool isConnected() => _connected;

  Stream<Event> onOpen, onClose, onError;

  static const defaultRetrySeconds = 2;
  static const double = 2;

  final String address;
  final int port;

  ClientWebSocket(this.address, this.port);

  @override
  Future start([int retrySeconds = defaultRetrySeconds]) {
    final completer = Completer();

    var reconnectScheduled = false;

    _webSocket = WebSocket('ws://$address:$port');

    void _scheduleReconnect() {
      if (!reconnectScheduled) {
        Timer(Duration(seconds: retrySeconds),
            () async => await start(retrySeconds * double));
      }
      reconnectScheduled = true;
    }

    _webSocket
      ..onOpen.listen((Event e) {
        _connected = true;

        completer.complete();
      })
      ..onMessage.listen((MessageEvent e) {
        onData(e.data);
      })
      ..onClose.listen((Event e) {
        _connected = false;
        _scheduleReconnect();
      })
      ..onError.listen((Event e) {
        _connected = false;
        _scheduleReconnect();
      });

    onOpen = _webSocket.onOpen;
    onClose = _webSocket.onClose;
    onError = _webSocket.onError;

    return completer.future;
  }

  @override
  void send(String type, [message]) {
    if (message == null) {
      _webSocket.send(jsonEncode(type));

      return;
    }

    _webSocket.send(jsonEncode([type, message]));
  }
}
