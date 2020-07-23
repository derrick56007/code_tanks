import '../../../../code_tanks_common.dart';

import '../../../../code_tanks_entity_component_system.dart';

class SocketComponent extends Component {
  final CommonWebSocket socket;

  SocketComponent(this.socket);
}