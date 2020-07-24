import 'dart:math';

import '../components/tank_utilities_component.dart';

import '../components/collision/collider_component.dart';
import '../../../kdtree/kd_tree.dart';
import '../components/collision/physics_component.dart';
import '../../server_utils/vector_2d.dart';
import '../../server_utils/tuple.dart';
import '../../server_utils/angle.dart';

import '../../../../code_tanks_entity_component_system.dart';

class PhysicsSystem extends System {
  static const maxAngularVelocity = pi / 8;

  final tree = KDTree();

  final positions = <Vector2D>[];
  final positionsToEntity = <Vector2D, Entity>{};

  final velocityDampeningRate = 0.5;
  final angularVelocityDampeningRate = 0.5;

  PhysicsSystem() : super({PhysicsComponent, ColliderComponent});

  @override
  Future<void> preProcess() async {
    positions.clear();
    positionsToEntity.clear();
  }

  @override
  Future<void> process(Entity entity) async {
    PhysicsComponent physComp = entity.getComponent(PhysicsComponent);

    final rotationDelta = physComp.angularVelocity;

    physComp
      ..position.features[0] += physComp.velocity * sin(physComp.rotation.toDegrees())
      ..position.features[1] += physComp.velocity * cos(physComp.rotation.toDegrees())
      ..rotation = (physComp.rotation + rotationDelta) % tau
      // ..velocity *= velocityDampeningRate
      // ..angularVelocity *= angularVelocityDampeningRate;
      ..velocity *= 0
      ..angularVelocity *= 0;

    // custom processing for tanks (gun and radar)

    TankUtilitiesComponent tankComp = entity.getComponent(TankUtilitiesComponent);

    if (tankComp != null) {
      final gunRotationDelta = tankComp.gunAngularVelocity;
      tankComp
        ..gunRotation = (tankComp.gunRotation + gunRotationDelta) % tau
        ..radarRotation = (tankComp.radarRotation + tankComp.radarAngularVelocity) % tau
        // ..gunAngularVelocity *= angularVelocityDampeningRate
        // ..radarAngularVelocity *= angularVelocityDampeningRate;
        ..gunAngularVelocity *= 0
        ..radarAngularVelocity *= 0;        

      if (tankComp.gunRotatesWithTank) {
        tankComp.gunRotation = (tankComp.gunRotation + rotationDelta) % tau;
      }

      if (tankComp.radarRotatesWithGun) {
        tankComp.radarRotation = (tankComp.radarRotation + gunRotationDelta) % tau;

        if (tankComp.gunRotatesWithTank) {
          tankComp.radarRotation = (tankComp.radarRotation + rotationDelta) % tau;
        }
      }
    }

    positions.add(physComp.position);
    positionsToEntity[physComp.position] = entity;
  }

  @override
  Future<void> postProcess() async {
    tree.build(positions);

    for (final p in positions) {
      final e = positionsToEntity[p];
      PhysicsComponent physComp = e.getComponent(PhysicsComponent);
      ColliderComponent collComp = e.getComponent(ColliderComponent);

      final xStart = physComp.position.features[0] - collComp.shape.getMaxDiameter();
      final xEnd = physComp.position.features[0] + collComp.shape.getMaxDiameter();
      final yStart = physComp.position.features[1] - collComp.shape.getMaxDiameter();
      final yEnd = physComp.position.features[1] + collComp.shape.getMaxDiameter();

      final queryRegions = <Tuple<num, num>>[
        Tuple(xStart, xEnd),
        Tuple(yStart, yEnd),
      ];

      // print('do collision for ${e.id} ${physComp.position.features} with queryRegions: $queryRegions');

      for (final p2 in tree.rangeSearch(queryRegions)) {
        final e2 = positionsToEntity[p2];

        if (e2.id != e.id) {
          // print('${e.id} possibly collided with ${e2.id}');
        }
      }

      //
    }
  }

  // static num smallestSignedAngleBetween(num start, num target) {
  //   const tau = 2 * pi;
  //   final a = (start - target) % tau;
  //   final b = (target - start) % tau;

  //   return a < b ? -a : b;
  // }

  static const tau = 2 * pi;

  // static num toDegrees(num rad) => rad * 180 / pi;
}
