import '../models/domino_tile.dart';

class RulesEngine {
  static List<DominoTile> findValidMoves(
    List<DominoTile> hand,
    List<int> openEnds,
  ) {
    final moves = <DominoTile>[];
    for (final tile in hand) {
      for (final end in openEnds) {
        if (tile.matches(end)) {
          moves.add(tile);
          break;
        }
      }
    }
    return moves;
  }

  static bool isValidMove(
    DominoTile tile,
    List<int> openEnds,
  ) {
    for (final end in openEnds) {
      if (tile.matches(end)) return true;
    }
    return false;
  }

  /// The sides ('left' / 'right') where [tile] can legally be played.
  static List<String> getValidSides(DominoTile tile, List<int> openEnds) {
    final sides = <String>[];
    if (tile.matches(openEnds.first)) sides.add('left');
    if (tile.matches(openEnds.last)) sides.add('right');
    return sides;
  }

  static String? getPlacementSide(
    DominoTile tile,
    List<int> openEnds,
    bool isBoardEmpty,
  ) {
    if (isBoardEmpty) return 'right';

    for (final end in openEnds) {
      if (tile.matches(end)) {
        if (end == openEnds.first) return 'left';
        return 'right';
      }
    }
    return null;
  }

  static int getConnectedEnd(
    DominoTile tile,
    List<int> openEnds,
    String side,
  ) {
    final targetEnd = side == 'left' ? openEnds.first : openEnds.last;
    if (tile.top == targetEnd) return tile.top;
    if (tile.bottom == targetEnd) return tile.bottom;
    return -1;
  }

  static int calculateHandScore(List<DominoTile> hand) {
    return hand.fold(0, (sum, tile) => sum + tile.score);
  }

  static int calculateRoundScore(
    List<List<DominoTile>> remainingHands,
    int winningTeam,
  ) {
    int score = 0;
    for (int i = 0; i < remainingHands.length; i++) {
      if (i % 2 != winningTeam) {
        score += calculateHandScore(remainingHands[i]);
      }
    }
    return score;
  }

  static bool isGameBlocked(List<List<DominoTile>> hands, List<DominoTile> boneyard, List<int> openEnds) {
    if (boneyard.isNotEmpty) return false;

    for (final hand in hands) {
      if (hand.isNotEmpty) {
        if (findValidMoves(hand, openEnds).isNotEmpty) return false;
      }
    }
    return true;
  }

  static int findWinner(List<List<DominoTile>> hands) {
    int lowestScore = 999;
    int winnerTeam = -1;

    for (int i = 0; i < hands.length; i++) {
      final score = calculateHandScore(hands[i]);
      if (score < lowestScore) {
        lowestScore = score;
        winnerTeam = i % 2;
      }
    }
    return winnerTeam;
  }
}
