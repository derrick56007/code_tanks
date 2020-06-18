import 'package:code_tanks/code_tanks_server.dart';

void main() async {
  final address = '0.0.0.0';
  final port = 9898;
  final fileDir = 'temp/';

  final server = Server(address, port, fileDir);
  await server.init();
}
