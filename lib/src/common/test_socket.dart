import 'package:code_tanks/code_tanks_common.dart';

class TestSocket extends CommonWebSocket {
  @override
  void send(String type, [msg]) {
    if (msg == null) {
      onDecodedData(type);
    } else {
      onDecodedData([type, msg]);
    }
  }

  @override
  Future start() async {
    return;
  }
}