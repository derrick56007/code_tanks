Map getDoNothingTank() => {
  'name': 'DoNothingTank',
  'language': 'en',
  'code_language': 'dart',
  'code': '''
import 'code_tanks_api.dart';

class Custom extends BaseTank {
  @override
  void onDetectRobot(DetectRobotEvent e) {
    // TODO: implement onDetectRobot
  }

  @override
  void tick() {
    // TODO: implement tick
  }
  
}

BaseTank createTank() => Custom();
'''
    };
