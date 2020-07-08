abstract class BaseTank {
  final currentCommands = <Map>[];

  void run();

  void onDetectRobot(DetectRobotEvent e);

  void ahead(int amount) {
    _createAndAddCommandWithArgument('ahead', amount);
  }

  void setAhead(int amount) {
    _createAndAddCommandWithArgument('set_ahead', amount);
  }

  void back(int amount) {
    _createAndAddCommandWithArgument('back', amount);
  }

  void setBack(int amount) {
    _createAndAddCommandWithArgument('set_back', amount);
  }

  void requestInfo(String infoType) {
    _createAndAddCommandWithArgument('request_info', infoType);
  }

  void rotateTank(int amount) {
    _createAndAddCommandWithArgument('rotate_tank', amount);
  }

  void setRotateTank(int amount) {
    _createAndAddCommandWithArgument('set_rotate_tank', amount);
  }  

  void rotateGun(int amount) {
    _createAndAddCommandWithArgument('rotate_gun', amount);
  }  

  void setRotateGun(int amount) {
    _createAndAddCommandWithArgument('set_rotate_gun', amount);
  }

  void rotateRadar(int amount) {
    _createAndAddCommandWithArgument('rotate_radar', amount);
  }

  void setRotateRadar(int amount) {
    _createAndAddCommandWithArgument('set_rotate_radar', amount);
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

abstract class DetectRobotEvent {}
