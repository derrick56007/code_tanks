import 'dart:async';
import 'dart:io';

import '../server_common/dummy_server.dart';

import '../../../code_tanks_server_common.dart';
import '../build_server/docker_utils.dart';
import 'package:path/path.dart' as path;

class BuildServer extends DummyServer {
  final String fileDir;
  // final builtTanks = <String, String>{};

  BuildServer(String address, int port, this.fileDir,
      String authenticationServerAddress, int authenticationServerPort)
      : super('build', authenticationServerAddress, authenticationServerPort);

  @override
  void init() async {
    authenticationSocket.on(
        'build_code', (data) => onBuildCode(data, authenticationSocket));

    await super.init();

    // await buildPreDefinedTanks();
  }

  Future<void> onBuildCode(data, DummySocket authSocket) async {
    final codeLang = data['code_language'];
    final code = data['code'];
    final uuid = data['uuid'];

    // final hash = BuiltTankHasher.getHash(codeLang, code);

    // if (builtTanks.containsKey(hash)) {
    //   // tank built before
    //   final uuid = builtTanks[hash];

    //   print('this tank has been built before! using uuid: $uuid');

    //   return uuid;
    // }

    // final uuid = await DockerUtils.getAvailableUuid(fileDir);
    final fp = path.joinAll([Directory.current.path, fileDir, uuid]);

    await DockerUtils.copyDockerFiles(fp, codeLang);
    await DockerUtils.createCustomFile(fp, codeLang, code);
    final exitCode = await DockerUtils.build(fp, uuid, authSocket);

    if (exitCode != 0) {
      // builtTanks[hash] = uuid;

      // await DockerUtils.saveToRegistry(fp, uuid, socket);

      // return uuid;

      final errorMsg = {
        'code': exitCode
      };

      authSocket.send('build_code_error_$uuid', errorMsg);

      return;
    }

    // check if save to registry works
    await DockerUtils.saveToRegistry(fp, uuid, authSocket);

    authSocket.send('build_code_success_$uuid');
  }

  // Future buildPreDefinedTanks() async {
  //   print('building predefined tanks...');

  //   for (final tankMap in PreDefinedTanks.tankMap.values) {
  //     final uuid = await onCodeUpload(tankMap);
  //     final tankName = tankMap['name'];

  //     if (uuid == null) {
  //       print('error building $tankName');
  //       continue;
  //     }

  //     print('successfully built $tankName');
  //   }

  //   print('done building predefined tanks');
  // }
}
