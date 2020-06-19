import 'package:redis/redis.dart';

class AuthenticationDatabase {
  static const address = 'redis';
  static const port = 6379;

  final connection = RedisConnection();

  Command _currentCommand;

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
}