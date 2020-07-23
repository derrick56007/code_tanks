import '../../../../../code_tanks_entity_component_system.dart';
import '../../../server_utils/vector_2d.dart';

class PhysicsComponent extends Component {
  final Vector2D position;
  num velocity = 0;

  num rotation = 0;
  num angularVelocity = 0;

  PhysicsComponent(this.position);
}