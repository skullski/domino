import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domino/game/team_game.dart';
import 'package:domino/widgets/game_board.dart';

void main() {
  testWidgets('GameBoard renders a single tile when board has one tile',
      (tester) async {
    final game = TeamGame();
    game.startGame();

    final state = game.state;
    final firstTile = state.players[state.currentPlayer].hand.first;
    game.playTile(state.currentPlayer, firstTile);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 400, height: 400, child: GameBoard(board: game.state.board)),
        ),
      ),
    );

    expect(find.byType(GameBoard), findsOneWidget);
  });

  testWidgets('GameBoard renders a snaking board for a long chain',
      (tester) async {
    final game = TeamGame();
    game.startGame();

    final state = game.state;
    final firstTile = state.players[state.currentPlayer].hand.first;
    game.playTile(state.currentPlayer, firstTile);

    // Play as many legal tiles as possible to grow the chain.
    for (int i = 0; i < 20; i++) {
      final player = state.currentPlayer;
      final moves = game.getValidMoves(player);
      if (moves.isEmpty) break;
      game.playTile(player, moves.first);
    }

    expect(game.state.board.length, greaterThanOrEqualTo(3));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 320,
            child: GameBoard(board: game.state.board),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
