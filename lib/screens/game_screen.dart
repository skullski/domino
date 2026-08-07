import 'dart:async';

import 'package:flutter/material.dart';
import '../game/team_game.dart';
import '../models/game_state.dart';
import '../models/domino_tile.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/game_board.dart';
import '../widgets/opponent_area.dart';
import 'main_menu.dart';

/// 2v2 table screen matching the Dominoes Battle portrait layout:
/// header with team scores, partner at top, opponents on the sides,
/// the snake board in the center and the wooden bench at the bottom.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const double _turnSeconds = 20;

  late TeamGame game;
  Timer? _uiTimer;
  Timer? _aiTimer;
  int _turnIndex = -1;
  DateTime _turnStart = DateTime.now();
  bool _passedOnExpiry = false;

  @override
  void initState() {
    super.initState();
    game = TeamGame();
    game.startGame();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), _onTick);
    _scheduleAiIfNeeded();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _aiTimer?.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    final current = game.state.currentPlayer;
    if (current != _turnIndex) {
      _turnIndex = current;
      _turnStart = DateTime.now();
      _passedOnExpiry = false;
    }
    if (game.state.status != GameStatus.playing) return;
    if (current != game.humanPlayerIndex) return;
    final elapsed = DateTime.now().difference(_turnStart).inMilliseconds / 1000.0;
    if (elapsed < _turnSeconds || _passedOnExpiry) return;
    _passedOnExpiry = true;
    if (game.getValidMoves(game.humanPlayerIndex).isEmpty) {
      _passTurn();
    }
  }

  double _remainingFraction() {
    final elapsed = DateTime.now().difference(_turnStart).inMilliseconds / 1000.0;
    final remaining = (_turnSeconds - elapsed).clamp(0.0, _turnSeconds);
    return remaining / _turnSeconds;
  }

  void _scheduleAiIfNeeded() {
    if (!mounted) return;
    if (game.state.status != GameStatus.playing) return;
    if (game.isHumanTurn) return;

    _aiTimer?.cancel();
    _aiTimer = Timer(const Duration(milliseconds: 700), _runAiTurn);
  }

  void _runAiTurn() {
    if (!mounted) return;
    setState(() {
      game.aiPlayTurn();
    });
    _afterAction();
  }

  void _afterAction() {
    if (game.state.status == GameStatus.gameOver) {
      _showResult();
      return;
    }
    _scheduleAiIfNeeded();
  }

  void _onTileTap(DominoTile tile) {
    if (!game.isHumanTurn) return;
    final success = game.playTile(game.humanPlayerIndex, tile);
    if (!success) return;
    setState(() {});
    _afterAction();
  }

  void _passTurn() {
    setState(() {
      game.passTurn(game.humanPlayerIndex);
    });
    _afterAction();
  }

  void _showResult() {
    _aiTimer?.cancel();
    final scores = game.state.teamScores;
    final isGameOver = game.isGameOver;
    final winner = game.overallWinner;
    final blocked = game.state.status == GameStatus.blocked;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isGameOver ? 'Game Over!' : blocked ? 'Game Blocked!' : 'Hand Over!',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGameOver)
              Text(
                'Team ${winner! + 1} Wins!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _resultBox('Team 1', scores[0], const Color(0xFF1565C0)),
                _resultBox('Team 2', scores[1], const Color(0xFF6A1B9A)),
              ],
            ),
          ],
        ),
        actions: [
          if (!isGameOver)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => game.startNewHand());
                _scheduleAiIfNeeded();
              },
              child: const Text('Next Hand', style: TextStyle(fontSize: 16)),
            ),
          TextButton(
            onPressed: () {
              _aiTimer?.cancel();
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainMenu()),
              );
            },
            child: const Text('Menu', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _resultBox(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text('$score', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHumanTurn = game.isHumanTurn;
    final humanPlayer = game.state.players[game.humanPlayerIndex];
    final currentHand = humanPlayer.hand;
    final playableMoves = isHumanTurn
        ? game.getValidMoves(game.humanPlayerIndex)
        : const <DominoTile>[];
    final hasMoves = playableMoves.isNotEmpty;
    final scores = game.state.teamScores;
    final current = game.state.currentPlayer;
    final remaining = _remainingFraction();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          final headerH = (h * 0.115).clamp(56.0, 92.0);
          final partnerH = h * 0.115;
          final benchH = (h * 0.27).clamp(150.0, 230.0);
          final sideW = (w * 0.115).clamp(44.0, 64.0);

          final boardL = sideW + 4;
          final boardT = headerH + partnerH + 4;
          final boardR = w - sideW - 4;
          final boardB = h - benchH - 4;
          final boardW = (boardR - boardL).clamp(120.0, double.infinity);
          final boardH = (boardB - boardT).clamp(120.0, double.infinity);

          return Stack(
            children: [
              // Table felt background.
              Positioned.fill(child: _buildFelt()),

              // Center board area.
              Positioned(
                left: boardL,
                top: boardT,
                width: boardW,
                height: boardH,
                child: _buildBoardFrame(GameBoard(board: game.state.board)),
              ),

              // Header with team scores.
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: headerH,
                child: _buildHeader(scores),
              ),

              // Top partner.
              Positioned(
                left: 0,
                right: 0,
                top: headerH,
                height: partnerH,
                child: Center(
                  child: OpponentArea(
                    player: game.state.players[2],
                    playerIndex: 2,
                    isCurrentPlayer: current == 2,
                    tileDirection: Axis.horizontal,
                    timerFraction: current == 2 ? remaining : null,
                  ),
                ),
              ),

              // Left opponent.
              Positioned(
                left: 0,
                top: headerH + partnerH,
                width: sideW,
                height: h - headerH - partnerH - benchH,
                child: Center(
                  child: OpponentArea(
                    player: game.state.players[1],
                    playerIndex: 1,
                    isCurrentPlayer: current == 1,
                    tileDirection: Axis.vertical,
                    timerFraction: current == 1 ? remaining : null,
                  ),
                ),
              ),

              // Right opponent.
              Positioned(
                right: 0,
                top: headerH + partnerH,
                width: sideW,
                height: h - headerH - partnerH - benchH,
                child: Center(
                  child: OpponentArea(
                    player: game.state.players[3],
                    playerIndex: 3,
                    isCurrentPlayer: current == 3,
                    tileDirection: Axis.vertical,
                    timerFraction: current == 3 ? remaining : null,
                  ),
                ),
              ),

              // Bottom: wooden bench with the human hand + actions.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: benchH,
                child: _buildBottomArea(isHumanTurn, currentHand, playableMoves, hasMoves),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFelt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.05),
          radius: 0.95,
          colors: [
            Color(0xFF2F7A3A),
            Color(0xFF25632E),
            Color(0xFF1D5225),
            Color(0xFF153C1B),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardFrame(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF8D6E63).withValues(alpha: 0.45),
          width: 3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          color: const Color(0xFF173A20).withValues(alpha: 0.35),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeader(List<int> scores) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              _teamBanner('TEAM 1', scores[0], const Color(0xFF64B5F6), const Color(0xFF1565C0)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.casino_rounded, color: Color(0xFFFFD54F), size: 20),
                    const SizedBox(height: 2),
                    Text(
                      '${game.state.targetScore}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'GOAL',
                      style: TextStyle(color: Colors.white54, fontSize: 8, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              _teamBanner('TEAM 2', scores[1], const Color(0xFFCE93D8), const Color(0xFF6A1B9A)),
              const SizedBox(width: 4),
              _iconButton(Icons.settings_rounded, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamBanner(String label, int score, Color accent, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: accent, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 1),
          Text(
            '$score',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
    );
  }

  Widget _buildBottomArea(bool isHumanTurn, List<DominoTile> hand, List<DominoTile> playableMoves, bool hasMoves) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTurnInfo(hasMoves, isHumanTurn),
        Expanded(child: _buildWoodenRail(hand, playableMoves)),
        _buildActions(hasMoves, isHumanTurn),
      ],
    );
  }

  Widget _buildTurnInfo(bool hasMoves, bool isHumanTurn) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHumanTurn
                ? (hasMoves ? Icons.bolt_rounded : Icons.hourglass_empty_rounded)
                : Icons.psychology_rounded,
            color: isHumanTurn ? (hasMoves ? const Color(0xFFFFD54F) : Colors.red.shade300) : Colors.white54,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            isHumanTurn
                ? (hasMoves ? 'Your turn' : 'No moves - Pass!')
                : '${game.state.players[game.state.currentPlayer].name} is playing...',
            style: TextStyle(
              color: isHumanTurn ? Colors.white70 : Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodenRail(List<DominoTile> hand, List<DominoTile> playableMoves) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6D4C41), Color(0xFF5D4037), Color(0xFF4E342E)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: PlayerHandWidget(
        hand: hand,
        playableTiles: playableMoves,
        onTileTap: _onTileTap,
        isCurrentPlayer: true,
      ),
    );
  }

  Widget _buildActions(bool hasMoves, bool isHumanTurn) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: hasMoves && isHumanTurn ? null : _passTurn,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasMoves && isHumanTurn
                      ? [const Color(0xFF78909C), const Color(0xFF607D8B)]
                      : [const Color(0xFFE53935), const Color(0xFFC62828)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: (hasMoves && isHumanTurn ? const Color(0xFF78909C) : const Color(0xFFE53935))
                        .withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  const Text(
                    'PASS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => _showResult(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
