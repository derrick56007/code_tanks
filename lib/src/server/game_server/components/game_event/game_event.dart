import 'game_event_type.dart';

class GameEvent {
  final GameEventType gameEventType;

  GameEvent(this.gameEventType);

  Map toJson() => {
    'event_name': gameEventType.name,
  };
}