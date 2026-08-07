import 'package:flutter_test/flutter_test.dart';
import 'package:domino/game/team_game.dart';
import 'package:domino/models/game_state.dart';
import 'package:domino/widgets/game_board.dart';

void main() {
  test('computeLayout has no duplicated tiles for real boards', () {
    for (var seed = 0; seed < 30; seed++) {
      final game = TeamGame()..startGame();
      var iterations = 0;
      while (game.state.status == GameStatus.playing && iterations < 300) {
        iterations++;
        if (game.isHumanTurn) {
          final moves = game.getValidMoves(game.humanPlayerIndex);
          if (moves.isEmpty) {
            game.passTurn(game.humanPlayerIndex);
          } else {
            game.playTile(game.humanPlayerIndex, moves.first);
          }
        } else {
          game.aiPlayTurn();
        }
      }
      if (game.state.board.length < 2) continue;

      final layout = computeLayout(
        game.state.board,
        maxWidth: 400,
        maxHeight: 400,
      );

      final seen = <String>{};
      for (final pos in layout.positions) {
        if (!seen.add(pos.tile.toString())) {
          fail('DUPLICATE ${pos.tile} seed=$seed board=${game.state.board.map((p) => p.tile.toString()).join(",")}');
        }
      }
      if (layout.positions.length != game.state.board.length) {
        fail('MISSING tiles seed=$seed: placed=${layout.positions.length} board=${game.state.board.length}');
      }
    }
  });
}
