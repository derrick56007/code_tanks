import 'dart:math';
import '../../../../server_utils/utils.dart';

import 'package:code_tanks/src/server/server_utils/tuple.dart';

import 'kd_node.dart';
import 'vector_2d.dart';

class KDTree {
  KDNode root;

  // int numDim = 0;
  // num threshold = double.maxFinite;
  int size = 0;
  int height = -1;

  final pointsInRange = <Vector2D>[];

  final boundingBox = <Tuple<num, num>>[];

  void build(List<Vector2D> points) {
    size = points.length;

    if (size == 0) {
      return;
    }

    final end = size;

    height = log(size) ~/ log(2);

    final dim = points[0].features.length;

    for (var curDim = 0; curDim < dim; curDim++) {
      final feature = points[0].features[curDim];
      boundingBox.add(Tuple(feature, feature));
    }

    root = _buildSubtree(points, 0, end, 0, 0);
  }

  List<Vector2D> rangeSearch(List<Tuple<num, num>> queryRegions) {
    pointsInRange.clear();

    final curBB = boundingBox.map((e) => e.copy()).toList();

    _rangeSearchHelper(root, curBB, queryRegions, 0);

    return pointsInRange;
  }

  KDNode _buildSubtree(List<Vector2D> points, int start, int end, int curDim, int height) {
    if (start == end) {
      return null;
    }

    points.sortSublist(start, end, CompareVector2D(curDim).compare);

    final mid = (start + end) ~/ 2;

    final point = points[mid];

    final nextDim = (curDim + 1) % point.features.length;

    // build subtrees
    final node = KDNode(point);

    node.left = _buildSubtree(points, start, mid, nextDim, height + 1);
    node.right = _buildSubtree(points, mid + 1, end, nextDim, height + 1);

    // return root node
    return node;
  }

  void _rangeSearchHelper(KDNode node, List<Tuple<num, num>> curBB, List<Tuple<num, num>> queryRegions, int curDim) {
    if (node == null) {
      return;
    }

    if (isContained(node.position, queryRegions)) {
      pointsInRange.add(node.position);
    }

    final curr = node.position.features[curDim];

    final nextDim = (curDim + 1) % node.position.features.length;

    final tempBB = curBB.map((e) => e.copy()).toList();

    if (queryRegions[curDim].first < curr) {
      curBB[curDim].second = curr;

      _rangeSearchHelper(node.left, curBB, queryRegions, nextDim);
    }

    curBB = tempBB;

    if (queryRegions[curDim].second > curr) {
      curBB[curDim].first = curr;

      _rangeSearchHelper(node.right, curBB, queryRegions, nextDim);
    }

    curBB = tempBB;
  }

  static bool isContained(Vector2D point, List<Tuple<num, num>> queryRegions) {
    for (var i = 0; i < point.features.length; i++) {
      if (point.features[i] < queryRegions[i].first || point.features[i] > queryRegions[i].second) {
        return false;
      }
    }

    return true;
  }
}
