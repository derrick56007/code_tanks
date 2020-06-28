import 'package:code_tanks/code_tanks_entity_component_system.dart';

void main() async {
  var derp = {'a': {'1', '2'}};

  final d = derp['a'];
  d.add('7');

  print(derp['a']);

}

class Derp {
  int a = 0;
}




