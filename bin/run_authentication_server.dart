import 'dart:io';

import 'package:code_tanks/code_tanks_authentication_server.dart';

void main() async {
  final gameServerUrls = Platform.environment['GAME_SERVER_URLS'].split(',');
  final buildServerUrls = Platform.environment['BUILD_SERVER_URLS'].split(',');

  final address = '0.0.0.0';
  const defaultPort = 9897;

  final port = Platform.environment.containsKey('PORT')
      ? int.parse(Platform.environment['PORT'])
      : defaultPort;

  final redisAddress = 'redis';
  final redisPort = 6379;

  final authenticationServer = AuthenticationServer(
      address, port, gameServerUrls, buildServerUrls, redisAddress, redisPort);
  await authenticationServer.init();
}
