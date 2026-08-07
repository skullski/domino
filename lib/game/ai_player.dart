import 'dart:math';

import '../models/domino_tile.dart';

/// Basic heuristic AI for Block dominoes 2v2.
///
/// Strategy (simple but sane):
///   * dump doubles first (they are hard to get rid of),
///   * prefer tiles that match the larger open end (keeps control of the board),
///   * otherwise shed the highest-pip tiles.
/// A little randomness keeps bot play varied.
class AiPlayer {
  static const double doubleBonus = 20;
  static const double highEndBonus = 12;
  static const double jitter = 3;

  static DominoTile? chooseMove(
    List<DominoTile> hand,
    List<int> openEnds,
    bool boardEmpty, {
    Random? random,
  }) {
    final rng = random ?? Random();

    final moves = <DominoTile>[];
    for (final tile in hand) {
      if (boardEmpty) {
        moves.add(tile);
      } else {
        for (final end in openEnds) {
          if (tile.matches(end)) {
            moves.add(tile);
            break;
          }
        }
      }
    }

    if (moves.isEmpty) return null;

    final scored = moves
        .map((t) => _Entry(t, _score(t, openEnds, boardEmpty, rng)))
        .toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.first.tile;
  }

  static double _score(
    DominoTile tile,
    List<int> openEnds,
    bool boardEmpty,
    Random rng,
  ) {
    var score = tile.score.toDouble();
    if (tile.isDouble) score += doubleBonus;
    if (boardEmpty) return score + rng.nextDouble() * jitter;

    final maxEnd = openEnds.reduce(max);
    if (tile.matches(maxEnd)) score += highEndBonus;
    return score + rng.nextDouble() * jitter;
  }
}

class _Entry {
  final DominoTile tile;
  final double score;

  _Entry(this.tile, this.score);
}
