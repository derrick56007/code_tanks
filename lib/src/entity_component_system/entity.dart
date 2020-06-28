import 'world.dart';
import 'component.dart';

class Entity {
  final int id;
  final World world;
  final componentTypeToComponent = <Type, Component>{};

  Entity(this.id, this.world);

  void addComponent(Component component) {
    world.addComponentWithEntityId(component.runtimeType, id);
    componentTypeToComponent[component.runtimeType] = component;
  }

  Component getComponent(Type componentType) => componentTypeToComponent[componentType];
}