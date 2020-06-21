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
      'HMSET',
      primaryKey,
      'username',
      username,
      'password',
      hashedPassword
    ]))
        .toString();

    final register2Results =
        (await send_object(['HSET', 'users', username, userId])).toString();

    print([registerResults, register2Results]);

    return registerResults == 'OK' && register2Results == '1';
  }

  Future<bool> setUserIDAuthToken(String userId, String authToken) async {
    final primaryKey = 'user:$userId';

    final result = (await send_object(['HSET', primaryKey, 'auth', authToken])).toString();
    final result2 = (await send_object(['HSET', 'auths', authToken, userId])).toString();

    return result == '1' && result2 == '1';
  }

  Future<String> getUserIdFromAuthToken(String authToken) async =>
      (await send_object(['HGET', 'auths', authToken])).toString();

  Future<String> getAuthTokenFromUserId(String userId) async =>
      (await send_object(['HGET', 'user:$userId', 'auth'])).toString();

  Future deleteAuthTokenOfUserId(String userId) async {
    final primaryKey = 'user:$userId';

    final authToken = await getAuthTokenFromUserId(userId);
    
    await send_object(['HDEL', primaryKey, 'auth']);
    await send_object(['HDEL', 'auths', authToken]);
  }
}
