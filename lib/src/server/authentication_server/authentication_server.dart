import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:password_hash/password_hash.dart';
import 'package:quiver/collection.dart';

import '../server_common/base_server.dart';
import '../server_utils/utils.dart';
import '../../../code_tanks_server_common.dart';
import 'authentication_database.dart';

class AuthenticationServer extends BaseServer {
  static final _pbkdf2 = PBKDF2();

  final gameServerAddresses = <String>[];
  final buildServerAddresses = <String>[];

  final gameServerSockets = BiMap<ServerWebSocket, String>();
  final buildServerSockets = BiMap<ServerWebSocket, String>();

  final AuthenticationDatabase authDb;
  final userNameToBuildServerBiMap = BiMap<String, String>();
  final loggedInSockets = <ServerWebSocket, String>{};

  // bool builtDefaultTanks = false;

  AuthenticationServer(String address, int port, List<String> _gameServerAddresses, List<String> _buildServerAddresses,
      String redisAddress, int redisPort)
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
      socket.on('build_server_handshake', (_) => onBuildServerHandshake(req, socket));
    }

    if (requestFromGameServer(req)) {
      socket.on('game_server_handshake', (_) => onGameServerHandshake(req, socket));
    }

    socket
      ..on('register', (data) => onRegister(socket, data))
      ..on('login', (data) => onLogin(socket, data))
      ..on('logout', (_) => onLogout(socket))
      ..on('create_new_tank', (data) => onCreateNewTank(socket, data))
      ..on('make_tank_copy', (data) => onMakeTakeCopy(socket, data))
      ..on('open_existing_tank', (data) => onOpenExistingTank(socket, data))
      ..on('delete_tank', (data) => onDeleteTank(socket, data))
      ..on('rename_tank', (data) => onRenameTank(socket, data))
      ..on('save_tank', (data) => onSaveTank(socket, data))
      ..on('save_tank_as', (data) => onSaveTankAs(socket, data))
      ..on('build_code', (data) => onBuildCode(socket, data))
      ..on('run_game', (data) => onRunGame(socket, data))
      ..on('get_built_tanks', (_) => onGetBuiltTanks(socket))
      ..on('get_saved_tanks', (_) => onGetSavedTanks(socket));
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
    // if (!builtDefaultTanks) {
    //   print('building default tanks');

    //   buildDefaultTanks();
    // }
  }

  // void buildDefaultTanks() async {
  //   // TODO find better way to ensure default tanks are built
  //   for (final tankMap in DefaultTanks.tankMap.values) {
  //     final code = tankMap['code'];
  //     final codeLang = tankMap['code_language'];
  //     final tankName = tankMap['tank_name'];

  //     if (!isValidCodeUpload(codeLang, code, tankName)) {
  //       print('invalid code upload');
  //       return;
  //     }

  //     attemptBuildCode(codeLang, code, onBuildSuccess: (tankId) async {
  //       print('built default tank $tankName');

  //       await authDb.saveTankIdForUser('default_tanks', tankName, tankId);
  //     }, onAlreadyBuilt: () {
  //       print('already built default tank $tankName');
  //     });
  //   }

  //   builtDefaultTanks = true;
  // }

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
    return password != null && password.trim().isNotEmpty && password.toLowerCase() != 'null';
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

      socket.send('register_failure', 'failed to register $username; username exists');
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

    if (!(await authDb.registerUsernameWithHashedPassword(nextUserId, username, hashedPassword))) {
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

  bool isLoggedIn(ServerWebSocket socket) => loggedInSockets.containsKey(socket);

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

  String hashCodeUpload(String codeLang, String code) => sha1.convert(utf8.encode('$codeLang$code')).toString();

  String cleanCode(String code) {
    return code;
  }

  Future<void> onBuildCode(ServerWebSocket socket, data) async {
    await onSaveTank(socket, data);

    const failMsg = {'success': false};
    if (!isLoggedIn(socket)) {
      const logMsg = {'line': 'need to be logged in to build code'};
      print('need to be logged in to build code');
      socket.send('log', logMsg);
      socket.send('build_done', failMsg);
      return onNotLoggedInError(socket);
    }

    if (!(data is Map) || data['code'] == null || data['tank_name'] == null) {
      const logMsg = {'line': 'incorrect data type for build'};

      print('incorrect data type for build');
      socket.send('log', logMsg);

      socket.send('build_done', failMsg);
      return onInvalidDataError(socket);
    }

    final userId = getUserIdFromSocket(socket);

    final code = cleanCode(data['code']);
    final tankName = data['tank_name'];

    final codeLang = await authDb.getCodeLangForUserIdWithTankName(userId, tankName);

    if (!isValidCodeUpload(codeLang, code, tankName)) {
      const logMsg = {'line': 'invalid code upload'};
      print('invalid code upload');

      socket.send('log', logMsg);
      socket.send('build_done', failMsg);
      return onInvalidDataError(socket);
    }

    // alert client of build initialization
    socket.send('log', {'line': 'Initializing build...'});

    await attemptBuildCode(codeLang, code, onBuildSuccess: (tankId) async {
      const msg = {'success': true};

      socket.send('build_done', msg);

      print('saving for user $userId, $tankName, $tankId');
      final saved = await authDb.saveTankIdForUser(userId, tankName, tankId);

      if (saved) {
        print('saved custom tank for user $userId');
      } else {
        print('error saving custom tank');
      }

      // alert client of build success
      socket.send('log', {'line': '$tankName successfully built'});
    }, onAlreadyBuilt: (tankId) async {
      const msg = {'success': true};

      socket.send('build_done', msg);
      print('tank already built');
      await authDb.saveTankIdForUser(userId, tankName, tankId);

      socket.send('log', {'line': '$tankName already built'});
    }, onBuildError: () {
      socket.send('build_done', failMsg);
    }, onLog: (line) {
      final msg = {'line': line};
      socket.send('log', msg);
    });
  }

  static void defaultOnBuildSuccess(String tankUuid) {}

  static void defaultOnAlreadyBuilt(String tankUuid) {}

  static void defaultOnBuildError() {}

  static void defaultOnBuildLogPart(String line) {}

  Future<void> attemptBuildCode(String codeLang, String code,
      {void Function(String tankUuid) onBuildSuccess = defaultOnBuildSuccess,
      void Function(String tankUuid) onAlreadyBuilt = defaultOnAlreadyBuilt,
      void Function() onBuildError = defaultOnBuildError,
      void Function(String line) onLog = defaultOnBuildLogPart}) async {
    final codeLangWithCode = '$codeLang$code';

    final hashedCodeUpload = hashCodeUpload(codeLang, code);

    final alreadyBuiltId = await authDb.getCodeUploadUuid(hashedCodeUpload, codeLangWithCode);
    if (alreadyBuiltId != 'null') {
      // uuid exists
      onAlreadyBuilt(alreadyBuiltId);
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

    Future<void> _handleSuccess(_) async {
      // remove dispatch
      removeDispatches();

      final alreadyBuiltId = await authDb.getCodeUploadUuid(hashedCodeUpload, codeLangWithCode);

      if (alreadyBuiltId != 'null') {
        // this means that before this build was completed, a duplicate code upload finished building first
        onAlreadyBuilt(alreadyBuiltId);
        return;
      }

      onBuildSuccess(newUuid);

      final saved = await authDb.saveCodeUploadHash(hashedCodeUpload, codeLangWithCode, newUuid);

      if (saved) {
        print('saved code upload hash');
      } else {
        print('error saving code upload hash');
      }
    }

    void _handleError(_) {
      // remove dispatch
      removeDispatches();

      onBuildError();
    }

    void _handleBuildLog(dynamic data) {
      // TODO validate data

      final line = data['line'];

      print('build_code_log_part_$newUuid: $line');

      onLog(line);
    }

    void _handlePushLog(dynamic data) {
      // TODO validate data
      final line = data['line'];

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

  Future<void> onRunGame(ServerWebSocket socket, data) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    if (!(data is Map) || data['tank_names'] == null || !(data['tank_names'] is List)) {
      return onInvalidDataError(socket);
    }

    final tankNames = data['tank_names'];

    final gameKeyToTankIds = <String, String>{};

    final userId = getUserIdFromSocket(socket);

    for (final tankName in tankNames) {
      final tankId = await authDb.getTankIdFromTankName(userId, tankName);

      if (tankId == 'null') {
        print('failed getting tankId from tankname');
        return onInvalidDataError(socket);
      }

      String gameKey;

      do {
        gameKey = Utils.createRandomString(10);
      } while (gameKeyToTankIds.containsKey(gameKey));

      gameKeyToTankIds[gameKey] = tankId;
    }

    if (gameKeyToTankIds.length <= 1) return onInvalidDataError(socket);

    final nextGameId = await authDb.getNextGameId();

    final gameServer = getAnyGameServer();

    final msg = {'game_id': nextGameId, 'game_keys': gameKeyToTankIds};

    final runGameDone = gameServer.onSingleAsync('run_game_response_$nextGameId', (_data) {
      print('received frames');
      socket.send('run_game_response', _data);
    });

    gameServer.send('run_game', msg);

    await runGameDone;
  }

  Future<void> onGetBuiltTanks(ServerWebSocket socket) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    socket.send('built_tanks', {
      'built_tanks': await authDb.getBuiltTankNamesForUserId(getUserIdFromSocket(socket)),
    });
  }

  Future<void> onCreateNewTank(ServerWebSocket socket, data) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    if (!(data is Map) || data['tank_name'] == null || data['code_language'] == null) return onInvalidDataError(socket);

    final userId = getUserIdFromSocket(socket);

    final defaultCodes = <String, String>{
      'dart': '''
import 'package:code_tanks/code_tanks_dart_api.dart';

class Custom extends BaseTank {
  @override
  void run() {}

  @override
  void onScanTank(ScanTankEvent e) {}
}

BaseTank createTank() => Custom();
      ''',
    };

    if (!defaultCodes.containsKey(data['code_language'])) return onInvalidDataError(socket);

    // TODO get default code
    final defaultCode = defaultCodes[data['code_language']];

    if (await authDb.tankNameExists(userId, data['tank_name'])) return onInvalidDataError(socket);

    await authDb.saveCodeLangForUserIdWithTankName(userId, data['tank_name'], data['code_language']);
    await authDb.saveCodeForUserIdWithTankName(userId, data['tank_name'], defaultCode);

    await onOpenExistingTank(socket, data);
  }

  Future<void> onSaveTank(ServerWebSocket socket, data) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    if (!(data is Map) || data['tank_name'] == null || data['code'] == null) return onInvalidDataError(socket);

    final userId = getUserIdFromSocket(socket);

    if (!await authDb.tankNameExists(userId, data['tank_name'])) return onInvalidDataError(socket);

    await authDb.saveCodeForUserIdWithTankName(userId, data['tank_name'], data['code']);
  }

  Future<void> onOpenExistingTank(ServerWebSocket socket, data) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    if (!(data is Map) || data['tank_name'] == null) return onInvalidDataError(socket);

    final userId = getUserIdFromSocket(socket);

    if (await authDb.tankNameExists(userId, data['tank_name'])) {
      socket.send('open_existing_tank_success', {
        'code': await authDb.getCodeForUserIdWithTankName(userId, data['tank_name']),
        'tank_name': data['tank_name'],
      });
    } else {
      socket.send('open_existing_tank_failure');
    }
  }

  Future<void> onGetSavedTanks(ServerWebSocket socket) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    socket.send('saved_tanks', {
      'saved_tanks': await authDb.getSavedTankNamesForUserId(getUserIdFromSocket(socket)),
    });
  }

  Future<void> onSaveTankAs(ServerWebSocket socket, data) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    if (!(data is Map) || data['tank_name'] == null || data['new_tank_name'] == null) return onInvalidDataError(socket);

    final userId = getUserIdFromSocket(socket);

    if (!(await authDb.tankNameExists(userId, data['tank_name']))) return onInvalidDataError(socket);

    if (await authDb.tankNameExists(userId, data['new_tank_name'])) return onInvalidDataError(socket);

    final code = await authDb.getCodeForUserIdWithTankName(userId, data['tank_name']);
    final codeLang = await authDb.getCodeLangForUserIdWithTankName(userId, data['tank_name']);

    await authDb.saveCodeLangForUserIdWithTankName(userId, data['new_tank_name'], codeLang);
    await authDb.saveCodeForUserIdWithTankName(userId, data['new_tank_name'], code);
  }

  void onNotLoggedInError(ServerWebSocket socket) {
    // TODO
  }

  void onInvalidDataError(ServerWebSocket socket) {
    // TODO
  }

  Future<void> onMakeTakeCopy(ServerWebSocket socket, data) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    if (!(data is Map) || data['tank_name'] == null) return onInvalidDataError(socket);

    final userId = getUserIdFromSocket(socket);

    if (!(await authDb.tankNameExists(userId, data['tank_name']))) return onInvalidDataError(socket);

    data['new_tank_name'] = data['tank_name'];

    do {
      data['new_tank_name'] = data['new_tank_name'] + '_copy';
    } while (await authDb.tankNameExists(userId, data['new_tank_name']));

    await onSaveTankAs(socket, data);

    data['tank_name'] = data['new_tank_name'];

    await onOpenExistingTank(socket, data);
  }

  Future<void> onDeleteTank(ServerWebSocket socket, data) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    if (!(data is Map) || data['tank_name'] == null) return onInvalidDataError(socket);

    final userId = getUserIdFromSocket(socket);

    if (!(await authDb.tankNameExists(userId, data['tank_name']))) return onInvalidDataError(socket);

    await authDb.deleteTank(userId, data['tank_name']);
  }

  Future<void> onRenameTank(ServerWebSocket socket, data) async {
    if (!isLoggedIn(socket)) return onNotLoggedInError(socket);

    if (!(data is Map) || data['tank_name'] == null || data['new_tank_name'] == null) return onInvalidDataError(socket);

    final userId = getUserIdFromSocket(socket);

    if (!(await authDb.tankNameExists(userId, data['tank_name']))) return onInvalidDataError(socket);

    if (await authDb.tankNameExists(userId, data['new_tank_name'])) return onInvalidDataError(socket);

    await onSaveTankAs(socket, data);

    await authDb.deleteTank(userId, data['tank_name']);

    data['tank_name'] = data['new_tank_name'];

    await onOpenExistingTank(socket, data);
  }
}
