Map getDoNothingTank() => {
  'tank_name': 'DoNothingTank',
  'language': 'en',
  'code_language': 'dart',
  'code': '''
import 'package:code_tanks/code_tanks_dart_api.dart';

class Custom extends BaseTank {
  @override
  void run() {}

  @override
  void onScanTank(ScanTankEvent e) {}
}

BaseTank createTank() => Custom();
'''
    };
