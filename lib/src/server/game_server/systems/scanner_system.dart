import 'dart:math';

import 'package:code_tanks/code_tanks_dart_api.dart';
import 'package:code_tanks/src/server/game_server/components/collision/collider_component.dart';
import 'package:code_tanks/src/server/game_server/components/collision/physics_component.dart';
import 'package:code_tanks/src/server/game_server/components/game_event_component.dart';
import 'package:code_tanks/src/server/game_server/components/tank_utilities_component.dart';

import '../../../../code_tanks_kdtree.dart';
import '../components/scanner_component.dart';

import '../../../../code_tanks_entity_component_system.dart';

class ScannerSystem extends System {
  ScannerSystem() : super({ScannerComponent, PhysicsComponent, ColliderComponent, TankUtilitiesComponent});

  final tree = KDTree();

  final positions = <Vector2D>[];
  final positionsToEntity = <Vector2D, Entity>{};

  int currentScannerStep = -1;

  @override
  Future<void> preProcess() async {
    positions.clear();
    positionsToEntity.clear();
  }

  @override
  Future<void> process(Entity entity) async {
    PhysicsComponent physComp = entity.getComponent(PhysicsComponent);

    positions.add(physComp.position);
    positionsToEntity[physComp.position] = entity;
  }

  @override
  Future<void> postProcess() async {
    tree.build(positions);

    currentScannerStep++;

    for (final p in positions) {
      final e1 = positionsToEntity[p];

      PhysicsComponent physComp1 = e1.getComponent(PhysicsComponent);
      ScannerComponent scannerComp = e1.getComponent(ScannerComponent);
      TankUtilitiesComponent tankComp = e1.getComponent(TankUtilitiesComponent);

      final xStart = physComp1.position.features[0] - ScannerComponent.maxDiameter;
      final xEnd = physComp1.position.features[0] + ScannerComponent.maxDiameter;
      final yStart = physComp1.position.features[1] - ScannerComponent.maxDiameter;
      final yEnd = physComp1.position.features[1] + ScannerComponent.maxDiameter;

      final queryRegions = <Tuple<num, num>>[
        Tuple(xStart, xEnd),
        Tuple(yStart, yEnd),
      ];

      if (scannerComp.scanStep != currentScannerStep) {
        scannerComp
          ..scanStep = currentScannerStep
          ..scanIds.clear();
      }

      final radarRotation = tankComp.radarRotation - pi;

      final topVertexTranslated = Vector2D()
        ..features[0] = ScannerComponent.radarVertices[0].features[0] + physComp1.position.features[0]
        ..features[1] = ScannerComponent.radarVertices[0].features[1] + physComp1.position.features[1];

      final leftVertexTranslated = Vector2D()
        ..features[0] = ScannerComponent.radarVertices[1].features[0] * cos(radarRotation) -
            ScannerComponent.radarVertices[1].features[1] * sin(radarRotation) +
            physComp1.position.features[0]
        ..features[1] = ScannerComponent.radarVertices[1].features[1] * cos(radarRotation) +
            ScannerComponent.radarVertices[1].features[0] * sin(radarRotation) +
            physComp1.position.features[1];

      final rightVertexTranslated = Vector2D()
        ..features[0] = ScannerComponent.radarVertices[2].features[0] * cos(radarRotation) -
            ScannerComponent.radarVertices[2].features[1] * sin(radarRotation) +
            physComp1.position.features[0]
        ..features[1] = ScannerComponent.radarVertices[2].features[1] * cos(radarRotation) +
            ScannerComponent.radarVertices[2].features[0] * sin(radarRotation) +
            physComp1.position.features[1];

      final triangle = [topVertexTranslated, leftVertexTranslated, rightVertexTranslated];
      // print('${e1.id} derp, ${triangle}');
      // break;

      for (final p2 in tree.rangeSearch(queryRegions)) {
        final e2 = positionsToEntity[p2];

        if (e1.id == e2.id) {
          continue;
        }

        PhysicsComponent physComp2 = e2.getComponent(PhysicsComponent);
        ColliderComponent collComp2 = e2.getComponent(ColliderComponent);

        if (!triangleCircleCollision(triangle, physComp2.position, collComp2.shape.getMaxDiameter())) {
          continue;
        }

        final info = {
          'name': CollisionMask.nameOf(collComp2.categoryBitMask),
          'position': [physComp2.position.features[0], physComp2.position.features[1]],
          'rotation': physComp2.rotation,
          'velocity': physComp2.velocity,
        };

        print('scan ${e1.id} -> ${e2.id}');
        print('radar rotation: ${radarRotation}');
        print('${triangle} ${physComp2.position}, ${collComp2.shape.getMaxDiameter()}');

        // alert entity1 of collision event if entity1 has GameEventComponent
        GameEventComponent gameEventComponent1 = e1.getComponent(GameEventComponent);
        gameEventComponent1?.gameEvents?.add(ScanTankEvent(info));

        // save respective collisions
        if (!scannerComp.scanIds.contains(e2.id)) {
          scannerComp.scanIds.add(e2.id);
        }
      }
    }
  }

  // https://github.com/mattdesl/triangle-circle-collision
  static bool triangleCircleCollision(List<Vector2D> triangle, Vector2D circlePosition, num radius) {
    if (pointInTriangle(circlePosition, triangle)) {
      return true;
    }

    if (lineCircleCollision(triangle[0], triangle[1], circlePosition, radius)) {
      return true;
    }

    if (lineCircleCollision(triangle[1], triangle[2], circlePosition, radius)) {
      return true;
    }

    if (lineCircleCollision(triangle[2], triangle[0], circlePosition, radius)) {
      return true;
    }
    return false;
  }

  static bool pointInTriangle(Vector2D point, List<Vector2D> triangle) {
    var cx = point.features[0],
        cy = point.features[1],
        t0 = triangle[0],
        t1 = triangle[1],
        t2 = triangle[2],
        v0x = t2.features[0] - t0.features[0],
        v0y = t2.features[1] - t0.features[1],
        v1x = t1.features[0] - t0.features[0],
        v1y = t1.features[1] - t0.features[1],
        v2x = cx - t0.features[0],
        v2y = cy - t0.features[1],
        dot00 = v0x * v0x + v0y * v0y,
        dot01 = v0x * v1x + v0y * v1y,
        dot02 = v0x * v2x + v0y * v2y,
        dot11 = v1x * v1x + v1y * v1y,
        dot12 = v1x * v2x + v1y * v2y;

    // Compute barycentric coordinates
    var b = (dot00 * dot11 - dot01 * dot01),
        inv = b == 0 ? 0 : (1 / b),
        u = (dot11 * dot02 - dot01 * dot12) * inv,
        v = (dot00 * dot12 - dot01 * dot02) * inv;

    return u >= 0 && v >= 0 && (u + v < 1);
  }

  static bool lineCircleCollision(Vector2D a, Vector2D b, Vector2D circle, num radius) {
    //check to see if start or end points lie within circle
    if (pointCircleCollide(a, circle, radius)) {
      return true;
    }
    if (pointCircleCollide(b, circle, radius)) {
      return true;
    }

    var x1 = a.features[0],
        y1 = a.features[1],
        x2 = b.features[0],
        y2 = b.features[1],
        cx = circle.features[0],
        cy = circle.features[1];

    //vector d
    var dx = x2 - x1;
    var dy = y2 - y1;

    //vector lc
    var lcx = cx - x1;
    var lcy = cy - y1;

    //project lc onto d, resulting in vector p
    var dLen2 = dx * dx + dy * dy; //len2 of d
    var px = dx;
    var py = dy;
    if (dLen2 > 0) {
      var dp = (lcx * dx + lcy * dy) / dLen2;
      px *= dp;
      py *= dp;
    }

    final nearest = Vector2D()
      ..features[0] = x1 + px
      ..features[1] = y1 + py;

    //len2 of p
    var pLen2 = px * px + py * py;

    //check collision
    return pointCircleCollide(nearest, circle, radius) && pLen2 <= dLen2 && (px * dx + py * dy) >= 0;
  }

  static bool pointCircleCollide(Vector2D point, Vector2D circle, num radius) {
    if (radius == 0) {
      return false;
    }

    final dx = circle.features[0] - point.features[0];
    final dy = circle.features[1] - point.features[1];

    return dx * dx + dy * dy <= radius * radius;
  }
}
