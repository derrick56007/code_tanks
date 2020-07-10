import 'system.dart';
import 'entity.dart';

class World {
  int nextId = 0;

  final systems = <System>[];
  final systemByType = <Type, System>{};
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

  Future<void> updateAsync() async {
    for (final system in systems) {
      final sortedIds = getSortedIdsForEntitiesWithComponentTypes(system.componentTypes);
      
      await system.preProcess();
      
      for (final id in sortedIds) {
        await system.process(idToEntity[id]);
      }

      await system.postProcess();

    }
  }

  List<int> getSortedIdsForEntitiesWithComponentTypes(Set<Type> componentTypes) {

    final idSetsForCorrespondingComponentTypes = componentTypes.map((type) => componentTypeToIdSet[type]).toList();

    final ids = intersectionBetweenAllSets(idSetsForCorrespondingComponentTypes).toList().cast<int>();
    
    return ids..sort();
  }

  static Set intersectionBetweenAllSets(List<Set> sets) {
    if (sets.isEmpty) return {};
    
    if (sets.length == 1) return sets.first;

    var currentSet = sets.first;

    for (var i = 1; i < sets.length; i++) {
      currentSet = currentSet.intersection(sets[i]);
    }

    return currentSet;
  }

  void addSystem(System system) {
    print('adding system $system');
    systems.add(system);
    systemByType[system.runtimeType] = system;
  }

  System getSystemByType(Type systemType) => systemByType[systemType];
}
