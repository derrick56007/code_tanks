import 'dart:math';

import '../../../../../code_tanks_entity_component_system.dart';

class ColliderComponent extends Component {
  final CTShape shape;

  ColliderComponent(this.shape);
}

abstract class CTShape {
  const CTShape();

  num getMaxDiameter();
}

class CTRect extends CTShape {
  final num width, height;

  final num _maxDiameter;

  CTRect(this.width, this.height) : _maxDiameter = sqrt(pow(width, 2) + pow(height, 2));

  @override
  num getMaxDiameter() => _maxDiameter;
}
