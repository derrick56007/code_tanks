import 'dart:math';

import 'package:code_tanks/code_tanks_kdtree.dart';
import 'package:code_tanks/src/server/server_utils/tuple.dart';

import '../../../../code_tanks_entity_component_system.dart';

class ScannerComponent extends Component {
  int scanStep = -1;

  final scanIds = <int>[];

  static const width = 400;
  static const height = 400;

  static final maxDiameter = sqrt(pow(width, 2) + pow(height, 2));

  static final radarVertices = <Vector2D>[
    Vector2D()
      ..features[0] = 0
      ..features[1] = 0, // TOP VERTEX

    Vector2D()
      ..features[0] = -width / 2
      ..features[1] = -height, // LEFT VERTEX,

    Vector2D()
      ..features[0] = width / 2
      ..features[1] = -height, // RIGHT VERTEX
  ];
}
