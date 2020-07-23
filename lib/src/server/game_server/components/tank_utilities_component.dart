import '../../../../code_tanks_entity_component_system.dart';

class TankUtilitiesComponent extends Component {
  num gunRotation = 0;
  num gunAngularVelocity = 0;
  bool gunRotatesWithTank = false;

  num radarRotation = 0;
  num radarAngularVelocity = 0;
  bool radarRotatesWithGun = false;
}