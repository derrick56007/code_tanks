import '../../systems/physics_system.dart';

import '../../../server_utils/angle.dart';

import 'game_command_name.dart';

class GameCommand {
  static const instantCommands = <GameCommandName>[
    GameCommandName.setGunToRotateWithTank,
    GameCommandName.setRadarToRotateWithGun
  ];

  static const endOfTurnCommands = <GameCommandName>[
    GameCommandName.aheadBy,
    GameCommandName.backBy,
    GameCommandName.rotateTankBy,
    GameCommandName.rotateGunBy,
    GameCommandName.rotateRadarBy,
    GameCommandName.fireWithPower
  ];

  final GameCommandName name;
  final dynamic val;
  final bool isEndOfTurnCommand;

  int commandDepth = 0;

  GameCommand(this.name, {this.val = 0, this.isEndOfTurnCommand = false});

  static final _playerCommandStringToGameCommandGenerator = <String, Function>{
    'ahead_by': aheadBy,
    'set_ahead_by': setAheadBy,
    'back_by': backBy,
    'set_back_by': setBackBy,
    'rotate_gun_by': rotateGunBy,
    'set_rotate_gun_by': setRotateGunBy,
    'rotate_tank_by': rotateTankBy,
    'set_rotate_tank_by': setRotateTankBy,
    'rotate_radar_by': rotateRadarBy,
    'set_rotate_radar_by': setRotateRadarBy,
    'set_radar_to_rotate_with_gun': setRadarToRotateWithGun,
    'set_gun_to_rotate_with_tank': setGunToRotateWithTank,
    'request_info': requestInfo,
    'fire_with_power': fireWithPower,
    'set_fire_with_power': setFireWithPower,
  };

  static List<GameCommand> aheadBy(int val) {
    return List.generate(val.abs(), (_) => GameCommand(GameCommandName.aheadBy, val: 1));
  }

  static List<GameCommand> setAheadBy(int val) {
    return List.generate(val.abs(), (_) => GameCommand(GameCommandName.aheadBy, val: 1, isEndOfTurnCommand: true));
  }

  static List<GameCommand> backBy(int val) {
    return List.generate(val.abs(), (_) => GameCommand(GameCommandName.backBy, val: 1));
  }

  static List<GameCommand> setBackBy(int val) {
    return List.generate(val.abs(), (_) => GameCommand(GameCommandName.backBy, val: 1, isEndOfTurnCommand: true));
  }

  static List<GameCommand> rotateGunBy(int val, {bool isEndOfTurnCommand = false}) {
    final radians = val.toRadians();
    final commands = <GameCommand>[];

    for (var i = 0; i < radians ~/ PhysicsSystem.maxAngularVelocity; i++) {
      commands.add(GameCommand(GameCommandName.rotateGunBy,
          val: PhysicsSystem.maxAngularVelocity, isEndOfTurnCommand: isEndOfTurnCommand));
    }

    final remainder = radians % PhysicsSystem.maxAngularVelocity;
    if (remainder != 0) {
      commands.add(GameCommand(GameCommandName.rotateGunBy, val: remainder, isEndOfTurnCommand: isEndOfTurnCommand));
    }

    return commands;
  }

  static List<GameCommand> setRotateGunBy(int val) => rotateGunBy(val, isEndOfTurnCommand: true);

  static List<GameCommand> rotateTankBy(int val, {bool isEndOfTurnCommand = false}) {
    final radians = val.toRadians();
    final commands = <GameCommand>[];

    for (var i = 0; i < radians ~/ PhysicsSystem.maxAngularVelocity; i++) {
      commands.add(GameCommand(GameCommandName.rotateTankBy,
          val: PhysicsSystem.maxAngularVelocity, isEndOfTurnCommand: isEndOfTurnCommand));
    }

    final remainder = radians % PhysicsSystem.maxAngularVelocity;
    if (remainder != 0) {
      commands.add(GameCommand(GameCommandName.rotateTankBy, val: remainder, isEndOfTurnCommand: isEndOfTurnCommand));
    }

    return commands;
  }

  static List<GameCommand> setRotateTankBy(int val) => rotateTankBy(val, isEndOfTurnCommand: true);

  static List<GameCommand> rotateRadarBy(int val, {bool isEndOfTurnCommand = false}) {
    final radians = val.toRadians();
    final commands = <GameCommand>[];

    for (var i = 0; i < radians ~/ PhysicsSystem.maxAngularVelocity; i++) {
      commands.add(GameCommand(GameCommandName.rotateRadarBy,
          val: PhysicsSystem.maxAngularVelocity, isEndOfTurnCommand: isEndOfTurnCommand));
    }

    final remainder = radians % PhysicsSystem.maxAngularVelocity;
    if (remainder != 0) {
      commands.add(GameCommand(GameCommandName.rotateRadarBy, val: remainder, isEndOfTurnCommand: isEndOfTurnCommand));
    }

    return commands;
  }

  static List<GameCommand> setRotateRadarBy(int val) => rotateRadarBy(val, isEndOfTurnCommand: true);

  static List<GameCommand> setRadarToRotateWithGun(bool val) {
    return [GameCommand(GameCommandName.setRadarToRotateWithGun, val: val)];
  }

  static List<GameCommand> setGunToRotateWithTank(bool val) {
    return [GameCommand(GameCommandName.setGunToRotateWithTank, val: val)];
  }

  static List<GameCommand> requestInfo(String val) {
    return [GameCommand(GameCommandName.requestInfo, val: 1)];
  }

  static List<GameCommand> fireWithPower(int val) {
    return [GameCommand(GameCommandName.fireWithPower, val: 1)];
  }

  static List<GameCommand> setFireWithPower(int val) {
    return [GameCommand(GameCommandName.fireWithPower, val: 1, isEndOfTurnCommand: true)];
  }

  static List<GameCommand> commandsfromStringWithVal(String str, val) {
    if (!_playerCommandStringToGameCommandGenerator.containsKey(str)) {
      return [];
    }

    return _playerCommandStringToGameCommandGenerator[str](val);
  }

  @override
  String toString() => name.toString();
}
