import 'dart:async';
import 'dart:io';

import 'package:code_tanks/src/server/server_common/base_server.dart';
import 'package:quiver/collection.dart';

import '../../../code_tanks_server_common.dart';
import '../authentication_server/authentication_database.dart';

class AuthenticationServer extends BaseServer {
  final List<String> gameServerAddresses;
  final List<String> buildServerAddresses;

  final gameServerSockets = <String, ServerWebSocket>{};
  final buildServerSockets = <String, ServerWebSocket>{};

  final AuthenticationDatabase authenticationDatabase;
  final userNameToBuildServerBiMap = BiMap<String, String>();

  AuthenticationServer(String address, int port, this.gameServerAddresses,
      this.buildServerAddresses, String redisAddress, int redisPort)
      : authenticationDatabase =
            AuthenticationDatabase(redisAddress, redisPort),
        super('authentication', address, port) {
    print('game server urls: $gameServerAddresses');
    print('build server urls: $buildServerAddresses');
  }

  @override
  void init() async {
    await super.init();
    await authenticationDatabase.init();
  }

  @override
  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    socket
      ..on('game_server_handshake', () {
        final address = req.connectionInfo.remoteAddress.address;

        print('handshake from game server $address');

        if (!gameServerAddresses.contains(address)) {
          print('address is not a valid game server $address');
          return;
        }

        if (gameServerSockets.containsKey(address)) {
          print('game server already connected: $address');
          return;
        }

        gameServerSockets[address] = socket;
        print('game server handshake success');
      })
      ..on('build_server_handshake', () {
        final address = req.connectionInfo.remoteAddress.address;

        print('handshake from build server $address');

        if (!buildServerAddresses.contains(address)) {
          print('address is not a valid build server $address');
          return;
        }
        if (buildServerSockets.containsKey(address)) {
          print('build server already connected: $address');
          return;
        }

        buildServerSockets[address] = socket;
        print('build server handshake success');
      })
      ..on('web_server_handshake', () {
        final address = req.connectionInfo.remoteAddress.address;

        print('handshake from web server $address');
        print('web server handshake success');
      })
      ..on('register', (data) => onRegister(socket, data))
      ..on('login', (data) => onLogin(socket, data))
      ..on('logout', () => onLogout(socket));
  }

  @override
  void handleSocketDone(HttpRequest req, ServerWebSocket socket) {
    if (gameServerSockets.containsValue(socket)) {
      gameServerSockets.remove(socket);
    }

    if (buildServerSockets.containsValue(socket)) {
      buildServerSockets.remove(socket);
    }
  }

  Future<void> onRegister(ServerWebSocket socket, data) async {
    print('register data = $data');
    return;

    await onLogout(socket);

    if (!(data is Map)) {
      print('incorrect data type for registering');
      return;
    }

    final username = '${data["username"]}';
    final password = '${data["password"]}';

    if (username == null ||
        username.trim().isEmpty ||
        username.toLowerCase() == 'null') {
      print('invalid username/password');
      return;
    }

    // search for username
    final searchResult =
        await authenticationDatabase.send_object(['HGET', 'users', username]);

    print(searchResult);

    if (password == null ||
        password.trim().isEmpty ||
        password.toLowerCase() == 'null') {
      print('invalid username/password');
      return;
    }
  }

  Future<void> onLogin(ServerWebSocket socket, data) async {
    print('login data = $data');
    return;
  }

  Future<void> onLogout(ServerWebSocket socket) async {}
}

// class DerpServer {
//   final String address;
//   final int port;
//   final List<String> gameServerAddresses;
//   final List<String> buildServerAddresses;

//   HttpServer server;
//   StreamSubscription<HttpRequest> sub;

//   final gameServerSockets = <String, ServerWebSocket>{};
//   final buildServerSockets = <String, ServerWebSocket>{};

//   final AuthenticationDatabase authenticationDatabase;

//   DerpServer(this.address, this.port, this.gameServerAddresses,
//       this.buildServerAddresses, String redisAddress, int redisPort)
//       : authenticationDatabase =
//             AuthenticationDatabase(redisAddress, redisPort) {
//     print('game server urls: $gameServerAddresses');
//     print('build server urls: $buildServerAddresses');
//   }

//   final userNameToBuildServerBiMap = BiMap<String, String>();

//   void init() async {
//     server = await HttpServer.bind(address, port);
//     server.idleTimeout = null;

//     sub = server.listen(onRequest);

//     print('auth server started at $address:$port');

//     await authenticationDatabase.init();
//   }

//   void onRequest(HttpRequest req) async {
//     // handle websocket connection
//     if (WebSocketTransformer.isUpgradeRequest(req)) {
//       final socket = ServerWebSocket.upgradeRequest(req);

//       await socket.start();

//       handleSocketStart(req, socket);

//       await socket.done;

//       handleSocketDone(socket);
//     }
//   }

//   void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
//     socket
//       ..on('game_server_handshake', () {
//         final address = req.connectionInfo.remoteAddress.address;

//         print('handshake from game server $address');

//         if (!gameServerAddresses.contains(address)) {
//           print('address is not a valid game server $address');
//           return;
//         }

//         if (gameServerSockets.containsKey(address)) {
//           print('game server already connected: $address');
//           return;
//         }

//         gameServerSockets[address] = socket;
//         print('game server handshake success');
//       })
//       ..on('build_server_handshake', () {
//         final address = req.connectionInfo.remoteAddress.address;

//         print('handshake from build server $address');

//         if (!buildServerAddresses.contains(address)) {
//           print('address is not a valid build server $address');
//           return;
//         }
//         if (buildServerSockets.containsKey(address)) {
//           print('build server already connected: $address');
//           return;
//         }

//         buildServerSockets[address] = socket;
//         print('build server handshake success');
//       })
//       ..on('web_server_handshake', () {
//         final address = req.connectionInfo.remoteAddress.address;

//         print('handshake from web server $address');
//         print('web server handshake success');
//       })
//       ..on('register', (data) => onRegister(socket, data))
//       ..on('login', (data) => onLogin(socket, data))
//       ..on('logout', () => onLogout(socket));
//   }

//   void handleSocketDone(ServerWebSocket socket) {
//     if (gameServerSockets.containsValue(socket)) {
//       gameServerSockets.remove(socket);
//     }

//     if (buildServerSockets.containsValue(socket)) {
//       buildServerSockets.remove(socket);
//     }
//   }

//   Future close() async {
//     await sub.cancel();

//     print('authentication server closed at $address:$port');
//   }

//   Future<void> onRegister(ServerWebSocket socket, data) async {
//     await onLogout(socket);

//     if (!(data is Map)) {
//       print('incorrect data type for registering');
//       return;
//     }

//     final username = '${data["username"]}';
//     final password = '${data["password"]}';

//     if (username == null ||
//         username.trim().isEmpty ||
//         username.toLowerCase() == 'null') {
//       print('invalid username/password');
//       return;
//     }

//     // search for username
//     final searchResult =
//         await authenticationDatabase.send_object(['HGET', 'users', username]);

//     print(searchResult);

//     if (password == null ||
//         password.trim().isEmpty ||
//         password.toLowerCase() == 'null') {
//       print('invalid username/password');
//       return;
//     }
//   }

//   Future<void> onLogin(ServerWebSocket socket, data) async {}

//   Future<void> onLogout(ServerWebSocket socket) async {}
// }
