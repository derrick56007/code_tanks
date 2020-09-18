import 'dart:math';

import 'package:code_tanks/code_tanks_kdtree.dart';

import '../../../../../code_tanks_entity_component_system.dart';

abstract class CollisionMask {
  static const none = 0x00000000;
  static const all = 0xFFFFFFFF;
  static const tank = 0x00000001;
  static const wall = 0x00000002;
  static const bullet = 0x00000004;

  static const _maskToName = <int, String>{
    none: 'none',
    all: 'all',
    tank: 'tank',
    wall: 'wall',
    bullet: 'bullet',
  };

  static String nameOf(int mask) => _maskToName[mask];
}

class ColliderComponent extends Component {
  final CTShape shape;

  final int categoryBitMask;
  final int collisionBitMask;

  int collisionStep = -1;
  final collisionIds = <int>[];

  ColliderComponent(this.shape, this.categoryBitMask, this.collisionBitMask);

  bool collidesWith(ColliderComponent other) => collisionBitMask & other.categoryBitMask != 0;

  @override
  String toString() => shape.toString();
}

abstract class CTShape {
  const CTShape();

  num getMaxDiameter();

  @override
  String toString() => 'maxDiameter: ${getMaxDiameter()}';
}

class CTRect extends CTShape {
  final num width, height;

  final num _maxDiameter;

  CTRect(this.width, this.height) : _maxDiameter = sqrt(pow(width, 2) + pow(height, 2));

  @override
  num getMaxDiameter() => _maxDiameter;

  @override
  String toString() => 'width: $width, height: $height, ${super.toString()}';
}

class CTCircle extends CTShape {
  final num radius;
  final num _maxDiameter;

  CTCircle(this.radius) : _maxDiameter = radius * 2;

  @override
  num getMaxDiameter() => _maxDiameter;
}
