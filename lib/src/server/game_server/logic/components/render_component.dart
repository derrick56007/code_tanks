import '../../../../../code_tanks_entity_component_system.dart';

class RenderComponent extends Component {
  final RenderType renderType;

  RenderComponent(this.renderType);
}

enum RenderType {
  tank,
  bullet
}