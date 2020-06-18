import 'dart:convert';
import 'dart:io';

import 'package:code_tanks/src/server/server_websocket.dart';
import 'package:code_tanks/src/server/utils.dart';
import 'package:path/path.dart' as path;

class DockerUtils {
  static final utf8Decoder = Utf8Decoder();
  static final lineSplitter = LineSplitter();

  static const fileExtensions = <String, String>{
    'dart': '.dart',
    'python': '.py'
  };

  static Future build(String fp, String uuid, ServerWebSocket socket) async {
    //     Process.start('ls', [], runInShell: true).then((Process process) {
    //   process.stdout
    //       .transform(utf8.decoder)
    //       .listen((data) { print(data); });
    //   // process.stdin.writeln('Hello, world!');
    //   // process.stdin.writeln('Hello, galaxy!');
    //   // process.stdin.writeln('Hello, universe!');
    // });

    final dockerFilePath = path.join(fp, 'Dockerfile');

    // docker tag must be lowercase

    final process = await Process.start(
        'docker', ['build', '-f', dockerFilePath, '-t', uuid, fp],
        runInShell: true);

    final lineStream = process.stdout
        .transform(DockerUtils.utf8Decoder)
        .transform(DockerUtils.lineSplitter);

    final logPath = path.joinAll([fp, 'out', 'log']);
    final logFile = await File(logPath).create(recursive: true);

    await for (final line in lineStream) {
      socket.send('build_log_part', line);
      await logFile.writeAsString(line + '\n', mode: FileMode.append);
    }

    await process.stderr.drain();
    // print('exit code: ${await process.exitCode}');
    final exitCode = await process.exitCode;
    print('built $uuid with exit code $exitCode');
  }

  static Future copyDockerFiles(String fp, String codeLanguage) async {
    final assetDir =
        path.joinAll([Directory.current.path, 'assets', codeLanguage]);
    await Utils.copyPath(assetDir, fp);
  }

  static Future createCustomFile(
      String fp, String codeLanguage, String code) async {
    final ext = fileExtensions[codeLanguage];

    final p = path.joinAll([fp, 'custom$ext']);
    final file = await File(p).create(recursive: true);
    await file.writeAsString(code);
  }

  static Future<String> getAvailableUuid(String fp) async {
    String uuid;
    String tempPath;

    do {
      uuid = Utils.createRandomString(10);
      tempPath = path.joinAll([Directory.current.path, fp, uuid]);
    } while (await Directory(tempPath).exists());

    return uuid;
  }
}
