import 'dart:math';

// ignore: avoid_relative_lib_imports
import 'package:code_tanks/src/server/game_server/components/collision/physics_component.dart';
import 'package:code_tanks/src/server/game_server/components/scanner_component.dart';
import 'package:code_tanks/src/server/game_server/systems/scanner_system.dart';
import 'package:code_tanks/src/server/server_utils/vector_2d.dart';

import '../lib/src/server/server_utils/angle.dart';

import 'package:test/test.dart';

void main() {
  group('simple test', () {
    Vector2D topVertexTranslated;
    Vector2D leftVertexTranslated;
    Vector2D rightVertexTranslated;

    PhysicsComponent physComp1;

    setUp(() {
      physComp1 = PhysicsComponent(Vector2D()
        ..features[0] = 100
        ..features[1] = 100)
        ..rotation = pi / 2;

      topVertexTranslated = Vector2D()
        ..features[0] = ScannerComponent.radarVertices[0].features[0] + physComp1.position.features[0]
        ..features[1] = ScannerComponent.radarVertices[0].features[1] + physComp1.position.features[1];

      leftVertexTranslated = Vector2D()
        ..features[0] = ScannerComponent.radarVertices[1].features[0] * cos(physComp1.rotation) -
            ScannerComponent.radarVertices[1].features[1] * sin(physComp1.rotation) +
            physComp1.position.features[0]
        ..features[1] = ScannerComponent.radarVertices[1].features[1] * cos(physComp1.rotation) +
            ScannerComponent.radarVertices[1].features[0] * sin(physComp1.rotation) +
            physComp1.position.features[1];

      rightVertexTranslated = Vector2D()
        ..features[0] = ScannerComponent.radarVertices[2].features[0] * cos(physComp1.rotation) -
            ScannerComponent.radarVertices[2].features[1] * sin(physComp1.rotation) +
            physComp1.position.features[0]
        ..features[1] = ScannerComponent.radarVertices[2].features[1] * cos(physComp1.rotation) +
            ScannerComponent.radarVertices[2].features[0] * sin(physComp1.rotation) +
            physComp1.position.features[1];
    });

    test('translation test', () async {
      expect([topVertexTranslated.features[0], topVertexTranslated.features[1]], [100, 100]);
      expect([leftVertexTranslated.features[0], leftVertexTranslated.features[1]], [500.0, -100.00000000000003]);
      expect([rightVertexTranslated.features[0], rightVertexTranslated.features[1]], [500.0, 300.0]);
    });

    test('triangle circle collision test', () async {
      final triangle = [topVertexTranslated, leftVertexTranslated, rightVertexTranslated];

      final pos = Vector2D()
        ..features[0] = 0
        ..features[1] = 0;

      num radius = 1;

      expect(ScannerSystem.triangleCircleCollision(triangle, pos, radius), false);

      pos
        ..features[0] = 250
        ..features[1] = 100;

      radius = 100;

      expect(ScannerSystem.triangleCircleCollision(triangle, pos, radius), true);

      pos..features[1] = -70;

      expect(ScannerSystem.triangleCircleCollision(triangle, pos, radius), true);

      pos..features[1] = -90;

      expect(ScannerSystem.triangleCircleCollision(triangle, pos, radius), false);

      pos
        ..features[0] = 600
        ..features[1] = 100;

      expect(ScannerSystem.triangleCircleCollision(triangle, pos, radius), true);
    });

    tearDown(() {
      //
    });
  });
}
