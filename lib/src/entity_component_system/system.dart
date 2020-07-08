import 'entity.dart';

abstract class System {
  final Set<Type> componentTypes;

  System(this.componentTypes);

  Future<void> process(Entity entity);
}