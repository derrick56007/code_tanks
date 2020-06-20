import '../server_common/base_server.dart';
import '../server_common/dummy_socket.dart';

abstract class ControlServer extends BaseServer {
  final String authenticationServerAddress;
  final int authenticationServerPort;
  final DummySocket authenticationSocket;

  ControlServer(String name, String address, int port,
      this.authenticationServerAddress, this.authenticationServerPort)
      : authenticationSocket = DummySocket(
            'ws://$authenticationServerAddress:$authenticationServerPort'),
        super(name, address, port);

  @override
  void init() async {
    await super.init();

    await authenticationSocket.start();
    print('connected to authentication server $authenticationServerAddress:$authenticationServerPort');
    authenticationSocket.send('${name}_server_handshake');
    print('sent handshake');
  }
}
