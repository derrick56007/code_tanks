import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pedantic/pedantic.dart';

import 'common_websocket.dart';

class DummySocket extends CommonWebSocket {
  final String url;
  WebSocket socket;

  DummySocket(this.url);

  @override
  void send(String type, [message]) {
    if (message == null) {
      socket.add(jsonEncode(type));

      return;
    }

    socket.add(jsonEncode([type, message]));
  }

  static const defaultRetrySeconds = 2;
  static const doub = 2;

  @override
  Future start([int retrySeconds = defaultRetrySeconds]) async {
    print('connecting to $url');
    final completer = Completer();

    var reconnectScheduled = false;

    void _scheduleReconnect() {
      if (!reconnectScheduled) {
        // this is for debugging purposes;
        // if a reconnect is scheduled, then devMode is toggled to see if insecure websocket is available (ws)
        // devMode = !devMode;
        final newRetrySeconds = retrySeconds * doub;

        print('scheduling reconnect to $url in $newRetrySeconds seconds');

        Timer(Duration(seconds: retrySeconds),
            () async => await start(newRetrySeconds));
      }
      reconnectScheduled = true;
    }

    unawaited(WebSocket.connect(url).then((WebSocket s) async {
      print('connected to $url');
      socket = s;

      completer.complete();

      final doneCompleter = Completer();
      done = doneCompleter.future;

      s.listen(onData, onError: (e) {
        doneCompleter.complete();
      }, onDone: () {
        doneCompleter.complete();
      });

      await done;

      print('disconnected from $url');

      _scheduleReconnect();
    }, onError: (e) {
      print('could not connect to $url');

      _scheduleReconnect();
    }));

    return completer.future;
  }
}
