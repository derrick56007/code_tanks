abstract class BaseTank {
  final currentCommands = <Map>[];

  void run();

  void onScanTank(ScanTankEvent e) {}

  void onHitByBulletEvent(HitByBulletEvent e) {}

  void aheadBy(int amount) {
    _createAndAddCommandWithArgument('ahead_by', amount);
  }

  void setAheadBy(int amount) {
    _createAndAddCommandWithArgument('set_ahead_by', amount);
  }

  void backBy(int amount) {
    _createAndAddCommandWithArgument('back_by', amount);
  }

  void setBackBy(int amount) {
    _createAndAddCommandWithArgument('set_back_by', amount);
  }

  void requestInfo(String infoType) {
    _createAndAddCommandWithArgument('request_info', infoType);
  }

  void rotateTankBy(int amount) {
    _createAndAddCommandWithArgument('rotate_tank_by', amount);
  }

  void setRotateTankBy(int amount) {
    _createAndAddCommandWithArgument('set_rotate_tank_by', amount);
  }  

  void rotateGunBy(int amount) {
    _createAndAddCommandWithArgument('rotate_gun_by', amount);
  }  

  void setRotateGunBy(int amount) {
    _createAndAddCommandWithArgument('set_rotate_gun_by', amount);
  }

  void rotateRadar(int amount) {
    _createAndAddCommandWithArgument('rotate_radar', amount);
  }

  void setRotateRadarBy(int amount) {
    _createAndAddCommandWithArgument('set_rotate_radar_by', amount);
  }

  void setRadarToRotateWithGun(bool b) {
    _createAndAddCommandWithArgument('set_radar_to_rotate_with_gun', b);
  }

  void setGunToRotateWithTank(bool b) {
    _createAndAddCommandWithArgument('set_gun_to_rotate_with_tank', b);
  }

  void fireWithPower(int power) {
    _createAndAddCommandWithArgument('fire_with_power', power);
  }

  void setFireWithPower(int power) {
    _createAndAddCommandWithArgument('set_fire_with_power', power);
  }  

  void _createAndAddCommandWithArgument(String commandType, dynamic commandArg) {
     currentCommands.add({'command_type': commandType, 'command_arg': commandArg});
  }
}

abstract class GameEvent {}

class ScanTankEvent extends GameEvent {
  ScanTankEvent.internal();

  factory ScanTankEvent.fromMap(Map map) => ScanTankEvent.internal();
}

class HitByBulletEvent extends GameEvent {
  HitByBulletEvent.internal();

  factory HitByBulletEvent.fromMap(Map map) => HitByBulletEvent.internal();  
}
