// import 'package:code_tanks/code_tanks_build_server.dart';
// import 'package:code_tanks/code_tanks_game_server.dart';
// import 'package:code_tanks/code_tanks_authentication_server.dart';
// import 'package:code_tanks/code_tanks_web_server.dart';

import 'run_authentication_server.dart' as run_authentication_server;
import 'run_build_server.dart' as run_build_server;
import 'run_game_server.dart' as run_game_server;
import 'run_web_server.dart' as run_web_server;

void main() async {
  await run_authentication_server.main();
  await run_build_server.main();
  await run_game_server.main();
  await run_web_server.main();

  // const gameServerAddress = '127.0.0.1';
  // const gameServerPort = 9899;

  // const buildServerAddress = gameServerAddress;
  // const buildServerPort = 9898;

  // const authenticationServerAddress = gameServerAddress;
  // const authenticationServerPort = 9897;

  // const webServerAddress = gameServerAddress;
  // const webServerPort = 9896;

  // const redisAddress = gameServerAddress;
  // const redisPort = 6379;

  // const gameServerAddresses = [gameServerAddress];
  // const buildServerAddresses = [buildServerAddress];

  // final authenticationServer = AuthenticationServer(
  //     authenticationServerAddress,
  //     authenticationServerPort,
  //     gameServerAddresses,
  //     buildServerAddresses,
  //     redisAddress,
  //     redisPort);
  // await authenticationServer.init();

  // final gameServer = GameServer(gameServerAddress, gameServerPort,
  //     authenticationServerAddress, authenticationServerPort);
  // await gameServer.init();

  // const fileDir = 'temp/';
  // final buildServer = BuildServer(buildServerAddress, buildServerPort, fileDir,
  //     authenticationServerAddress, authenticationServerPort);
  // await buildServer.init();

  // final webServer =
  //     WebServer(webServerAddress, webServerPort, authenticationServerUrl);
  // await webServer.init();
}
