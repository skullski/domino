import 'dart:math';
import '../models/domino_tile.dart';

List<DominoTile> createDoubleSixSet() {
  final tiles = <DominoTile>[];
  for (int i = 0; i <= 6; i++) {
    for (int j = i; j <= 6; j++) {
      tiles.add(DominoTile(i, j));
    }
  }
  return tiles;
}

void shuffleTiles(List<DominoTile> tiles) {
  final random = Random();
  for (int i = tiles.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final temp = tiles[i];
    tiles[i] = tiles[j];
    tiles[j] = temp;
  }
}

List<DominoTile> dealTiles(List<DominoTile> boneyard, int count) {
  final hand = <DominoTile>[];
  for (int i = 0; i < count && boneyard.isNotEmpty; i++) {
    hand.add(boneyard.removeAt(0));
  }
  return hand;
}

int findStartingPlayer(List<List<DominoTile>> hands) {
  int highestDoubleValue = -1;
  int startingPlayer = 0;

  for (int i = 0; i < hands.length; i++) {
    for (final tile in hands[i]) {
      if (tile.isDouble && tile.top > highestDoubleValue) {
        highestDoubleValue = tile.top;
        startingPlayer = i;
      }
    }
  }

  return startingPlayer;
}
