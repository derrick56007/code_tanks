library default_tanks;

import 'src/do_nothing_tank.dart'
    as do_nothing_tank;

class DefaultTanks {
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
