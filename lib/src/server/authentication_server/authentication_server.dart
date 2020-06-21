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
    final searchResults = '${await authenticationDatabase.send_object([
      'HGET',
      'users',
      username
    ])}';

    print('search results for $username = $searchResults');
    if (searchResults != 'null') {
      print('username $username already exists');

      socket.send('register_failure', 'failed to register $username');
      return;
    }

    if (password == null ||
        password.trim().isEmpty ||
        password.toLowerCase() == 'null') {
      print('invalid username/password');
      return;
    }

    final nextUserId =
        '${await authenticationDatabase.send_object(['INCR', 'next_user_id'])}';

    final primaryKey = 'user:$nextUserId';

    // TODO store hashed password
    final registerResults = '${await authenticationDatabase.send_object([
      'HMSET',
      primaryKey,
      'username',
      username,
      'password',
      password
    ])}';
    final register2Results = '${await authenticationDatabase.send_object([
      'HSET',
      'users',
      username,
      nextUserId
    ])}';

    print('registered with results = $registerResults, $register2Results');

    if (registerResults != 'OK') {
      socket.send('register_failure', 'failed to register $username');
      return;
    }

    print('registered $username successfully');

    final randomString = '${socket.hashCode}';

    socket.send('register_successful',
        {'username': username, 'session-token': randomString});
  }

  Future<void> onLogin(ServerWebSocket socket, data) async {
    print('login data = $data');
    return;
  }

  Future<void> onLogout(ServerWebSocket socket) async {}
}
