import 'dart:convert';

import 'dart:io';

class GameServerDockerCommands {
  static final lineSplitter = LineSplitter();
  static final utf8Decoder = Utf8Decoder();

  static Future<int> pullFromRegistry(String tankId) async {
    const registryAddress = 'localhost';
    const registryPort = 5000;

    final newTag = '$registryAddress:$registryPort/$tankId';

    final args = ['pull', newTag];
    final pullProcess = await Process.start('docker', args, runInShell: true);
    print('running docker pull with args: $args');
    await pullProcess.stderr.drain();
    final exitCode = await pullProcess.exitCode;

    print('pulled $tankId with exit code $exitCode');

    return exitCode;
  }

  // static Future<int> createDockerNetwork(String networkId) async {
  //   final args = ['network', 'create', networkId];

  //   print('running docker network with args: $args');
  //   final process = await Process.start('docker', args, runInShell: true);

  //   await process.stderr.drain();

  //   return await process.exitCode;
  // }

  // static Future<int> removeDockerNetwork(String networkId) async {
  //   final args = ['network', 'rm', networkId];

  //   print('running docker network with args: $args');
  //   final process = await Process.start('docker', args, runInShell: true);

  //   await process.stderr.drain();

  //   return await process.exitCode;
  // }

  // static Future<String> getNetworkIp(String name) async {
  //   final args = ['network', 'inspect', name];

  //   print('running docker network with args: $args');
  //   final process = await Process.start('docker', args, runInShell: true);
  //   final lineStream =
  //       process.stdout.transform(utf8Decoder).transform(lineSplitter);

  //   var jsonString = '';
  //   await for (final line in lineStream) {
  //     jsonString += line;
  //   }

  //   await process.stderr.drain();

  //   return jsonDecode(jsonString)[0]['IPAM']['Config'][0]['Gateway'];
  // }

  static Future<void> runTankContainer(String gameKey, String tankId
      // , String networkId
      ) async {
    final args = [
      'run',
      '--network',
      'host',
      '--env',
      'GAME_KEY=$gameKey',
      '--name',
      gameKey,
      // '--network',
      // networkId,
      tankId
    ];

    print('running docker create with args: $args');
    final process = await Process.start('docker', args, runInShell: true);
    final lineStream = process.stdout.transform(utf8Decoder).transform(lineSplitter);

    // TODO stream output to client socket
    lineStream.listen((line) {
      print(line);
    });
    // await process.stderr.drain();

    // return await process.exitCode;
    return;
  }

  static Future<int> killContainerByName(String gameKey) async {
    final args = [
      'kill',
      gameKey,
    ];

    print('running docker create with args: $args');
    final process = await Process.start('docker', args, runInShell: true);    

    await process.stderr.drain();
    final exitCode = await process.exitCode;

    print('killed container $gameKey with exit code $exitCode');

    return exitCode;
  }
}
