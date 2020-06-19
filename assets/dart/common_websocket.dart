import 'dart:convert';

abstract class CommonWebSocket {
  static const typeIndex = 0;
  static const messageIndex = 1;
  static const defaultLength = 2;

  final dispatchers = <String, Function>{};
  Future done;

  Future start();
  
  void on(String type, Function function) {
    if (dispatchers.containsKey(type)) {
      throw CTError('Overriding dispatch $type');
    }

    dispatchers[type] = function;
  }

  void send(String type, [message]);

  void onData(d) {
    final data = jsonDecode(d);

    if (data is List && data.length == defaultLength) {
      // check if dispatch exists
      final type = data[typeIndex];
      if (!dispatchers.containsKey(type)) {
        print('No such dispatch exists!: $type');
        return;
      }
      final msg = data[messageIndex];

      dispatchers[type](msg);

      return;
    }

    if (data is String) {
      final type = data;

      // check if is command msg
      if (!dispatchers.containsKey(type)) {
        print('No such dispatch exists!: $type');
        return;
      }
      dispatchers[type]();
      return;
    }

    print('No such dispatch exists!: $data');
  }
}

class CTError extends Error {
  final Object message;

  CTError(this.message);

  @override
  String toString() => 'CTError ${Error.safeToString(message)}';
}
