import 'package:code_tanks/code_tanks_build_server.dart';
import 'package:code_tanks/code_tanks_game_server.dart';
import 'package:code_tanks/code_tanks_authentication_server.dart';
import 'package:code_tanks/code_tanks_web_server.dart';

void main() async {
  const gameServerAddress = '127.0.0.1';
  const gameServerPort = 9899;

  const buildServerAddress = gameServerAddress;
  const buildServerPort = 9898;

  const authenticationServerAddress = gameServerAddress;
  const authenticationServerPort = 9897;

  const webServerAddress = gameServerAddress;
  const webServerPort = 9896;

  const redisAddress = gameServerAddress;
  const redisPort = 6379;

  const authenticationServerUrl =
      'ws://$authenticationServerAddress:$authenticationServerPort';

  const gameServerAddresses = [gameServerAddress];
  const buildServerAddresses = [buildServerAddress];

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

  const fileDir = 'temp/';
  final buildServer = BuildServer(
      buildServerAddress, buildServerPort, fileDir, authenticationServerUrl);
  await buildServer.init();

  final webServer =
      WebServer(webServerAddress, webServerPort, authenticationServerUrl);
  await webServer.init();
}
