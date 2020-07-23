import '../components/scanner_component.dart';

import '../../../../code_tanks_entity_component_system.dart';

class ScannerSystem extends System {
  ScannerSystem() : super({ScannerComponent});

  @override
  Future<void> process(Entity entity) async {
    // TODO: implement process
  }
  
}