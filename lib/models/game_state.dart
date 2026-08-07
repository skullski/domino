import 'domino_tile.dart';
import 'player.dart';

enum GameStatus { waiting, playing, blocked, gameOver }

enum TileDirection { horizontal, verticalUp, verticalDown }

class PlacedTile {
  final DominoTile tile;
  final String side;
  final int connectedEnd;
  final TileDirection direction;

  PlacedTile(this.tile, this.side, this.connectedEnd, {this.direction = TileDirection.horizontal});
}

class GameState {
  final List<Player> players;
  final List<PlacedTile> board;
  final List<DominoTile> boneyard;
  int leftEnd;
  int rightEnd;
  int currentPlayer;
  int currentTeam;
  GameStatus status;
  List<int> teamScores;
  int lastStartingPlayer;
  int consecutivePasses;
  final int targetScore;

  GameState({
    List<Player>? players,
    List<PlacedTile>? board,
    List<DominoTile>? boneyard,
    this.leftEnd = -1,
    this.rightEnd = -1,
    this.currentPlayer = 0,
    this.currentTeam = 0,
    this.status = GameStatus.waiting,
    List<int>? teamScores,
    this.lastStartingPlayer = 0,
    this.consecutivePasses = 0,
    this.targetScore = 100,
  })  : players = players ?? [],
        board = board ?? [],
        boneyard = boneyard ?? [],
        teamScores = teamScores ?? [0, 0];

  bool get isBoardEmpty => board.isEmpty;

  List<int> get openEnds {
    if (isBoardEmpty) return [0, 1, 2, 3, 4, 5, 6];
    return [leftEnd, rightEnd];
  }

  void addTileToBoard(DominoTile tile, String side, int connectedEnd) {
    // Determine direction based on chain shape
    TileDirection dir = TileDirection.horizontal;
    if (board.length == 1) {
      dir = TileDirection.verticalDown;
    } else if (board.length == 2) {
      dir = TileDirection.horizontal;
    } else if (board.length == 3) {
      dir = TileDirection.verticalUp;
    }
    // After 4 tiles, alternate between horizontal and vertical

    board.add(PlacedTile(tile, side, connectedEnd, direction: dir));

    if (isBoardEmpty || board.length == 1) {
      leftEnd = tile.top;
      rightEnd = tile.bottom;
    } else {
      if (side == 'left') {
        leftEnd = tile.getOtherEnd(connectedEnd);
      } else {
        rightEnd = tile.getOtherEnd(connectedEnd);
      }
    }
  }

  int get totalTilesInPlay {
    int total = 0;
    for (final player in players) {
      total += player.hand.length;
    }
    total += boneyard.length;
    total += board.length * 2;
    return total;
  }
}
