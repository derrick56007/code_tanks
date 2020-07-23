class GameEventType {
  final String name;

  const GameEventType(this.name);

  static GameEventType tankScanned = GameEventType('scan_tank_event');
  
  static GameEventType hitByBullet = GameEventType('hit_by_bullet_event');
}