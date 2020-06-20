import 'dart:io';

import 'package:code_tanks/code_tanks_build_server.dart';

void main() async {
  const address = '0.0.0.0';
  const defaultPort = 9898;

  final port = Platform.environment.containsKey('PORT')
      ? int.parse(Platform.environment['PORT'])
      : defaultPort;

  final authenticationServerAddress =
      Platform.environment.containsKey('AUTHENTICATION_SERVER_ADDRESS')
          ? Platform.environment['AUTHENTICATION_SERVER_ADDRESS']
          : '127.0.0.1';

  final authenticationServerPort =
      Platform.environment.containsKey('AUTHENTICATION_SERVER_PORT')
          ? int.parse(Platform.environment['AUTHENTICATION_SERVER_PORT'])
          : 9897;

  const fileDir = 'temp/';
  final buildServer = BuildServer(address, port, fileDir,
      authenticationServerAddress, authenticationServerPort);
  await buildServer.init();
}
