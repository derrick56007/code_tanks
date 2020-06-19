library prebuilt_tanks;

import 'package:code_tanks/src/server/game/pre_defined_tanks/src/do_nothing_tank.dart'
    as do_nothing_tank;

class PreDefinedTanks {
  static final tankMap = <String, Map>{
    'do_nothing_tank': do_nothing_tank.getDoNothingTank(),
  };

  static Map getTankByName(String name) {
    if (!tankMap.containsKey(name)) {
      print('prebuilt tank $name does not exist!');
      return tankMap['do_nothing_tank'];
    }

    return tankMap[name];
  }
}
