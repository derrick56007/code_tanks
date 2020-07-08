import 'package:code_tanks/code_tanks_entity_component_system.dart';

void main() async {
  // final address = '0.0.0.0';
  // final port = 9897;

  // final socket = DummySocket('ws://$address:$port');
  // await socket.start();
  // await socket.done;

  // var a = TreeSet<String>();
  // a.add('derp');

  // print(a.lookup('dep'));
  final world = World();
  world.addSystem(ACSystem());
  world.addSystem(ASystem());

  final entityA = world.createEntity();
  entityA.addComponent(AComponent());

  final entityB = world.createEntity();
  entityB.addComponent(BComponent());  

  final entityAC = world.createEntity();
  entityAC.addComponent(AComponent());  
  entityAC.addComponent(CComponent());

  final entityABC = world.createEntity();
  entityABC.addComponent(AComponent());  
  entityABC.addComponent(BComponent());  
  entityABC.addComponent(CComponent());  

  print(world.idToEntity);

  await world.updateAsync();
  await world.updateAsync();
}

class AComponent extends Component {
  int a = 1;
}

class BComponent extends Component {
  int b = 2;
}

class CComponent extends Component {
  int c = 3;
}

class ASystem extends System {
  ASystem() : super({AComponent});

  @override
  Future<void> process(Entity entity) async {
    AComponent aComp = entity.getComponent(AComponent);

    print('entity.a val ff ${aComp.a}');
    return;
  }
}

class ACSystem extends System {
  ACSystem() : super({AComponent, CComponent});

  @override
  Future<void> process(Entity entity) async {
    AComponent aComp = entity.getComponent(AComponent);
    CComponent cComp = entity.getComponent(CComponent);

    print('entity.a val ${aComp.a}');
    print('entity.c val ${cComp.c}');
    return;
  }
}






