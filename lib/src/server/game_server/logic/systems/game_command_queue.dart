
import 'package:code_tanks/src/server/game_server/logic/commands/game_command.dart';
import 'package:quiver/async.dart';

class GameCommandQueue {

  final commands = <GameCommand>[];
  final endOfTurnCommands = <GameCommandName, List<GameCommand>>{};

  int numCommands = 0;

  GameCommandQueue() {
    for (final c in GameCommand.endOfTurnCommands) {
      endOfTurnCommands[c] = <GameCommand>[];
    }
  }

  void addAllCommands(List<GameCommand> i) {
    for ( final c in i) {
      addCommand(c);
    }
  }

  void addCommand(GameCommand command) {
    var commandIndex = GameCommand.endOfTurnCommands.indexOf(command.name);
    if (commandIndex == -1) {
      commandIndex = GameCommand.endOfTurnCommands.length;
    }

    if (command.isEndOfTurnCommand) {
      endOfTurnCommands[command.name].add(command);
    } else {
      commands.add(command);
    }

    numCommands++;
  }

  List<GameCommand> popNextCommands() {
    final lst = <GameCommand>[];

    while (commands.isNotEmpty) {

      final command = commands.removeAt(0);
      numCommands--;
      lst.add(command);

      if (!GameCommand.instantCommands.contains(command.name)) {
        return lst;
      }
    }

    for (final commandName in GameCommand.endOfTurnCommands) {
      if (endOfTurnCommands[commandName].isNotEmpty) {
        final command = endOfTurnCommands[commandName].removeAt(0);
        numCommands--;

        lst.add(command);
      }
    }


    return lst;
  }

  bool get isNotEmpty => numCommands > 0;

  bool get isEmpty => !isNotEmpty;

  int get length => numCommands;
}