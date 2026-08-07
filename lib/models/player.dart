import 'domino_tile.dart';

class Player {
  final String name;
  final int team;
  List<DominoTile> hand;

  Player({
    required this.name,
    required this.team,
    List<DominoTile>? hand,
  }) : hand = hand ?? [];

  bool get isEmpty => hand.isEmpty;

  bool hasPlayableMove(List<int> openEnds) {
    for (final tile in hand) {
      for (final end in openEnds) {
        if (tile.matches(end)) return true;
      }
    }
    return false;
  }

  List<DominoTile> getPlayableMoves(List<int> openEnds) {
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

  int get handScore => hand.fold(0, (sum, tile) => sum + tile.score);
}
