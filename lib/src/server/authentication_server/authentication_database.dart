import 'package:redis/redis.dart';

class AuthenticationDatabase {
  final String address;
  final int port;

  final connection = RedisConnection();

  Command _currentCommand;

  AuthenticationDatabase(this.address, this.port);

  Future<void> init() async {
    print('connecting to redis db...');
    _currentCommand = await connection.connect(address, port);
    print('connected to redis db');
  }

  Future<dynamic> send_object(List<String> o) async {
    if (_currentCommand == null) {
      print('cannot send object to redis; first connect to redis');
      return;
    }

    if (o == null || o.isEmpty) {
      print('cannot send null/empty object to redis');
      return;
    }

    return await _currentCommand.send_object(o);
  }

  Future<String> getUserIdFromUsername(String username) async =>
      (await send_object(['HGET', 'users', username])).toString();

  Future<String> getNextUserId() async =>
      (await send_object(['INCR', 'next_user_id'])).toString();

  Future<String> getHashedPasswordFromUserId(String userId) async =>
      (await send_object(['HGET', 'user:$userId', 'password'])).toString();

  Future<bool> registerUsernameWithHashedPassword(
      String userId, String username, String hashedPassword) async {
    final primaryKey = 'user:$userId';

    final registerResults = (await send_object([
      'HSET',
      primaryKey,
      'username',
      username,
      'password',
      hashedPassword
    ]))
        .toString();

    final register2Results =
        (await send_object(['HSET', 'users', username, userId])).toString();

    return registerResults == '2' && register2Results == '1';
  }

  Future<bool> saveCodeUploadHash(String hashedCodeUpload, String codeLangWithCode, String uuid) async {
    final primaryKey = 'hashed_code_upload:$hashedCodeUpload';
    final results = (await send_object(['HSET', primaryKey, codeLangWithCode, uuid])).toString();
    final results2 = (await send_object(['HSET', 'build_uuids', uuid, uuid])).toString();

    return results == '1' && results2 == '1';
  }

  Future<bool> buildUuidExists(String uuid) async {
    final results = (await send_object(['HEXISTS', 'build_uuids', uuid])).toString();

    return results == '1';
  }

    // Future<String> getNextBuildId() async =>
    //   (await send_object(['INCR', 'next_build_id'])).toString();

  Future<String> getCodeUploadUuid(String hashedCodeUpload, String codeLangWithCode) async {
    final primaryKey = 'hashed_code_upload:$hashedCodeUpload';
    return (await send_object(['HGET', primaryKey, codeLangWithCode])).toString();
  }

  Future<bool> saveTankIdForUser(String userId, String tankName, String tankId) async {
    final primaryKey = 'user:$userId:tanks';
    final results = (await send_object(['HSET', primaryKey, tankName, tankId])).toString();
    return results == '1';
  }
}
