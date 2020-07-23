import '../components/collision/physics_component.dart';
import '../components/render_component.dart';
import '../components/tank_utilities_component.dart';

import '../../../../code_tanks_entity_component_system.dart';
import '../../../common/render_type.dart';

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
      renderInfo['y'] = physComp.position.features[1];
      renderInfo['rotation'] = physComp.rotation;

      TankUtilitiesComponent tankUtilsComp = entity.getComponent(TankUtilitiesComponent);
      renderInfo['gun_rotation'] = tankUtilsComp.gunRotation;
      renderInfo['radar_rotation'] = tankUtilsComp.radarRotation;
    } else if (renderComp.renderType == RenderType.bullet) {
      PhysicsComponent physComp = entity.getComponent(PhysicsComponent);

      renderInfo['x'] = physComp.position.features[0];
      renderInfo['y'] = physComp.position.features[1];
    }

    final renderable = Renderable(entity.id, renderComp.renderType, renderInfo);
    currentFrame.renderables.add(renderable);
  }

  @override
  Future<void> postProcess() async {
    frames.add(currentFrame);
    currentFrame = null;
  }
}

class Renderable {
  final int id;
  final RenderType renderType;
  final Map renderInfo;

  Renderable(this.id, this.renderType, this.renderInfo);

  Map toMap() => {
        'id': id,
        'render_type': renderType.index,
        'render_info': renderInfo,
      };
}

class Frame {
  final renderables = <Renderable>[];

  List<Map> toList() => renderables.map((r) => r.toMap()).toList(growable: false);
}
