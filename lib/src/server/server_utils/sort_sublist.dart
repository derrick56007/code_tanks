extension SortSublist<T> on List<T> {
  void sortSublist(int start, int end, [Comparator<T> comparator]) =>
      setRange(start, end, sublist(start, end)..sort(comparator));
}