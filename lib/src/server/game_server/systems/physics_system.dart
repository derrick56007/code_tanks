import 'dart:math';

import 'package:code_tanks/code_tanks_dart_api.dart';
import 'package:code_tanks/src/server/game_server/components/game_event_component.dart';

import '../components/tank_utilities_component.dart';

import '../components/collision/collider_component.dart';
import '../../../kdtree/kd_tree.dart';
import '../components/collision/physics_component.dart';
import '../../server_utils/vector_2d.dart';
import '../../server_utils/tuple.dart';
import '../../server_utils/reverse_list.dart';

import '../../../../code_tanks_entity_component_system.dart';

class PhysicsSystem extends System {
  static const maxAngularVelocity = pi / 64;

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

    // TODO disable movement on collision

    physComp
      ..position.features[0] += physComp.velocity * -sin(physComp.rotation)
      ..position.features[1] += physComp.velocity * cos(physComp.rotation)
      ..rotation = (physComp.rotation + rotationDelta) % tau
      ..velocity *= 0
      ..angularVelocity *= 0;

    // custom processing for tanks (gun and radar)

    TankUtilitiesComponent tankComp = entity.getComponent(TankUtilitiesComponent);

    if (tankComp != null) {
      final gunRotationDelta = tankComp.gunAngularVelocity;
      tankComp
        ..gunRotation = (tankComp.gunRotation + gunRotationDelta) % tau
        ..radarRotation = (tankComp.radarRotation + tankComp.radarAngularVelocity) % tau
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

  int currentCollisionStep = -1;

  @override
  Future<void> postProcess() async {
    tree.build(positions);

    currentCollisionStep++;

    for (final p in positions) {
      final e1 = positionsToEntity[p];

      PhysicsComponent physComp1 = e1.getComponent(PhysicsComponent);
      ColliderComponent collComp1 = e1.getComponent(ColliderComponent);

      final xStart = physComp1.position.features[0] - collComp1.shape.getMaxDiameter();
      final xEnd = physComp1.position.features[0] + collComp1.shape.getMaxDiameter();
      final yStart = physComp1.position.features[1] - collComp1.shape.getMaxDiameter();
      final yEnd = physComp1.position.features[1] + collComp1.shape.getMaxDiameter();

      final queryRegions = <Tuple<num, num>>[
        Tuple(xStart, xEnd),
        Tuple(yStart, yEnd),
      ];

      for (final p2 in tree.rangeSearch(queryRegions)) {
        final e2 = positionsToEntity[p2];

        PhysicsComponent physComp2 = e2.getComponent(PhysicsComponent);
        ColliderComponent collComp2 = e2.getComponent(ColliderComponent);

        if (collComp1.collisionStep != currentCollisionStep) {
          collComp1
            ..collisionStep = currentCollisionStep
            ..collisionIds.clear();
        }

        if (collComp2.collisionStep != currentCollisionStep) {
          collComp2
            ..collisionStep = currentCollisionStep
            ..collisionIds.clear();
        }

        // check if collision between two entities already checked
        if (collComp1.collisionIds.contains(e2.id) || collComp2.collisionIds.contains(e1.id)) {
          continue;
        }

        // check if collision is possible
        if (!collComp1.collidesWith(collComp2) || e1.id == e2.id) {
          continue;
        }

        // check shape collision
        if (!doesCollide(physComp1, collComp1, physComp2, collComp2)) {
          continue;
        }

        print('collision ${e1.id} -> ${e2.id}');
        print('($physComp1, $collComp1) -> ($physComp2, $collComp2)');

        // alert entity1 of collision event if entity1 has GameEventComponent
        GameEventComponent gameEventComponent1 = e1.getComponent(GameEventComponent);
        gameEventComponent1?.gameEvents?.add(CollisionEvent(generateCollisionInfo(collComp2, physComp2)));

        // alert entity2 of collision event if entity2 has GameEventComponent
        GameEventComponent gameEventComponent2 = e2.getComponent(GameEventComponent);
        gameEventComponent2?.gameEvents?.add(CollisionEvent(generateCollisionInfo(collComp1, physComp1)));

        // save respective collisions
        if (!collComp1.collisionIds.contains(e2.id)) {
          collComp1.collisionIds.add(e2.id);
        }

        // save respective collisions
        if (!collComp2.collisionIds.contains(e1.id)) {
          collComp2.collisionIds.add(e1.id);
        }
      }
    }
  }

  static const tau = 2 * pi;

  static Map generateCollisionInfo(ColliderComponent colComp, PhysicsComponent physComp) => {
        'name': CollisionMask.nameOf(colComp.categoryBitMask),
        'position': [physComp.position.features[0], physComp.position.features[1]],
        'rotation': physComp.rotation,
        'velocity': physComp.velocity,
      };

  static bool doesCollide(
      PhysicsComponent phys1, ColliderComponent coll1, PhysicsComponent phys2, ColliderComponent coll2) {
    // check bitMask collision
    if (!coll1.collidesWith(coll2)) {
      return false;
    }

    // check shape collision
    final shapeToPosition = <CTShape, Vector2D>{coll1.shape: phys1.position, coll2.shape: phys2.position};
    final shapeList = <CTShape>[coll1.shape, coll2.shape];

    if (shapeList.first.runtimeType == CTRect || (shapeList..reverse()).first.runtimeType == CTRect) {
      // check rectangle collision
      final pos1 = shapeToPosition[shapeList.first];
      final pos2 = shapeToPosition[shapeList.last];

      final CTRect shape1 = shapeList.first;

      if (shapeList.last.runtimeType == CTRect) {
        // rect -> rect collision check
        final CTRect shape2 = shapeList.last;

        // TODO handle rotations
        // https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection
        return pos1.features[0] < pos2.features[0] + shape2.width &&
            pos1.features[0] + shape1.width > pos2.features[0] &&
            pos1.features[1] < pos2.features[1] + shape2.height &&
            pos1.features[1] + shape1.height > pos2.features[1];
      } else if (shapeList.last.runtimeType == CTCircle) {
        // rect -> circle collision check
        final CTCircle shape2 = shapeList.last;

        // TODO handle rotations
        // https://stackoverflow.com/questions/401847/circle-rectangle-collision-detection-intersection
        final circleDistX = (pos2.features[0] - pos1.features[0]).abs();
        final circleDistY = (pos2.features[1] - pos1.features[1]).abs();

        if (circleDistX > (shape1.width / 2 + shape2.radius)) {
          return false;
        }
        if (circleDistY > (shape1.height / 2 + shape2.radius)) {
          return false;
        }

        if (circleDistX <= (shape1.width / 2)) {
          return true;
        }
        if (circleDistY <= (shape1.height / 2)) {
          return true;
        }

        final cornerDistanceSq = pow(circleDistX - shape1.width / 2, 2) + pow(circleDistY - shape1.height / 2, 2);

        return (cornerDistanceSq <= pow(shape2.radius, 2));
      }
    } else if (shapeList.first.runtimeType == CTCircle || (shapeList..reverse()).first.runtimeType == CTCircle) {
      final pos1 = shapeToPosition[shapeList.first];
      final pos2 = shapeToPosition[shapeList.last];

      final CTCircle shape1 = shapeList.first;

      if (shapeList.last.runtimeType == CTCircle) {
        final CTCircle shape2 = shapeList.last;

        // circle -> circle collision check
        final dx = pos1.features[0] - pos2.features[0];
        final dy = pos1.features[1] - pos2.features[1];

        final distance = sqrt(dx * dx + dy * dy);

        return distance < shape1.radius + shape2.radius;
      }
    }

    return false;
  }
}
