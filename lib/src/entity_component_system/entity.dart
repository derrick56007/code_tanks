import 'world.dart';
import 'component.dart';

class Entity {
  final int id;
  final World world;
  final _componentTypeToComponent = <Type, Component>{};

  Entity(this.id, this.world);

  void addComponent(Component component) {
    world.addComponentWithEntityId(component.runtimeType, id);
    _componentTypeToComponent[component.runtimeType] = component;
  }

  void addAll(Iterable<Component> components) => components.forEach((component) => addComponent);

  Component getComponent(Type componentType) => _componentTypeToComponent[componentType];
}
