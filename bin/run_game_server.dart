import 'dart:io';

import 'package:code_tanks/code_tanks_game_server.dart';

void main() async {
  const address = '0.0.0.0';
  const defaultPort = 9898;

  final port = Platform.environment.containsKey('PORT')
      ? int.parse(Platform.environment['PORT'])
      : defaultPort;

  final authenticationServerUrl = Platform.environment['AUTHENTICATION_SERVER_URL'];

  final gameServer = GameServer(address, port, authenticationServerUrl);
  await gameServer.init();
}
