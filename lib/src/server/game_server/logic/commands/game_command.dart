enum GameCommandName {
  ahead,
  back,
  rotateTank,
  rotateGun,
  rotateRadar,

  setRadarToRotateWithGun,
  setGunToRotateWithTank,

  fireWithPower,
  requestInfo
}

class GameCommand {
  static const instantCommands = <GameCommandName>[
    GameCommandName.setGunToRotateWithTank,
    GameCommandName.setRadarToRotateWithGun
  ];
  static const endOfTurnCommands = <GameCommandName>[
    GameCommandName.ahead,
    GameCommandName.back,
    GameCommandName.rotateTank,
    GameCommandName.rotateGun,
    GameCommandName.rotateRadar,
    GameCommandName.fireWithPower
  ];

  final GameCommandName name;
  final dynamic val;
  final bool isEndOfTurnCommand;

  GameCommand(this.name, {this.val = 0, this.isEndOfTurnCommand = false});

    static final _playerCommandStringToGameCommandGenerator = <String, Function>{
    'ahead': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.ahead, val: 1)),
    'set_ahead': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.ahead, val: 1, isEndOfTurnCommand: true)),

    'back': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.back, val: 1)),
    'set_back': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.back, val: 1, isEndOfTurnCommand: true)),

    'rotate_gun': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.rotateGun, val: 1)),    
    'set_rotate_gun': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.rotateGun, val: 1, isEndOfTurnCommand: true)),

    'rotate_tank': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.rotateTank, val: 1)),    
    'set_rotate_tank': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.rotateTank, val: 1, isEndOfTurnCommand: true)),    

    'rotate_radar': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.rotateRadar, val: 1)),    
    'set_rotate_radar': (int val) => List.generate(val.abs(), (_) => GameCommand(GameCommandName.rotateRadar, val: 1, isEndOfTurnCommand: true)),

    'set_radar_to_rotate_with_gun': (bool val) => [GameCommand(GameCommandName.setRadarToRotateWithGun, val: val)],
    'set_gun_to_rotate_with_tank': (bool val) => [GameCommand(GameCommandName.setGunToRotateWithTank, val: val)], 
    
    'request_info': (String val) => [GameCommand(GameCommandName.requestInfo, val: 1)],
    'fire_with_power': (int val) => [GameCommand(GameCommandName.fireWithPower, val: 1)], 
    'set_fire_with_power': (int val) => [GameCommand(GameCommandName.fireWithPower, val: 1, isEndOfTurnCommand: true)], 
  };

  static List<GameCommand> fromStringWithVal(String str, val) => _playerCommandStringToGameCommandGenerator[str](val);
}
