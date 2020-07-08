class Tuple<T,A> {
  final T first;
  final A second;

  const Tuple(this.first, this.second);

  @override
  String toString() => '($first, $second)';
}