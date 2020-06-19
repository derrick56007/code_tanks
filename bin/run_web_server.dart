import 'dart:io';

import 'package:code_tanks/code_tanks_web_server.dart';

void main() async {
  final address = '0.0.0.0';
  const defaultPort = 9896;

  final port = Platform.environment.containsKey('PORT')
      ? int.parse(Platform.environment['PORT'])
      : defaultPort;

  final authenticationServerUrl = Platform.environment['AUTHENTICATION_SERVER_URL'];

  final webServer = WebServer(address, port, authenticationServerUrl);
  await webServer.init();
}
