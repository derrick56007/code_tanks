// this is a temp file

import 'code_tanks_api.dart';

class Custom extends BaseTank {
  @override
  void run() {
    // TODO: implement run
  }

  @override
  void onDetectRobot(DetectRobotEvent e) {
    // TODO: implement onDetectRobot
  }
}

BaseTank createTank() => Custom();