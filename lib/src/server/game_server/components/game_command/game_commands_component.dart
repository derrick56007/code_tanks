import '../../../../../code_tanks_entity_component_system.dart';
import 'game_command_queue.dart';

class GameCommandsComponent extends Component {
  final commandQueue = GameCommandQueue();
}
