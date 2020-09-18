import 'package:code_tanks/src/server/server_utils/tuple.dart';

import '../../../../code_tanks_entity_component_system.dart';

class TankUtilitiesComponent extends Component {
  num gunRotation = 0;
  num gunAngularVelocity = 0;
  bool gunRotatesWithTank = true;

  num radarRotation = 0;
  num radarAngularVelocity = 0;
  bool radarRotatesWithGun = true;

  static final radarVertices = <Tuple<num, num>>[
    Tuple(0, 0), // TOP VERTEX
    Tuple(-200, -400), // LEFT VERTEX,
    Tuple(200, -400),
  ];
}
