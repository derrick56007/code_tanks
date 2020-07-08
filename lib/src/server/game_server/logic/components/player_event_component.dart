import 'package:code_tanks/src/server/game_server/logic/systems/game_command_queue.dart';
import 'package:code_tanks/src/server/game_server/logic/systems/player_event_system.dart';
import 'package:code_tanks/src/server/server_utils/tuple.dart';

import '../../../../../code_tanks_entity_component_system.dart';

class PlayerEventComponent extends Component {
  // final gameCommandTypes = <Tuple<GameCommandType, dynamic>>[];
  final commandQueue = GameCommandQueue();
}
