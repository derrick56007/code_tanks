import 'dart:html';

import 'dart:math';

class SelectList {
  final Element parentListElement;
  final String selectedClassName;
  final bool deselectable;

  SelectList(this.parentListElement, this.selectedClassName, this.deselectable);

  Element selected;

  bool get elementSelected => selected != null;
  bool get elementNotSelected => !elementSelected;

  int get length => parentListElement.children.length;

  void Function(Element prev) onChange = (_){};

  void _selectableOnClick(Element selectable) {
    selected?.classes?.remove(selectedClassName);

    final prev = selected;

    if (selected != selectable) {
      selected = selectable;
      selected.classes.add(selectedClassName);
      onChange(prev);
    } else if (deselectable) {
      selected = null;
      onChange(prev);
    }
  }

  Element addSelectableWithHtml(String html) {
    final selectable = Element.html(html);
    selectable.onClick.listen((_) => _selectableOnClick(selectable));
    parentListElement.children.add(selectable);
    onChange(null);
    return selectable;
  }

  void removeSelected({bool selectPrevious = false}) {
    if (elementNotSelected) return;

    remove(selected, selectPrevious: selectPrevious);
  }

  void remove(Element element, {bool selectPrevious = false}) {
    final elementIndex = parentListElement.children.indexOf(element);

    if (elementIndex == -1) return;

    if (selected == element) {
      selected = null;
    }

    parentListElement.children.remove(element);

    if (selectPrevious && parentListElement.children.isNotEmpty) {
      parentListElement.children[max(elementIndex - 1, 0)].click();
    } else {
      onChange(null);
    }
  }

  void clear() {
    parentListElement.children.clear();
    selected = null;
    onChange(null);
  }
}
