import 'run_authentication_server.dart' as run_authentication_server;
import 'run_build_server.dart' as run_build_server;
import 'run_game_server.dart' as run_game_server;

void main() async {
  await run_authentication_server.main();
  await run_build_server.main();
  await run_game_server.main();
  
  // use webdev to serve html files
}
