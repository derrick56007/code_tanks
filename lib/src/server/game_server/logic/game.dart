import 'package:quiver/collection.dart';

import '../../../../code_tanks_server_common.dart';

class Game {
  final String address;
  final String gameId;

  final socketToTankStates = <ServerWebSocket, TankStates>{};
  final socketToGameKey = BiMap<ServerWebSocket, String>();
  // final Map<String, PlayerInfo> gameKeyToPlayerInfo;
  final List<String> gameKeys;

  Game(this.address, this.gameId, this.gameKeys);

  void onTankDisconnect(ServerWebSocket socket) {}

  void addTank(ServerWebSocket socket, String gameKey) {
    
    if (!gameKeys.contains(gameKey) ||
        socketToGameKey.length == gameKeys.length ||
        socketToGameKey.inverse.containsKey(gameKey)) {
          print('error adding tank');
      return;
    }

    socketToGameKey[socket] = gameKey;

    print('added tank');

    if (socketToGameKey.length == gameKeys.length) {
      startGame();
    }
  }

  void startGame() {
    print('started game $gameId');
  }
}

class TankStates {}

class PlayerInfo {
  final String gameKey;
  final String userId;
  final String tankId;

  PlayerInfo(this.gameKey, this.userId, this.tankId);
}
