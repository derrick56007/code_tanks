import 'dart:io';

import 'package:code_tanks/code_tanks_authentication_server.dart';

void main() async {
  final gameServerAddresses = Platform.environment.containsKey('GAME_SERVER_ADDRESSES')
      ? Platform.environment['GAME_SERVER_ADDRESSES'].split(',')
      : ['127.0.0.1'];

  final buildServerAddresses = Platform.environment.containsKey('BUILD_SERVER_ADDRESSES')
      ? Platform.environment['BUILD_SERVER_ADDRESSES'].split(',')
      : ['127.0.0.1'];   

  const address = '0.0.0.0';
  const defaultPort = 9897;

  final port = Platform.environment.containsKey('PORT')
      ? int.parse(Platform.environment['PORT'])
      : defaultPort;

  final redisAddress = Platform.environment.containsKey('REDIS_ADDRESS')
      ? Platform.environment['REDIS_ADDRESS']
      : '127.0.0.1';
  const redisPort = 6379;

  final authenticationServer = AuthenticationServer(
      address, port, gameServerAddresses, buildServerAddresses, redisAddress, redisPort);
  await authenticationServer.init();
}
