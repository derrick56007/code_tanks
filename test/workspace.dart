import 'package:code_tanks/code_tanks_server_common.dart';

void main() async {
  final address = '0.0.0.0';
  final port = 9897;

  final socket = DummySocket('ws://$address:$port');
  await socket.start();
  await socket.done;
}
