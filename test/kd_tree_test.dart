import 'package:code_tanks/src/server/game_server/logic/components/collision/kd_tree.dart';
import 'package:code_tanks/src/server/game_server/logic/components/collision/vector_2d.dart';
import 'package:code_tanks/src/server/server_utils/tuple.dart';
import 'package:test/test.dart';

class NaiveSearch {
  List<Vector2D> points;

  void build(List<Vector2D> _points) {
    points = _points;
  }

  bool isContained(Vector2D point, List<Tuple<num, num>> queryRegions) {
    for (var i = 0; i < point.features.length; i++) {
      if (point.features[i] < queryRegions[i].first || point.features[i] > queryRegions[i].second) {
        return false;
      }
    }

    return true;
  }

  List<Vector2D> rangeSearch(List<Tuple<num, num>> queryRegions) {
    final results = <Vector2D>[];

    for (final point in points) {
      if (isContained(point, queryRegions)) {
        results.add(point);
      }
    }

    return results;
  }
}

void main() {
  KDTree kdTree;
  NaiveSearch naiveSearch;

  group('simple test', () {
    final points = <Vector2D>[
      Vector2D()
        ..features[0] = 1.0
        ..features[1] = 3.2,
      Vector2D()
        ..features[0] = 3.2
        ..features[1] = 1.0,
      Vector2D()
        ..features[0] = 5.7
        ..features[1] = 3.2,
      Vector2D()
        ..features[0] = 1.8
        ..features[1] = 2.9,
      Vector2D()
        ..features[0] = 4.4
        ..features[1] = 4.2,
      Vector2D()
        ..features[0] = 0.0
        ..features[1] = 0.0,
      Vector2D()
        ..features[0] = 2.7
        ..features[1] = 9.1,
    ];

    setUp(() {
      kdTree = KDTree();
      kdTree.build(points);

      naiveSearch = NaiveSearch();
      naiveSearch.build(points);
    });

    test('test CompareKDNode', () {
      final zeroVec = Vector2D()
          ..features[0] = 0.0
          ..features[1] = 0.0;

      final temp = <Vector2D>[
        Vector2D()
          ..features[0] = 1.0
          ..features[1] = 3.2,
        Vector2D()
          ..features[0] = 3.2
          ..features[1] = 1.0,
        Vector2D()
          ..features[0] = 5.7
          ..features[1] = 3.2,
        Vector2D()
          ..features[0] = 1.8
          ..features[1] = 2.9,
        Vector2D()
          ..features[0] = 4.4
          ..features[1] = 4.2,
        zeroVec,
        Vector2D()
          ..features[0] = 2.7
          ..features[1] = 9.1,
      ];

      temp.sort(CompareVector2D(0).compare);
      expect(temp[0], zeroVec);
      temp.sort(CompareVector2D(1).compare);
      expect(temp[0], zeroVec);
    });

    test('range search test', () {
      final queryRegions = <Tuple<num, num>>[Tuple(1.0, 5.0), Tuple(1.0, 5.0)];

      final naivePoints = naiveSearch.rangeSearch(queryRegions);
      final kdtPoints = kdTree.rangeSearch(queryRegions);

      final c = CompareVector2D(0).compare;
      expect(naivePoints..sort(c), kdtPoints..sort(c));
    });

    test('size test', () {
      expect(kdTree.size, 7);
    });

    test('height test', () {
      expect(kdTree.height, 2);
    });

    tearDown(() {
      //
    });
  });
}
