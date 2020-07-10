import 'package:code_tanks/src/server/game_server/logic/components/collision/physics_component.dart';
import 'package:code_tanks/src/server/game_server/logic/components/render_component.dart';
import 'package:code_tanks/src/server/game_server/logic/components/tank_utilities_component.dart';

import '../../../../../code_tanks_entity_component_system.dart';

class RenderSystem extends System {
  RenderSystem() : super({RenderComponent});

  final frames = <Frame>[];
  Frame currentFrame;

  @override
  Future<void> preProcess() async {
    currentFrame = Frame();
  }

  @override
  Future<void> process(Entity entity) async {
    RenderComponent renderComp = entity.getComponent(RenderComponent);

    final renderInfo = {};

    if (renderComp.renderType == RenderType.tank) {
      PhysicsComponent physComp = entity.getComponent(PhysicsComponent);

      renderInfo['x'] = physComp.position.features[0];
      renderInfo['y'] = physComp.position.features[0];
      renderInfo['rotation'] = physComp.rotation;

      TankUtilitiesComponent tankUtilsComp = entity.getComponent(TankUtilitiesComponent);
      renderInfo['gun_rotation'] = tankUtilsComp.gunRotation;
      renderInfo['radar_rotation'] = tankUtilsComp.radarRotation;
    } else if (renderComp.renderType == RenderType.bullet) {
      PhysicsComponent physComp = entity.getComponent(PhysicsComponent);

      renderInfo['x'] = physComp.position.features[0];
      renderInfo['y'] = physComp.position.features[0];
    }

    final renderable = Renderable(renderComp.renderType, renderInfo);
    currentFrame.renderables.add(renderable);
  }

  @override
  Future<void> postProcess() async {
    frames.add(currentFrame);
    currentFrame = null;
  }
}

class Renderable {
  final RenderType renderType;
  final Map renderInfo;

  Renderable(this.renderType, this.renderInfo);

  Map toMap() => {
        'render_type': renderType.index,
        'render_info': renderInfo,
      };
}

class Frame {
  final renderables = <Renderable>[];

  List<Map> toList() => renderables.map((r) => r.toMap()).toList(growable: false);
}
