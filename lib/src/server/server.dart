import 'dart:async';
import 'dart:io';

import 'package:code_tanks/src/server/docker_utils.dart';
import 'package:code_tanks/src/server/server_websocket.dart';
import 'package:code_tanks/src/server/utils.dart';
import 'package:path/path.dart' as path;

class Server {
  final String address;
  final int port;
  final String fileDir;

  HttpServer server;
  StreamSubscription<HttpRequest> sub;

  Server(this.address, this.port, this.fileDir);

  void init() async {
    server = await HttpServer.bind(address, port);
    server.idleTimeout = null;

    sub = server.listen(onRequest);

    print('Server started at $address:$port');
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
    socket //
      ..on('code_upload', (data) async {
        socket.send('code_upload_success');

        final uuid = await DockerUtils.getAvailableUuid(fileDir);
        final fp = path.joinAll([Directory.current.path, fileDir, uuid]);
        final codeLang = data['code_language'];
        final code = data['code'];

        await DockerUtils.createCustomFile(fp, codeLang, code);
        await DockerUtils.copyDockerFiles(fp, codeLang);
        await DockerUtils.build(fp, uuid, socket);
      });
  }


  void handleSocketDone(ServerWebSocket socket) {}

  Future close() async {
    await sub.cancel();

    print('Server closed at $address:$port');
  }
}
