import 'package:code_tanks/code_tanks_build_server.dart';
import 'package:code_tanks/code_tanks_game_server.dart';
import 'package:code_tanks/code_tanks_authentication_server.dart';
import 'package:code_tanks/code_tanks_web_server.dart';

void main() async {
  final gameServerAddress = '127.0.0.1';
  final gameServerPort = 9899;

  final buildServerAddress = '127.0.0.1';
  final buildServerPort = 9898;

  final authenticationServerAddress = '127.0.0.1';
  final authenticationServerPort = 9897;

  final webServerAddress = '127.0.0.1';
  final webServerPort = 9896;

  final redisAddress = '127.0.0.1';
  final redisPort = 6379;

  final authenticationServerUrl =
      'ws://$authenticationServerAddress:$authenticationServerPort';

  final gameServerAddresses = [gameServerAddress];
  final buildServerAddresses = [buildServerAddress];

  final authenticationServer = AuthenticationServer(
      authenticationServerAddress,
      authenticationServerPort,
      gameServerAddresses,
      buildServerAddresses,
      redisAddress,
      redisPort);
  await authenticationServer.init();

  final gameServer =
      GameServer(gameServerAddress, gameServerPort, authenticationServerUrl);
  await gameServer.init();

  final fileDir = 'temp/';
  final buildServer = BuildServer(
      buildServerAddress, buildServerPort, fileDir, authenticationServerUrl);
  await buildServer.init();

  final webServer =
      WebServer(webServerAddress, webServerPort, authenticationServerUrl);
  await webServer.init();
}
