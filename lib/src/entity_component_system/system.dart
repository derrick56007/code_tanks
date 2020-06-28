import 'entity.dart';

abstract class System {
  final Set<Type> componentTypes;

  System(this.componentTypes);

  void process(Entity entity);
}