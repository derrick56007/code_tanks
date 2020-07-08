import 'package:code_tanks/src/server/game_server/logic/components/render_component.dart';

import '../../../../../code_tanks_entity_component_system.dart';

class RenderSystem extends System {
  RenderSystem() : super({RenderComponent});

  @override
  Future<void> process(Entity entity) async {
    return;
  }
  
}