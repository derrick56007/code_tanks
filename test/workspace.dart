
import 'dart:io';

import 'package:code_tanks/src/server/game_server/game_server_docker_commands.dart';
import 'package:http_server/http_server.dart';

void main() async {
  await GameServerDockerCommands.killContainerByName('great_ardinghelli');
}



