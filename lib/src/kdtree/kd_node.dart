import '../server/server_utils/vector_2d.dart';

class KDNode {
  KDNode left, right;

  final Vector2D position;

  KDNode(this.position);
}