extension ReverseList<T> on List<T> {
  void reverse() => setRange(0, length, reversed);
}
