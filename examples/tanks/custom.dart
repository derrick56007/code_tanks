

import '../../assets/dart/code_tanks_api.dart';

class Custom extends BaseTank {
  @override
  void onDetectRobot(DetectRobotEvent e) {
    // TODO: implement onDetectRobot
  }

  @override
  void run() {
    setRadarToRotateWithGun(true);

    ahead(100);
    rotateGun(360);
    back(100);
    setRotateRadar(100);
    rotateGun(-360);
  }
}

BaseTank createTank() => Custom();