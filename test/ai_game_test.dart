import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:domino/game/ai_player.dart';
import 'package:domino/game/team_game.dart';
import 'package:domino/models/domino_tile.dart';
import 'package:domino/models/game_state.dart';

void main() {
  test('aiPlayTurn plays when it is an AI turn, not on a human turn', () {
    final game = TeamGame()..startGame();

    // The starting player may be the human; if so we skip to an AI turn.
    if (game.isHumanTurn) {
      final moves = game.getValidMoves(game.humanPlayerIndex);
      if (moves.isEmpty) {
        game.passTurn(game.humanPlayerIndex);
      } else {
        game.playTile(game.humanPlayerIndex, moves.first);
      }
    }

    expect(game.isHumanTurn, isFalse);
    final playerBefore = game.state.currentPlayer;
    final acted = game.aiPlayTurn();
    expect(acted, isTrue);

    // The turn must advance to the next player unless the hand just ended.
    expect(
      game.state.currentPlayer != playerBefore ||
          game.state.status != GameStatus.playing,
      isTrue,
    );
  });

  test('AiPlayer chooses a valid tile or passes', () {
    final hand = [const DominoTile(1, 2), const DominoTile(3, 3), const DominoTile(4, 5)];
    final rng = Random(42);

    final move = AiPlayer.chooseMove(hand, [3, 6], false, random: rng);
    expect(move, isNotNull);
    expect(move!.matches(3) || move.matches(6), isTrue);

    // No matching tile -> pass.
    final blocked = AiPlayer.chooseMove(hand, [0], false, random: rng);
    expect(blocked, isNull);

    // Empty board -> always plays something.
    final lead = AiPlayer.chooseMove(hand, const [], true, random: rng);
    expect(lead, isNotNull);
  });

  test('full game with AI reaches 100 points', () {
    for (var seed = 0; seed < 10; seed++) {
      final game = TeamGame()..startGame();
      var iterations = 0;

      while (!game.isGameOver && iterations < 1000) {
        iterations++;
        if (game.state.status == GameStatus.gameOver) {
          game.startNewHand();
          continue;
        }
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

      expect(game.isGameOver, isTrue, reason: 'seed $seed did not finish');
      expect(
        game.state.teamScores[0] >= 100 || game.state.teamScores[1] >= 100,
        isTrue,
        reason: 'seed $seed scores: ${game.state.teamScores}',
      );
    }
  });

  test('board never contains a duplicate tile value', () {
    for (var seed = 0; seed < 20; seed++) {
      final game = TeamGame()..startGame();
      var iterations = 0;

      while (game.state.status == GameStatus.playing && iterations < 500) {
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

        // After every action, no two placed tiles may share values.
        final values = <String>{};
        for (final placed in game.state.board) {
          expect(values.add(placed.tile.toString()), isTrue,
              reason: 'duplicate ${placed.tile} on board at seed $seed');
        }
      }

      // The boneyard + all hands must still form a unique set with the board.
      final all = <String>{};
      for (final placed in game.state.board) {
        expect(all.add(placed.tile.toString()), isTrue);
      }
      for (final player in game.state.players) {
        for (final tile in player.hand) {
          expect(all.add(tile.toString()), isTrue,
              reason: 'tile $tile duplicated across state at seed $seed');
        }
      }
      for (final tile in game.state.boneyard) {
        expect(all.add(tile.toString()), isTrue,
            reason: 'tile $tile duplicated across state at seed $seed');
      }
      expect(all.length, 28,
          reason: 'not all 28 tiles present at seed $seed');
    }
  });
}
