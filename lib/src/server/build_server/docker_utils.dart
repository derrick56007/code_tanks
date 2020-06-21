import 'dart:convert';
import 'dart:io';

import '../server_common/server_websocket.dart';
import '../server_utils/utils.dart';
import 'package:path/path.dart' as path;

class DockerUtils {
  static final utf8Decoder = Utf8Decoder();
  static final lineSplitter = LineSplitter();

  static const fileExtensions = <String, String>{
    'dart': '.dart',
    'python': '.py'
  };

  static Future<int> build(String fp, String uuid,
      [ServerWebSocket socket]) async {

    final dockerFilePath = path.join(fp, 'Dockerfile');

    // docker tag must be lowercase
    final args = ['build', '-f', dockerFilePath, '-t', uuid, fp];
    print('running docker build with args: $args');
    final process = await Process.start('docker', args, runInShell: true);

    final lineStream = process.stdout
        .transform(DockerUtils.utf8Decoder)
        .transform(DockerUtils.lineSplitter);

    final logPath = path.joinAll([fp, 'out', 'log']);
    final logFile = await File(logPath).create(recursive: true);

    await for (final line in lineStream) {
      socket?.send('build_log_part', line);
      await logFile.writeAsString(line + '\n', mode: FileMode.append);
    }

    await process.stderr.drain();
    // print('exit code: ${await process.exitCode}');
    final exitCode = await process.exitCode;
    print('built $uuid with exit code $exitCode');

    return exitCode;
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

    // first delete temp file
    await File(p).delete();
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

  static Future<int> saveToRegistry(String fp, String uuid,
      [ServerWebSocket socket]) async {
    const registryAddress = 'localhost';
    const registryPort = 5000;

    final newTag = '$registryAddress:$registryPort/$uuid';
    final tagArgs = ['tag', uuid, newTag];

    final tagProcess = await Process.start('docker', tagArgs, runInShell: true);
    print('running tag push with args: $tagArgs');
    final tagExitCode = await tagProcess.stderr.drain();

    if (tagExitCode != null) {
      print('error tagging $tagExitCode');
      return tagExitCode;
    }

    final args = ['push', newTag];
    print('running docker push with args: $args');
    final process = await Process.start('docker', args, runInShell: true);

    final lineStream = process.stdout
        .transform(DockerUtils.utf8Decoder)
        .transform(DockerUtils.lineSplitter);

    final logPath = path.joinAll([fp, 'out', 'push_log']);
    final logFile = await File(logPath).create(recursive: true);

    await for (final line in lineStream) {
      socket?.send('push_log_part', line);
      await logFile.writeAsString(line + '\n', mode: FileMode.append);
    }

    await process.stderr.drain();
    // print('exit code: ${await process.exitCode}');
    final exitCode = await process.exitCode;
    print('pushed $uuid with exit code $exitCode');

    return exitCode;
  }
}
