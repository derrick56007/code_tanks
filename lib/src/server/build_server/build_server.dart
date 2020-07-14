import 'dart:io';

import '../server_common/dummy_server.dart';
import '../build_server/build_server_docker_commands.dart';

import 'package:path/path.dart' as path;

class BuildServer extends DummyServer {
  final String fileDir;

  BuildServer(String address, int port, this.fileDir,
      String authenticationServerAddress, int authenticationServerPort)
      : super('build', authenticationServerAddress, authenticationServerPort);

  @override
  void init() async {
    authenticationSocket.on('build_code', onBuildCode);

    await super.init();
  }

  void onBuildCode(data) async {
    final codeLang = data['code_language'];
    final code = data['code'];
    final uuid = data['uuid'];

    final fp = path.joinAll([Directory.current.path, fileDir, uuid]);

    await BuildServerDockerCommands.copyDockerFiles(fp, codeLang);
    await BuildServerDockerCommands.createCustomFile(fp, codeLang, code);
    final exitCode =
        await BuildServerDockerCommands.build(fp, uuid, authenticationSocket);

    if (exitCode != 0) {

      final errorMsg = {'code': exitCode};

      authenticationSocket.send('build_code_error_$uuid', errorMsg);
    } else {
      // check if save to registry works
      await BuildServerDockerCommands.saveToRegistry(
          fp, uuid, authenticationSocket);

      authenticationSocket.send('build_code_success_$uuid');
    }

    await Directory(fp).delete(recursive: true);
  }
}
