import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:code_tanks/src/server/authentication_server/default_tanks/default_tanks.dart';
import 'package:code_tanks/src/server/server_common/base_server.dart';
import 'package:code_tanks/src/server/server_utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:password_hash/password_hash.dart';
import 'package:quiver/collection.dart';

import '../../../code_tanks_server_common.dart';
import '../authentication_server/authentication_database.dart';

class AuthenticationServer extends BaseServer {
  static final _pbkdf2 = PBKDF2();

  final gameServerAddresses = <String>[];
  final buildServerAddresses = <String>[];

  final gameServerSockets = BiMap<ServerWebSocket, String>();
  final buildServerSockets = BiMap<ServerWebSocket, String>();

  final AuthenticationDatabase authDb;
  final userNameToBuildServerBiMap = BiMap<String, String>();
  final loggedInSockets = <ServerWebSocket, String>{};

  bool builtDefaultTanks = false;

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
    print('socket start ${req.connectionInfo.remoteAddress.address}');

    if (requestFromBuildServer(req)) {
      socket.on(
          'build_server_handshake', () => onBuildServerHandshake(req, socket));
    }

    if (requestFromGameServer(req)) {
      socket.on(
          'game_server_handshake', () => onGameServerHandshake(req, socket));
    }

    // ..on('web_server_handshake', () => onWebServerHandshake(req, socket))
    socket
      ..on('register', (data) => onRegister(socket, data))
      ..on('login', (data) => onLogin(socket, data))
      ..on('logout', () => onLogout(socket))
      ..on('build_code', (data) => onBuildCode(socket, data))
      ..on('run_game', (data) => onRunGame(socket, data));
  }

  bool requestFromBuildServer(HttpRequest req) {
    final address = req.connectionInfo.remoteAddress.address;

    return buildServerAddresses.contains(address);
  }

  bool requestFromGameServer(HttpRequest req) {
    final address = req.connectionInfo.remoteAddress.address;

    return gameServerAddresses.contains(address);
  }

  @override
  void handleSocketDone(HttpRequest req, ServerWebSocket socket) {
    // req.connectionInfo will be null here
    // final address = req.connectionInfo.remoteAddress.address;

    gameServerSockets.remove(socket);
    buildServerSockets.remove(socket);

    logoutSocket(socket);
  }

  void onBuildServerHandshake(HttpRequest req, ServerWebSocket socket) {
    final address = req.connectionInfo.remoteAddress.address;

    print('handshake from build server $address');

    if (buildServerSockets.inverse.containsKey(address)) {
      print('build server already connected: $address');
      return;
    }

    buildServerSockets[socket] = address;
    print('build server handshake success');

    onAnyBuildServerConnected(socket);
  }

  void onAnyBuildServerConnected(ServerWebSocket socket) {
    if (!builtDefaultTanks) {
      print('building default tanks');

      buildDefaultTanks();
    }
  }

  void buildDefaultTanks() async {
    // TODO find better way to ensure default tanks are built
    for (final tankMap in DefaultTanks.tankMap.values) {
      final code = tankMap['code'];
      final codeLang = tankMap['code_language'];
      final tankName = tankMap['tank_name'];

      if (!isValidCodeUpload(codeLang, code, tankName)) {
        print('invalid code upload');
        return;
      }

      attemptBuildCode(codeLang, code, onBuildSuccess: (tankId) async {
        print('built default tank $tankName');

        await authDb.saveTankIdForUser('default_tanks', tankName, tankId);
      }, onAlreadyBuilt: () {
        print('already built default tank $tankName');
      });
    }

    builtDefaultTanks = true;
  }

  void onGameServerHandshake(HttpRequest req, ServerWebSocket socket) {
    final address = req.connectionInfo.remoteAddress.address;

    // print('handshake from game server $address');

    if (gameServerSockets.inverse.containsKey(address)) {
      print('game server already connected: $address');
      return;
    }

    gameServerSockets[socket] = address;
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
        username.toLowerCase() != 'null' &&
        username.toLowerCase() != 'default_tanks';
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

    final saltLength = 24;
    final salt = Salt.generateAsBase64String(saltLength);
    final hashedPassword = hashPassword(password, salt);

    if (!(await authDb.registerUsernameWithHashedPassword(
        nextUserId, username, hashedPassword))) {
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

    final saltStringLength = 32;
    final salt = realHashedPassword.substring(0, saltStringLength);
    final hashedPassword = hashPassword(password, salt);

    if (hashedPassword != realHashedPassword) {
      print('invalid username/password');
      socket.send('login_failure', 'invalid username/password');
      return;
    }

    print('logged in $username successfully');

    loggedInSockets[socket] = userId;

    socket.send('login_successful');
  }

  bool isLoggedIn(ServerWebSocket socket) =>
      loggedInSockets.containsKey(socket);

  String getUserIdFromSocket(ServerWebSocket socket) => loggedInSockets[socket];

  void onLogout(ServerWebSocket socket) {
    final logoutSuccessful = logoutSocket(socket);

    if (!logoutSuccessful) {
      return;
    }

    socket.send('logout_successful');
  }

  bool logoutSocket(ServerWebSocket socket) {
    return loggedInSockets.remove(socket) != null;
  }

  static String hashPassword(String password, String salt) {
    final hash = _pbkdf2.generateKey(password, salt, 1000, 32);
    final hashString = String.fromCharCodes(hash);
    return '$salt$hashString';
  }

  bool isValidCodeUpload(String codeLang, String code, String tankName) {
    if (codeLang == null || codeLang.trim().isEmpty) {
      return false;
    }

    // TODO check if string is greater than 512 MB
    // https://redis.io/topics/data-types-intro#:~:text=Redis%20keys%20are%20binary%20safe,are%20not%20a%20good%20idea.
    if (code == null || code.trim().isEmpty) {
      return false;
    }

    if (tankName == null || tankName.trim().isEmpty) {
      return false;
    }

    return true;
  }

  String hashCodeUpload(String codeLang, String code) {
    final codeLangWithCode = '$codeLang$code';

    final bytes = utf8.encode(codeLangWithCode); // data being hashed

    return sha1.convert(bytes).toString();
  }

  String cleanCode(String code) {
    return code;
  }

  Future<void> onBuildCode(ServerWebSocket socket, data) async {
    const failMsg = {'success': false};
    if (!isLoggedIn(socket)) {
      const logMsg = {'line': 'need to be logged in to build code'};
      print('need to be logged in to build code');
      socket.send('log', logMsg);
      socket.send('build_done', failMsg);
      return;
    }

    if (!(data is Map)) {
      const logMsg = {'line': 'incorrect data type for build'};

      print('incorrect data type for build');
      socket.send('log', logMsg);

      socket.send('build_done', failMsg);
      return;
    }

    final code = cleanCode(data['code']);
    final codeLang = data['code_language'];
    final tankName = data['tank_name'];

    if (!isValidCodeUpload(codeLang, code, tankName)) {
      const logMsg = {'line': 'invalid code upload'};
      print('invalid code upload');

      socket.send('log', logMsg);
      socket.send('build_done', failMsg);
      return;
    }

    attemptBuildCode(codeLang, code, onBuildSuccess: (tankId) async {
      const msg = {'success': true};

      socket.send('build_done', msg);

      final userId = getUserIdFromSocket(socket);

      print('saving for user $userId, $tankName, $tankId');
      final saved = await authDb.saveTankIdForUser(userId, tankName, tankId);

      if (saved) {
        print('saved custom tank for user $userId');
      } else {
        print('error saving custom tank');
      }
    }, onAlreadyBuilt: () {
      const msg = {'success': true};

      socket.send('build_done', msg);
      print('tank already built');

      const l = {'line': 'tank already built'};

      socket.send('log', l);
    }, onBuildError: () {
      socket.send('build_done', failMsg);
    }, onLog: (line) {
      final msg = {'line': line};
      socket.send('log', msg);
    });
  }

  static void defaultOnBuildSuccess(String tankUuid) {}

  static void defaultOnAlreadyBuilt() {}

  static void defaultOnBuildError() {}

  static void defaultOnBuildLogPart(String line) {}

  void attemptBuildCode(String codeLang, String code,
      {void Function(String tankUuid) onBuildSuccess = defaultOnBuildSuccess,
      void Function() onAlreadyBuilt = defaultOnAlreadyBuilt,
      void Function() onBuildError = defaultOnBuildError,
      void Function(String line) onLog = defaultOnBuildLogPart}) async {
    final codeLangWithCode = '$codeLang$code';

    final hashedCodeUpload = hashCodeUpload(codeLang, code);

    if ((await authDb.getCodeUploadUuid(hashedCodeUpload, codeLangWithCode)) !=
        'null') {
      // uuid exists
      onAlreadyBuilt();
      return;
    }

    final newUuid = Utils.createRandomString(10);

    // send to build server
    final buildServerSocket = getAnyBuildServerSocket();

    void removeDispatches() {
      buildServerSocket
        ..removeDispatch('build_code_success_$newUuid')
        ..removeDispatch('build_code_error_$newUuid')
        ..removeDispatch('build_code_log_part_$newUuid')
        ..removeDispatch('push_code_log_part_$newUuid');
    }

    Future<void> _handleSuccess() async {
// remove dispatch
      removeDispatches();

      if ((await authDb.getCodeUploadUuid(
              hashedCodeUpload, codeLangWithCode)) !=
          'null') {
        // this means that before this build was completed, a duplicate code upload finished building first
        onAlreadyBuilt();
        return;
      }

      onBuildSuccess(newUuid);

      final saved = await authDb.saveCodeUploadHash(
          hashedCodeUpload, codeLangWithCode, newUuid);

      if (saved) {
        print('saved code upload hash');
      } else {
        print('error saving code upload hash');
      }
    }

    void _handleError() {
      // remove dispatch
      removeDispatches();

      onBuildError();
    }

    void _handleBuildLog(String line) {
      print('build_code_log_part_$newUuid: $line');

      onLog(line);
    }

    void _handlePushLog(String line) {
      print('push_code_log_part_$newUuid: $line');

      onLog(line);
    }

    buildServerSocket
      ..on('build_code_success_$newUuid', _handleSuccess)
      ..on('build_code_error_$newUuid', _handleError)
      ..on('build_code_log_part_$newUuid', _handleBuildLog)
      ..on('push_code_log_part_$newUuid', _handlePushLog);

    final msg = {'code_language': codeLang, 'code': code, 'uuid': newUuid};
    buildServerSocket.send('build_code', msg);
  }

  ServerWebSocket getAnyBuildServerSocket() {
    return buildServerSockets.keys.first;
  }

  ServerWebSocket getAnyGameServer() {
    return gameServerSockets.keys.first;
  }

  void onRunGame(ServerWebSocket socket, data) async {
    // TODO validate data
    if (!isLoggedIn(socket)) {
      return;
    }

    final tankNames = data['tank_names'];

    final gameKeyToTankIds = <String, String>{};

    final userId = getUserIdFromSocket(socket);

    for (final tankName in tankNames) {
      final tankId = await authDb.getTankIdFromTankName(userId, tankName);

      if (tankId == 'null') {
        print('failed getting tankId from tankname');
        return;
      }

      String gameKey;

      do {
        gameKey = Utils.createRandomString(10);
      } while (gameKeyToTankIds.containsKey(gameKey));

      gameKeyToTankIds[gameKey] = tankId;
    }

    final nextGameId = await authDb.getNextGameId();

    final gameServer = getAnyGameServer();

    final msg = {'game_id': nextGameId, 'game_keys': gameKeyToTankIds};
    gameServer.send('run_game', msg);
  }
}
