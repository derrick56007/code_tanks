import 'dart:async';
import 'dart:io';

import '../../../code_tanks_server_common.dart';
import '../build_server/built_tank_info.dart';
import '../server_common/server_websocket.dart';
import '../game_server/pre_defined_tanks/pre_defined_tanks.dart';
import '../build_server/docker_utils.dart';
import 'package:path/path.dart' as path;

class BuildServer {
  final String address;
  final int port;
  final String fileDir;
  final String authenticationServerUrl;
  final DummySocket authenticationSocket;

  HttpServer server;
  StreamSubscription<HttpRequest> sub;

  // tank hash to uuid map
  final builtTanks = <String, String>{};

  BuildServer(
      this.address, this.port, this.fileDir, this.authenticationServerUrl): authenticationSocket = DummySocket(authenticationServerUrl);

  void init() async {
    server = await HttpServer.bind(address, port);
    server.idleTimeout = null;

    sub = server.listen(onRequest);

    print('build server started at $address:$port');

    await authenticationSocket.start();
    print('connected to authentication server $authenticationServerUrl');
    authenticationSocket.send('build_server_handshake');
    print('sent handshake');

    await buildPreDefinedTanks();
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
      ..on('code_upload', (data) {
        onCodeUpload(data, socket);
      });
  }

  void handleSocketDone(ServerWebSocket socket) {}

  Future close() async {
    await sub.cancel();

    print('build server closed at $address:$port');
  }

  Future<String> onCodeUpload(data, [ServerWebSocket socket]) async {
    socket?.send('code_upload_success');

    final codeLang = data['code_language'];
    final code = data['code'];
    final hash = BuiltTankHasher.getHash(codeLang, code);

    if (builtTanks.containsKey(hash)) {
      // tank built before
      final uuid = builtTanks[hash];

      print('this tank has been built before! using uuid: $uuid');

      return uuid;
    }

    final uuid = await DockerUtils.getAvailableUuid(fileDir);
    final fp = path.joinAll([Directory.current.path, fileDir, uuid]);

    await DockerUtils.copyDockerFiles(fp, codeLang);
    await DockerUtils.createCustomFile(fp, codeLang, code);
    final exitCode = await DockerUtils.build(fp, uuid, socket);

    if (exitCode == 0) {
      builtTanks[hash] = uuid;

      return uuid;
    }

    return null;
  }

  Future buildPreDefinedTanks() async {
    print('building predefined tanks...');

    for (final tankMap in PreDefinedTanks.tankMap.values) {
      final uuid = await onCodeUpload(tankMap);
      final tankName = tankMap['name'];

      if (uuid == null) {
        print('error building $tankName');
        continue;
      }

      print('successfully built $tankName');
    }

    print('done building predefined tanks');
  }
}
