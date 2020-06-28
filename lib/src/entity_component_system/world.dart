import 'system.dart';
import 'entity.dart';

class World {
  int nextId = 0;

  final systems = <System>[];
  final componentTypeToIdSet = <Type, Set<int>>{};
  final idToEntity = <int, Entity>{};

  Entity createEntity() {
    final id = nextId++;
    idToEntity[id] = Entity(id, this);

    return idToEntity[id];
  }

  void addComponentWithEntityId(Type componentType, int entityId) {
    componentTypeToIdSet.putIfAbsent(componentType, () => <int>{});

    componentTypeToIdSet[componentType].add(entityId);
  }

  void update() {
    for (final system in systems) {
      final sortedIds = getSortedIdsForEntitiesWithComponentTypes(system.componentTypes);
      for (final id in sortedIds) {
        system.process(idToEntity[id]);
      }
    }
  }

  List<int> getSortedIdsForEntitiesWithComponentTypes(Set<Type> componentTypes) {
    final idSetsForCorrespondingComponentTypes = componentTypes.map((type) => componentTypeToIdSet[type]).toList();

    final ids = intersectionBetweenAllSets(idSetsForCorrespondingComponentTypes).toList();
    return ids..sort();
  }

  static Set intersectionBetweenAllSets(List<Set> sets) {
    if (sets.length == 1) {
      return sets.first;
    }

    var currentSet = sets.first;

    for (var i = 1; i < sets.length; i++) {
      currentSet = currentSet.intersection(sets[i]);
    }

    return currentSet;
  }

  void addSystem(System system) {
    systems.add(system);
  }
}
