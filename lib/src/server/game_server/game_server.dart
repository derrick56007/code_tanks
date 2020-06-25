
import '../server_common/dummy_server.dart';


class GameServer extends DummyServer {
  GameServer(String address, int port, String authenticationServerAddress,
      int authenticationServerPort)
      : super('game', authenticationServerAddress,
            authenticationServerPort);
}
