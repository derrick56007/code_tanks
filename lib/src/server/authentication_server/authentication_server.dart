import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:code_tanks/src/server/authentication_server/default_tanks/default_tanks.dart';
import 'package:code_tanks/src/server/server_common/base_server.dart';
import 'package:code_tanks/src/server/server_utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:quiver/collection.dart';

import '../../../code_tanks_server_common.dart';
import '../authentication_server/authentication_database.dart';

class AuthenticationServer extends BaseServer {
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
    socket
      ..on('build_server_handshake', () => onBuildServerHandshake(req, socket))
      ..on('game_server_handshake', () => onGameServerHandshake(req, socket))
      ..on('web_server_handshake', () => onWebServerHandshake(req, socket))
      ..on('register', (data) => onRegister(socket, data))
      ..on('login', (data) => onLogin(socket, data))
      ..on('logout', () => onLogout(socket))
      ..on('build_code', (data) => onBuildCode(socket, data));
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

    if (!buildServerAddresses.contains(address)) {
      print('address is not a valid build server $address');
      return;
    }
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

      attemptBuildCode(codeLang, code, onSuccess: (tankId) async {
        print('built default tank $tankName');

        await authDb.saveTankIdForUser('default_tanks', tankName, tankId);
      });
    }

    builtDefaultTanks = true;
  }

  void onGameServerHandshake(HttpRequest req, ServerWebSocket socket) {
    final address = req.connectionInfo.remoteAddress.address;

    print('handshake from game server $address');

    if (!gameServerAddresses.contains(address)) {
      print('address is not a valid game server $address');
      return;
    }

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

    final hashedPassword = hashPassword(password);

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

    final hashedPassword = hashPassword(password);

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

  static String hashPassword(String password) {
    // TODO
    return password;
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

    attemptBuildCode(codeLang, code, onSuccess: (tankId) async {
      const msg = {'success': true};

      socket.send('build_done', msg);

      final userId = getUserIdFromSocket(socket);

      final saved = await authDb.saveTankIdForUser(userId, tankName, tankId);

      if (saved) {
        print('saved custom tank');
      } else {
        print('error saving custom tank');
      }
    }, onError: () {
      socket.send('build_done', failMsg);
    }, onLog: (line) {
      final msg = {'line': line};
      socket.send('log', msg);
    });
  }

  void attemptBuildCode(String codeLang, String code,
      {Function onSuccess, Function onError, Function onLog}) async {
    final codeLangWithCode = '$codeLang$code';

    final hashedCodeUpload = hashCodeUpload(codeLang, code);

    var uuid =
        await authDb.getCodeUploadUuid(hashedCodeUpload, codeLangWithCode);

    if (uuid != 'null') {
      // uuid exists
      print('uuid already built');

      onSuccess(uuid);
      return;
    }

    final tempUuid = Utils.createRandomString(10);

    // send to build server
    final buildServerSocket = getAnyBuildServerSocket();

    Function removeDispatches = () {
      buildServerSocket
        ..removeDispatch('build_code_success_$tempUuid')
        ..removeDispatch('build_code_error_$tempUuid')
        ..removeDispatch('build_code_log_part_$tempUuid')
        ..removeDispatch('push_code_log_part_$tempUuid');
    };

    buildServerSocket
      ..on('build_code_success_$tempUuid', () async {
        // remove dispatch
        removeDispatches();

        uuid =
            await authDb.getCodeUploadUuid(hashedCodeUpload, codeLangWithCode);

        if (uuid != 'null') {
          // this means that before this build was completed, a duplicate code upload finished building first
          print('uuid already built');
          if (onSuccess != null) {
            onSuccess(uuid);
          }
          return;
        }

        if (onSuccess != null) {
          onSuccess(tempUuid);
        }

        final saved = await authDb.saveCodeUploadHash(
            hashedCodeUpload, codeLangWithCode, tempUuid);

        if (saved) {
          print('saved code upload hash');
        } else {
          print('error saving code upload hash');
        }
      })
      ..on('build_code_error_$tempUuid', (data) {
        // remove dispatch
        removeDispatches();

        if (onError != null) {
          onError();
        }
      })
      ..on('build_code_log_part_$tempUuid', (line) {
        print('build_code_log_part_$tempUuid: $line');

        if (onLog != null) {
          onLog(line);
        }
      })
      ..on('push_code_log_part_$tempUuid', (line) {
        print('push_code_log_part_$tempUuid: $line');

        if (onLog != null) {
          onLog(line);
        }
      });

    final msg = {'code_language': codeLang, 'code': code, 'uuid': tempUuid};

    buildServerSocket.send('build_code', msg);
  }

  ServerWebSocket getAnyBuildServerSocket() {
    return buildServerSockets.keys.first;
  }

  ServerWebSocket getAnyGameServer() {
    return gameServerSockets.keys.first;
  }
}
