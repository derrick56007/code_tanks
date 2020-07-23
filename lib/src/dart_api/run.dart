import 'dart:io';

import 'package:code_tanks/code_tanks_dart_api.dart';

void run(BaseTank bot) async {
  final gameKey = Platform.environment['GAME_KEY'];

  // TODO replace with game server address
  const url = 'ws://host.docker.internal:9899';

  final socket = DummySocket(url);
  // final bot = custom.createTank();

  handleSocketAndBot(socket, bot);

  print('game instance connecting to $url');

  await socket.start();
  print('game instance connected');

  final data = {'game_key': gameKey};
  socket.send('game_instance_handshake', data);
}

final nameToEventGenerator = <String, GameEvent Function(Map)>{
  'scan_tank_event': (Map map) => ScanTankEvent.fromMap(map),
  'hit_by_bullet_event': (Map map) => HitByBulletEvent.fromMap(map),
};

void handleSocketAndBot(socket, BaseTank bot) {
  void sendAndClearCommands(String msgType) {
    final msg = {'commands': bot.currentCommands};
    socket.send(msgType, msg);
    bot.currentCommands.clear();

    print('sent commands');
  }

  void onRunGameCommandsRequest(_) {
    // print('received run_game_commands_request');
    bot.run();
    sendAndClearCommands('run_game_commands_response');
  }

  final dispatchToRespectiveEventHandler = <Type, Function>{
    ScanTankEvent: (ScanTankEvent e) => bot.onScanTank(e),
    HitByBulletEvent: (HitByBulletEvent e) => bot.onHitByBulletEvent(e)
  };

  void onEventCommandsRequest(data) {
    print('received event_commands_request');

    print(data);

    // TODO validate data
    final eventName = data['event_name'];
    final gameEvent = nameToEventGenerator[eventName](data);

    dispatchToRespectiveEventHandler[gameEvent.runtimeType](gameEvent);
    sendAndClearCommands('event_commands_response');
  }

  socket //
    ..on('run_game_commands_request', onRunGameCommandsRequest)
    ..on('event_commands_request', onEventCommandsRequest);
}
