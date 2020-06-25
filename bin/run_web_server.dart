import 'dart:io';

import 'package:code_tanks/code_tanks_web_server.dart';

void main() async {
  const address = '0.0.0.0';
  const defaultPort = 9896;

  final port = Platform.environment.containsKey('PORT')
      ? int.parse(Platform.environment['PORT'])
      : defaultPort;
          
  final webServer = WebServer(
      address, port);
  await webServer.init();
}
