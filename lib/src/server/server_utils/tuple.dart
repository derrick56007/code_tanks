class Tuple<T, A> {
  T first;
  A second;

  Tuple(this.first, this.second);

  @override
  String toString() => '($first, $second)';

  Tuple<T, A> copy() => Tuple<T, A>(first, second);
}
