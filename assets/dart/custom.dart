// this is a placeholder file

import 'package:code_tanks/code_tanks_dart_api.dart';

class Custom extends BaseTank {
  @override
  void run() {}

  @override
  void onScanTank(ScanTankEvent e) {}
}

BaseTank createTank() => Custom();