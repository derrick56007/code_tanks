Map getDoNothingTank() => {
  'tank_name': 'DoNothingTank',
  'language': 'en',
  'code_language': 'dart',
  'code': '''
import 'code_tanks_api.dart';

class Custom extends BaseTank {
  @override
  void run() {
    setRadarToRotateWithGun(true);

    ahead(2);
    rotateGun(2);
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    ahead(2);
  }

  @override
  void onScanTank(ScanTankEvent e) {
    back(2);
    setRotateRadar(2);

    setRotateGun(2);
    ahead(2);
  }
}

BaseTank createTank() => Custom();
'''
    };
