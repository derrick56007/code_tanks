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

  final AuthenticationDatabase authDb;
  final userNameToBuildServerBiMap = BiMap<String, String>();

  AuthenticationServer(String address, int port, this.gameServerAddresses,
      this.buildServerAddresses, String redisAddress, int redisPort)
      : authDb = AuthenticationDatabase(redisAddress, redisPort),
        super('authentication', address, port) {
    print('game server urls: $gameServerAddresses');
    print('build server urls: $buildServerAddresses');
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
      ..on('logout', (data) => onLogout(socket, data));
  }

  @override
  void handleSocketDone(HttpRequest req, ServerWebSocket socket) {
    final address = req.connectionInfo.remoteAddress.address;

    if (gameServerSockets.containsValue(address)) {
      gameServerSockets.remove(address);
    }

    if (buildServerSockets.containsValue(address)) {
      buildServerSockets.remove(address);
    }
  }

  void onBuildServerHandshake(HttpRequest req, ServerWebSocket socket) {
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
  }

  void onGameServerHandshake(HttpRequest req, ServerWebSocket socket) {
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

    await onLogout(socket, data);

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

    final authToken = generateAuthenticationToken();

    final m = {'auth_token': authToken};

    await authDb.deleteAuthTokenOfUserId(userId);
    await authDb.setUserIDAuthToken(userId, authToken);

    socket.send('login_successful', m);
  }

  Future<bool> isLoggedIn(String authToken) async {
    final userId = await authDb.getUserIdFromAuthToken(authToken);

    if (userId == 'null') {
      return false;
    }

    final authTokenForFoundUserId = await authDb.getAuthTokenFromUserId(userId);

    return authToken == authTokenForFoundUserId;
  }

  Future<void> onLogout(ServerWebSocket socket, data) async {
    if (!(data is Map)) {
      print('wrong data type = $data');
      return;
    }

    final authToken = data['auth_token'];
    if (authToken == null) {
      print('no auth token');
      return;
    }

    if (!(await isLoggedIn(authToken))) {
      print('not logged in');
      return;
    }

    final userId = await authDb.getUserIdFromAuthToken(authToken);

    await authDb.deleteAuthTokenOfUserId(userId);
  }

  static String hashPassword(String password) {
    // TODO
    return password;
  }

  static String generateAuthenticationToken() {
    // TODO
    return Object().hashCode.toString();
  }
}
