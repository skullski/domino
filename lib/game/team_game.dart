import '../models/domino_tile.dart';
import '../models/player.dart';
import '../models/game_state.dart';
import 'ai_player.dart';
import 'domino_set.dart';
import 'rules_engine.dart';

class TeamGame {
  late GameState state;
  final int humanPlayerIndex;

  TeamGame({this.humanPlayerIndex = 0}) {
    state = GameState();
  }

  bool get isHumanTurn =>
      state.status == GameStatus.playing &&
      state.currentPlayer == humanPlayerIndex;

  /// Plays (or passes) the current AI player's turn. Returns true if the AI
  /// actually acted.
  bool aiPlayTurn() {
    if (isHumanTurn) return false;
    if (state.status != GameStatus.playing) return false;

    final playerIndex = state.currentPlayer;
    final move = AiPlayer.chooseMove(
      state.players[playerIndex].hand,
      state.openEnds,
      state.isBoardEmpty,
    );

    if (move != null) {
      playTile(playerIndex, move);
    } else {
      passTurn(playerIndex);
    }
    return true;
  }

  void startGame() {
    final tiles = createDoubleSixSet();
    shuffleTiles(tiles);

    state = GameState(
      players: [
        Player(name: 'You', team: 0),
        Player(name: 'Bot 2', team: 1),
        Player(name: 'Bot 3', team: 0),
        Player(name: 'Bot 4', team: 1),
      ],
      boneyard: tiles,
      status: GameStatus.playing,
      teamScores: [0, 0],
    );

    for (final player in state.players) {
      player.hand = dealTiles(state.boneyard, 7);
    }

    final hands = state.players.map((p) => p.hand).toList();
    state.currentPlayer = findStartingPlayer(hands);
    state.currentTeam = state.currentPlayer % 2;
    state.lastStartingPlayer = state.currentPlayer;
  }

  List<DominoTile> getValidMoves(int playerIndex) {
    if (playerIndex != state.currentPlayer) return [];
    return RulesEngine.findValidMoves(
      state.players[playerIndex].hand,
      state.openEnds,
    );
  }

  bool playTile(int playerIndex, DominoTile tile) {
    if (playerIndex != state.currentPlayer) return false;
    if (!RulesEngine.isValidMove(tile, state.openEnds)) return false;

    final player = state.players[playerIndex];
    final side = RulesEngine.getPlacementSide(
      tile,
      state.openEnds,
      state.isBoardEmpty,
    );

    if (side == null) return false;

    // The first tile has no open end to connect to, so use either end.
    final connectedEnd = state.isBoardEmpty
        ? tile.top
        : RulesEngine.getConnectedEnd(tile, state.openEnds, side);

    player.hand.remove(tile);
    state.addTileToBoard(tile, side, connectedEnd);
    state.consecutivePasses = 0;

    if (player.hand.isEmpty) {
      endHand(playerIndex % 2);
      return true;
    }

    advanceTurn();
    checkGameStatus();
    return true;
  }

  // Block mode: no drawing, just pass
  void passTurn(int playerIndex) {
    if (playerIndex != state.currentPlayer) return;

    state.consecutivePasses++;

    // If all 4 players passed in a row, game is blocked
    if (state.consecutivePasses >= state.players.length) {
      state.status = GameStatus.blocked;
      endHand(-1);
      return;
    }

    advanceTurn();
  }

  void advanceTurn() {
    state.currentPlayer = (state.currentPlayer + 1) % state.players.length;
    state.currentTeam = state.currentPlayer % 2;
  }

  void checkGameStatus() {
    if (state.status != GameStatus.playing) return;
    // Block mode: only ends when someone empties hand or all pass
  }

  void endHand(int winningTeam) {
    final hands = state.players.map((p) => p.hand).toList();

    int score;
    if (winningTeam >= 0) {
      // Someone emptied their hand - team wins, gets opponents' pips
      score = RulesEngine.calculateRoundScore(hands, winningTeam);
    } else {
      // Blocked - lowest total pips wins
      final winner = RulesEngine.findWinner(hands);
      score = RulesEngine.calculateRoundScore(hands, winner);
      winningTeam = winner;
    }

    state.teamScores[winningTeam] += score;
    state.status = GameStatus.gameOver;
  }

  void startNewHand() {
    final tiles = createDoubleSixSet();
    shuffleTiles(tiles);

    state.boneyard
      ..clear()
      ..addAll(tiles);
    state.board.clear();
    state.leftEnd = -1;
    state.rightEnd = -1;
    state.consecutivePasses = 0;

    for (final player in state.players) {
      player.hand.clear();
    }

    state.status = GameStatus.playing;

    for (final player in state.players) {
      player.hand = dealTiles(state.boneyard, 7);
    }

    final hands = state.players.map((p) => p.hand).toList();
    state.currentPlayer = findStartingPlayer(hands);
    state.currentTeam = state.currentPlayer % 2;
  }

  bool get isGameOver =>
      state.teamScores[0] >= 100 || state.teamScores[1] >= 100;

  int? get overallWinner {
    if (!isGameOver) return null;
    return state.teamScores[0] >= 100 ? 0 : 1;
  }
}
