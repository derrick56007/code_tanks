import 'dart:async';
import 'dart:io';

import 'package:code_tanks/src/server/server_common/base_server.dart';
import 'package:quiver/collection.dart';

import '../../../code_tanks_server_common.dart';
import '../authentication_server/authentication_database.dart';

class AuthenticationServer extends BaseServer {
  final gameServerAddresses = TreeSet<String>();
  final buildServerAddresses = TreeSet<String>();

  final gameServerSockets = <String, ServerWebSocket>{};
  final buildServerSockets = <String, ServerWebSocket>{};

  final AuthenticationDatabase authDb;
  final userNameToBuildServerBiMap = BiMap<String, String>();
  final loggedInSockets = TreeSet<ServerWebSocket>();

  AuthenticationServer(
      String address,
      int port,
      List<String> _gameServerAddresses,
      List<String> _buildServerAddresses,
      String redisAddress,
      int redisPort)
      : authDb = AuthenticationDatabase(redisAddress, redisPort),
        super('authentication', address, port) {
    print('game server urls: $_gameServerAddresses');
    print('build server urls: $_buildServerAddresses');

    gameServerAddresses.addAll(_gameServerAddresses);
    buildServerAddresses.addAll(_buildServerAddresses);
  }

  @override
  void init() async {
    await super.init();
    await authDb.init();
  }

  @override
  void handleSocketStart(HttpRequest req, ServerWebSocket socket) {
    socket
      ..on('build_server_handshake', () => onBuildServerHandshake(req, socket))
      ..on('game_server_handshake', () => onGameServerHandshake(req, socket))
      ..on('web_server_handshake', () => onWebServerHandshake(req, socket))
      ..on('register', (data) => onRegister(socket, data))
      ..on('login', (data) => onLogin(socket, data))
      ..on('logout', () => onLogout(socket));
  }

  @override
  void handleSocketDone(HttpRequest req, ServerWebSocket socket) {
    final address = req.connectionInfo.remoteAddress.address;

    gameServerSockets.remove(address);
    buildServerSockets.remove(address);
  }

  void onBuildServerHandshake(HttpRequest req, ServerWebSocket socket) {
    final address = req.connectionInfo.remoteAddress.address;

    print('handshake from build server $address');

    if (buildServerAddresses.lookup(address) == null) {
      print('address is not a valid build server $address');
      return;
    }
    if (buildServerSockets.containsKey(address)) {
      print('build server already connected: $address');
      return;
    }

    buildServerSockets[address] = socket;
    print('build server handshake success');
  }

  void onGameServerHandshake(HttpRequest req, ServerWebSocket socket) {
    final address = req.connectionInfo.remoteAddress.address;

    print('handshake from game server $address');

    if (gameServerAddresses.lookup(address) == null) {
      print('address is not a valid game server $address');
      return;
    }

    if (gameServerSockets.containsKey(address)) {
      print('game server already connected: $address');
      return;
    }

    gameServerSockets[address] = socket;
    print('game server handshake success');
  }

  void onWebServerHandshake(HttpRequest req, ServerWebSocket socket) {
    final address = req.connectionInfo.remoteAddress.address;

    print('handshake from web server $address');
    print('web server handshake success');
  }

  static bool isValidUsername(String username) {
    return username != null &&
        username.trim().isNotEmpty &&
        username.toLowerCase() != 'null';
  }

  static bool isValidPassword(String password) {
    return password != null &&
        password.trim().isNotEmpty &&
        password.toLowerCase() != 'null';
  }

  Future<void> onRegister(ServerWebSocket socket, data) async {
    print('register data = $data');

    logoutSocket(socket);

    if (!(data is Map)) {
      print('incorrect data type for registering');
      return;
    }

    final username = '${data["username"]}';

    if (!isValidUsername(username)) {
      print('invalid username/password');
      socket.send('register_failure', 'invalid username/password');
      return;
    }

    // search for username
    final searchResults = await authDb.getUserIdFromUsername(username);

    if (searchResults != 'null') {
      print('username $username already exists');

      socket.send(
          'register_failure', 'failed to register $username; username exists');
      return;
    }

    final password = '${data["password"]}';

    // validate password
    if (!isValidPassword(password)) {
      print('invalid username/password');
      socket.send('register_failure', 'invalid username/password');
      return;
    }

    final nextUserId = await authDb.getNextUserId();

    final hashedPassword = hashPassword(password);

    if (await authDb.registerUsernameWithHashedPassword(
        nextUserId, username, hashedPassword)) {
      socket.send('register_failure', 'failed to register $username');
      return;
    }

    print('registered $username successfully');

    socket.send('register_successful');
  }

  Future<void> onLogin(ServerWebSocket socket, data) async {
    print('login data = $data');

    logoutSocket(socket);

    if (!(data is Map)) {
      print('incorrect data type for login');
      return;
    }

    final username = '${data["username"]}';

    if (!isValidUsername(username)) {
      print('invalid username/password');
      socket.send('login_failure', 'invalid username/password');

      return;
    }

    // search for username
    final userId = await authDb.getUserIdFromUsername(username);

    if (userId == 'null') {
      print('username $username does not exist');

      socket.send('login_failure', 'invalid username/password');
      return;
    }

    final password = '${data["password"]}';

    // validate password
    if (!isValidPassword(password)) {
      print('invalid username/password');
      socket.send('login_failure', 'invalid username/password');
      return;
    }

    final realHashedPassword = await authDb.getHashedPasswordFromUserId(userId);

    final hashedPassword = hashPassword(password);

    if (hashedPassword != realHashedPassword) {
      print('invalid username/password');
      socket.send('login_failure', 'invalid username/password');
      return;
    }

    print('logged in $username successfully');

    loggedInSockets.add(socket);

    socket.send('login_successful');
  }

  bool isLoggedIn(ServerWebSocket socket) => loggedInSockets.contains(socket);

  void onLogout(ServerWebSocket socket) {
    final logoutSuccessful = logoutSocket(socket);

    if (!logoutSuccessful) {
      return;
    }

    socket.send('logout_successful');
  }

  bool logoutSocket(ServerWebSocket socket) => loggedInSockets.remove(socket);

  static String hashPassword(String password) {
    // TODO
    return password;
  }
}
