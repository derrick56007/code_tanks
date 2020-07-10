class Vector2D {
  final features = List<num>.generate(2, (index) => 0.0);

  Vector2D();

  @override
  String toString() => features.toString();
}

class CompareVector2D {
  final int dimension;

  Comparator<Vector2D> compare;

  CompareVector2D(this.dimension) {
    compare = (Vector2D a, Vector2D b) {
      if (a.features[dimension] < b.features[dimension]) {
        return -1;
      }
      if (a.features[dimension] > b.features[dimension]) {
        return 1;
      }
      return 0;
    };
  }
}