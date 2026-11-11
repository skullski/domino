import 'dart:async';

import 'package:flutter/material.dart';

import '../game/domino_set.dart';
import '../models/domino_tile.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/game_board.dart';
import '../widgets/hand_over_dialog.dart';
import '../widgets/opponent_seat.dart';
import '../widgets/player_rack.dart';
import '../widgets/score_header.dart';
import '../widgets/sprite_domino_tile.dart';

/// Playable game table (Block, 2v2). The bots pick the first matching tile so
/// we can test the flow while the full rules are wired.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const int _targetScore = 100;
  static const double _turnSeconds = 20;

  final GlobalKey _boardKey = GlobalKey();
  late final AnimationController _flyController;
  OverlayEntry? _flyEntry;
  bool _animating = false;
  final List<GlobalKey> _seatKeys = List.generate(4, (_) => GlobalKey());
  DominoTile? _selected;
  Rect? _selectedFromRect;
  DominoTile? _dragTile;

  int _team1Score = 45;
  int _team2Score = 34;
  int _current = 0;
  Timer? _botTimer;
  Timer? _ticker;
  DateTime _turnStart = DateTime.now();
  int _turnIndex = -1;
  int _consecutivePasses = 0;
  bool _handOver = false;

  final List<DominoTile> _hand = [
    const DominoTile(0, 0),
    const DominoTile(1, 2),
    const DominoTile(3, 4),
    const DominoTile(0, 6),
    const DominoTile(5, 5),
    const DominoTile(2, 3),
  ];

  final List<PlacedTile> _board = [
    PlacedTile(const DominoTile(6, 6), 'center', 6),
    PlacedTile(const DominoTile(6, 5), 'left', 6),
    PlacedTile(const DominoTile(5, 4), 'left', 5),
    PlacedTile(const DominoTile(6, 2), 'right', 6),
  ];

  final List<Player> _players = [
    Player(name: 'You', team: 0),
    Player(
      name: 'Bot 1',
      team: 1,
      hand: [
        const DominoTile(0, 1),
        const DominoTile(1, 3),
        const DominoTile(2, 4),
        const DominoTile(3, 5),
        const DominoTile(1, 6),
        const DominoTile(4, 6),
      ],
    ),
    Player(
      name: 'Bot 2',
      team: 0,
      hand: [
        const DominoTile(0, 2),
        const DominoTile(1, 4),
        const DominoTile(2, 5),
        const DominoTile(3, 6),
        const DominoTile(1, 5),
        const DominoTile(0, 3),
      ],
    ),
    Player(
      name: 'Bot 3',
      team: 1,
      hand: [
        const DominoTile(0, 4),
        const DominoTile(0, 5),
        const DominoTile(1, 1),
        const DominoTile(2, 2),
        const DominoTile(3, 3),
        const DominoTile(4, 4),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _dealGame();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), _onTick);
    _scheduleBots();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    _ticker?.cancel();
    _flyEntry?.remove();
    _flyEntry = null;
    _flyController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Item B — turn timer
  // ---------------------------------------------------------------------------

  void _onTick(Timer timer) {
    if (!mounted) return;
    if (_current != _turnIndex) {
      _turnIndex = _current;
      _turnStart = DateTime.now();
    }
    if (_handOver || _animating) return;
    if (_turnFraction <= 0) {
      _onTurnTimeout();
      return;
    }
    setState(() {});
  }

  double get _turnFraction {
    final elapsed =
        DateTime.now().difference(_turnStart).inMilliseconds / 1000.0;
    return ((_turnSeconds - elapsed).clamp(0.0, _turnSeconds) / _turnSeconds);
  }

  void _onTurnTimeout() {
    if (_handOver || _animating) return;
    _turnStart = DateTime.now();

    if (_current == 0) {
      final moves = _hand
          .where((t) {
            final (l, r) = _openEnds();
            return t.matches(l) || t.matches(r);
          })
          .toList();
      if (moves.isEmpty) {
        _registerPass();
      } else {
        final tile = moves.first;
        final (l, r) = _openEnds();
        final side = tile.matches(l) ? 'left' : 'right';
        _commitPlay(tile, side, side == 'left' ? l : r);
      }
    } else {
      _botTimer?.cancel();
      _playBot();
    }
  }

  /// Item A — real match setup: shuffle the 28 tiles, deal 7 to each player
  /// (no boneyard), then the 6-6 owner plays it automatically.
  /// Item A — a fresh match: reset the score, then deal the first hand.
  void _dealGame() {
    _team1Score = 0;
    _team2Score = 0;
    _dealHand();
  }

  /// Deals one hand: shuffle 28, 7 each (no boneyard), 6-6 owner auto-plays.
  void _dealHand() {
    final tiles = createDoubleSixSet();
    shuffleTiles(tiles);

    _hand.clear();
    for (final player in _players) {
      player.hand.clear();
    }

    for (var i = 0; i < 7; i++) {
      _hand.add(tiles.removeAt(0));
      _players[1].hand.add(tiles.removeAt(0));
      _players[2].hand.add(tiles.removeAt(0));
      _players[3].hand.add(tiles.removeAt(0));
    }

    _board.clear();
    _consecutivePasses = 0;
    _handOver = false;
    _selected = null;
    _dragTile = null;
    _animating = false;

    final hands = [_hand, _players[1].hand, _players[2].hand, _players[3].hand];
    for (var i = 0; i < hands.length; i++) {
      final index = hands[i].indexWhere((tile) => tile.isDouble && tile.top == 6);
      if (index >= 0) {
        final sixSix = hands[i].removeAt(index);
        _board.add(PlacedTile(sixSix, 'center', 6));
        _current = (i + 1) % 4;
        break;
      }
    }

    _turnStart = DateTime.now();
    _turnIndex = -1;
  }

  /// Starts the next hand of the same match, keeping the scores.
  void _startNextHand() {
    _dealHand();
    setState(() {});
    _scheduleBots();
  }

  (int, int) _openEnds() {
    final center = _board.first.tile;
    var left = center.top;
    var right = center.bottom;
    for (var i = 1; i < _board.length; i++) {
      final p = _board[i];
      if (p.side == 'left') {
        left = p.tile.getOtherEnd(p.connectedEnd);
      } else {
        right = p.tile.getOtherEnd(p.connectedEnd);
      }
    }
    return (left, right);
  }

  Set<DominoTile> get _playable {
    if (_handOver || _animating || _current != 0) return {};
    final (left, right) = _openEnds();
    return _hand.where((t) => t.matches(left) || t.matches(right)).toSet();
  }

  ({bool left, bool right}) _endsFor(DominoTile tile) {
    final (left, right) = _openEnds();
    return (left: tile.matches(left), right: tile.matches(right));
  }

  void _playHuman(DominoTile tile, Rect? fromRect) {
    if (_handOver || _animating || _current != 0) return;
    if (_selected == tile) {
      setState(() => _selected = null);
      return;
    }
    final ends = _endsFor(tile);
    if (!ends.left && !ends.right) return;
    // Select the tile; the player then taps the end where it should go.
    setState(() {
      _selected = tile;
      _selectedFromRect = fromRect;
    });
  }

  void _chooseEnd(String side) {
    final tile = _selected;
    if (tile == null) return;
    final from = _selectedFromRect;
    setState(() => _selected = null);
    _startPlay(tile, side, from);
  }

  void _onDropTile(DominoTile tile, String side, Offset dropPoint) {
    if (_handOver || _animating || _current != 0) return;
    final ends = _endsFor(tile);
    if (side == 'left' ? !ends.left : !ends.right) return;
    setState(() => _selected = null);
    _startPlay(
      tile,
      side,
      Rect.fromLTWH(dropPoint.dx, dropPoint.dy, 40, 88),
    );
  }

  void _startPlay(DominoTile tile, String side, Rect? fromRect) {
    if (_handOver || _animating || _current != 0) return;
    final (left, right) = _openEnds();
    final connected = side == 'left' ? left : right;

    final target = _boardTargetRect(tile, side, connected);
    if (fromRect == null || target == null) {
      _commitPlay(tile, side, connected);
      return;
    }

    setState(() {
      _hand.remove(tile);
      _animating = true;
      _selected = null;
    });
    _flyTile(tile, fromRect, target, () {
      _commitPlay(tile, side, connected);
    });
  }

  void _commitPlay(DominoTile tile, String side, int connected) {
    setState(() {
      _hand.remove(tile);
      _board.add(PlacedTile(tile, side, connected));
      _current = 1;
      _consecutivePasses = 0;
      _animating = false;
      _selected = null;
      _dragTile = null;
    });
    if (_hand.isEmpty) {
      _endHand(0);
      return;
    }
    _scheduleBots();
  }

  /// Where [tile] will land after playing it on [side]. Global by default,
  /// or board-widget-local when [local] is true.
  ({Rect rect, bool horizontal, bool flipped})? _placementFor(
    DominoTile tile,
    String side,
    int connected, {
    required bool local,
  }) {
    final ctx = _boardKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final size = box.size;
    final origin = local ? Offset.zero : box.localToGlobal(Offset.zero);

    final sim = [..._board, PlacedTile(tile, side, connected)];
    final layout = computeLayout(
      sim,
      maxWidth: size.width,
      maxHeight: size.height,
    );
    final bounds = layout.bounds;
    final scale = layout.scale;

    var placement = layout.positions.first;
    for (final p in layout.positions) {
      if (p.tile.top == tile.top && p.tile.bottom == tile.bottom) {
        placement = p;
        break;
      }
    }

    final left =
        placement.offset.dx -
        bounds.left -
        (placement.horizontal ? 102.0 : 50.0) * scale / 2;
    final top =
        placement.offset.dy -
        bounds.top -
        (placement.horizontal ? 50.0 : 102.0) * scale / 2;
    final w = (placement.horizontal ? 130.0 : 60.0) * scale;
    final h = (placement.horizontal ? 60.0 : 130.0) * scale;

    final rect = Rect.fromLTWH(
      origin.dx + (size.width - bounds.width) / 2 + left,
      origin.dy + (size.height - bounds.height) / 2 + top,
      w,
      h,
    );
    return (
      rect: rect,
      horizontal: placement.horizontal,
      flipped: placement.isFlipped,
    );
  }

  ({Rect rect, bool horizontal, bool flipped})? _boardTargetRect(
    DominoTile tile,
    String side,
    int connected,
  ) => _placementFor(tile, side, connected, local: false);

  void _flyTile(
    DominoTile tile,
    Rect from,
    ({Rect rect, bool horizontal, bool flipped}) target,
    VoidCallback onDone,
  ) {
    final overlay = Overlay.of(context);
    final face = _faceAsset(tile);
    final horizontal = target.horizontal;
    final flipped = target.flipped;
    final to = target.rect;

    _flyEntry?.remove();
    _flyEntry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _flyController,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_flyController.value);
            final rect = Rect.lerp(from, to, t)!;
            final imgW = horizontal ? rect.height : rect.width;
            final imgH = horizontal ? rect.width : rect.height;
            final turns = ((horizontal ? 1 : 0) + (flipped ? 2 : 0)) % 4;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fromRect(
                  rect: rect,
                  child: RotatedBox(
                    quarterTurns: turns,
                    child: Image.asset(
                      face,
                      width: imgW,
                      height: imgH,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    overlay.insert(_flyEntry!);
    _flyController.forward(from: 0).whenCompleteOrCancel(() {
      if (_flyEntry != null) {
        _flyEntry!.remove();
        _flyEntry = null;
      }
      if (!mounted) return;
      onDone();
    });
  }

  String _faceAsset(DominoTile t) {
    final hi = t.top > t.bottom ? t.top : t.bottom;
    final lo = t.top > t.bottom ? t.bottom : t.top;
    return 'assets/tiles/t1d$hi$lo.png';
  }

  DominoTile get _leftEndTile {
    var t = _board.first.tile;
    for (final p in _board) {
      if (p.side == 'left') t = p.tile;
    }
    return t;
  }

  DominoTile get _rightEndTile {
    var t = _board.first.tile;
    for (final p in _board) {
      if (p.side == 'right') t = p.tile;
    }
    return t;
  }

  /// Preview slot (board-local) adjacent to the *current* end tile, so the
  /// marker lines up with the board as it is drawn right now.
  Rect? _previewRectFor(DominoTile tile, String side) {
    final ctx = _boardKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final size = box.size;

    final (left, right) = _openEnds();
    final connected = side == 'left' ? left : right;
    final sim = [..._board, PlacedTile(tile, side, connected)];

    final cur = computeLayout(
      _board,
      maxWidth: size.width,
      maxHeight: size.height,
    );
    final next = computeLayout(
      sim,
      maxWidth: size.width,
      maxHeight: size.height,
    );

    final endTile = side == 'left' ? _leftEndTile : _rightEndTile;
    TilePlacement? curEnd;
    for (final p in cur.positions) {
      if (p.tile.top == endTile.top && p.tile.bottom == endTile.bottom) {
        curEnd = p;
        break;
      }
    }
    TilePlacement? nextEnd;
    TilePlacement? nextNew;
    for (final p in next.positions) {
      if (p.tile.top == endTile.top && p.tile.bottom == endTile.bottom) {
        nextEnd = p;
      }
      if (p.tile.top == tile.top && p.tile.bottom == tile.bottom) {
        nextNew = p;
      }
    }
    if (curEnd == null || nextEnd == null || nextNew == null) return null;

    final ratio = cur.scale / next.scale;
    final delta = (nextNew.offset - nextEnd.offset) * ratio;
    final center = curEnd.offset + delta;

    final off = Offset(
      (size.width - cur.bounds.width) / 2,
      (size.height - cur.bounds.height) / 2,
    );
    final localCenter = Offset(
      center.dx - cur.bounds.left + off.dx,
      center.dy - cur.bounds.top + off.dy,
    );

    final horizontal = nextNew.horizontal;
    final w = (horizontal ? 130.0 : 60.0) * cur.scale;
    final h = (horizontal ? 60.0 : 130.0) * cur.scale;
    return Rect.fromCenter(center: localCenter, width: w, height: h);
  }

  /// The destination slots (board-local) for [tile] on each valid side.
  ({Rect? left, Rect? right}) _placementRectsFor(DominoTile tile) {
    final (l, r) = _openEnds();
    final leftRect = tile.matches(l) ? _previewRectFor(tile, 'left') : null;
    final rightRect = tile.matches(r) ? _previewRectFor(tile, 'right') : null;
    return (left: leftRect, right: rightRect);
  }

  List<Widget> _buildEndTargets() {
    final tile = _dragTile ?? _selected;
    if (tile == null) return const [];
    if (_current != 0 || _handOver || _animating) return const [];

    final rects = _placementRectsFor(tile);
    return [
      if (rects.left != null) _endTarget('left', rects.left!),
      if (rects.right != null) _endTarget('right', rects.right!),
    ];
  }

  Widget _endTarget(String side, Rect rect) {
    const margin = 18.0;
    return Positioned.fromRect(
      rect: rect.inflate(margin),
      child: DragTarget<DominoTile>(
        onWillAcceptWithDetails: (details) {
          final ends = _endsFor(details.data);
          return side == 'left' ? ends.left : ends.right;
        },
        onAcceptWithDetails: (details) =>
            _onDropTile(details.data, side, details.offset),
        builder: (context, candidate, rejected) {
          final hover = candidate.isNotEmpty;
          return GestureDetector(
            onTap: () => _chooseEnd(side),
            child: Padding(
              padding: const EdgeInsets.all(margin),
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: hover
                    ? const Color(0xFFFFD700).withValues(alpha: 0.45)
                    : const Color(0xFF0A2518).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.9),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFFFFD700),
                size: 26,
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  void _reorderHand(int oldIndex, int newIndex) {
    // ReorderableListView already adjusts newIndex for the removed item.
    if (newIndex == oldIndex) return;
    setState(() {
      final tile = _hand.removeAt(oldIndex);
      _hand.insert(newIndex, tile);
    });
  }

  void _scheduleBots() {
    _botTimer?.cancel();
    if (_handOver) return;
    if (_current == 0) {
      // Human turn: auto-skip when there is nothing playable.
      if (_playable.isEmpty) {
        _botTimer = Timer(const Duration(milliseconds: 900), () {
          if (!mounted || _current != 0 || _playable.isNotEmpty) return;
          _registerPass();
        });
      }
      return;
    }
    _botTimer = Timer(const Duration(milliseconds: 800), _playBot);
  }

  void _playBot() {
    if (!mounted || _handOver || _current == 0) return;
    final player = _players[_current];
    final (left, right) = _openEnds();

    DominoTile? move;
    String? side;
    var connected = 0;
    for (final tile in player.hand) {
      if (tile.matches(left)) {
        move = tile;
        side = 'left';
        connected = left;
        break;
      }
      if (tile.matches(right)) {
        move = tile;
        side = 'right';
        connected = right;
        break;
      }
    }

    if (move != null && side != null) {
      _flyBotTile(_current, move, side, connected);
      return;
    }
    _registerPass();
  }

  /// Flies a bot's tile from its seat to the board so the table shows who
  /// played it, then places it and passes the turn.
  void _flyBotTile(int seat, DominoTile tile, String side, int connected) {
    final player = _players[seat];
    final from = _seatRect(seat);
    final target = _boardTargetRect(tile, side, connected);
    player.hand.remove(tile);

    void land() {
      if (!mounted) return;
      setState(() {
        _board.add(PlacedTile(tile, side, connected));
        _animating = false;
        _current = (seat + 1) % 4;
        _selected = null;
        _dragTile = null;
        _consecutivePasses = 0;
      });
      if (player.hand.isEmpty) {
        _endHand(player.team);
        return;
      }
      _scheduleBots();
    }

    if (from == null || target == null) {
      land();
      return;
    }
    setState(() => _animating = true);
    _flyTile(
      tile,
      Rect.fromCenter(center: from.center, width: 50, height: 90),
      target,
      land,
    );
  }

  Rect? _seatRect(int seat) {
    final box = _seatKeys[seat].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// A player could not play. Count the pass; four in a row blocks the hand.
  void _registerPass() {
    _consecutivePasses++;
    if (_consecutivePasses >= 4) {
      _endBlocked();
      return;
    }
    setState(() {
      _current = (_current + 1) % 4;
      _selected = null;
      _dragTile = null;
    });
    _scheduleBots();
  }

  /// Blocked hand: the team with the fewest pips wins and scores the other
  /// team's pips.
  void _endBlocked() {
    final pips0 = _teamPips(0);
    final pips1 = _teamPips(1);
    final winningTeam = pips0 <= pips1 ? 0 : 1;
    final points = winningTeam == 0 ? pips1 : pips0;
    _finishHand(winningTeam, points);
  }

  void _endHand(int winningTeam) {
    final points = _teamPips(1 - winningTeam);
    _finishHand(winningTeam, points);
  }

  /// Adds the hand points, then either ends the match (win card) or deals the
  /// next hand automatically after a short pause.
  void _finishHand(int winningTeam, int points) {
    _botTimer?.cancel();
    setState(() {
      _handOver = true;
      if (winningTeam == 0) {
        _team1Score += points;
      } else {
        _team2Score += points;
      }
    });

    final gameOver =
        _team1Score >= _targetScore || _team2Score >= _targetScore;
    if (gameOver) {
      _showHandOver(winningTeam, points);
      return;
    }
    _botTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _startNextHand();
    });
  }

  int _teamPips(int team) {
    var total = 0;
    for (var i = 0; i < _players.length; i++) {
      if (_players[i].team != team) continue;
      final hand = i == 0 ? _hand : _players[i].hand;
      total += hand.fold<int>(0, (sum, t) => sum + t.top + t.bottom);
    }
    return total;
  }

  void _showHandOver(int winningTeam, int points) {
    final isWin = winningTeam == 0;
    final isGameOver =
        _team1Score >= _targetScore || _team2Score >= _targetScore;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HandOverDialog(
        isWin: isWin,
        isGameOver: isGameOver,
        winningTeam: winningTeam,
        points: points,
        team1Score: _team1Score,
        team2Score: _team2Score,
        targetScore: _targetScore,
        onPrimary: () {
          Navigator.pop(ctx);
          if (isGameOver) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GameScreen()),
            );
          } else {
            _startNextHand();
          }
        },
        onMenu: () {
          Navigator.pop(ctx);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScoreHeader(
              team1Score: _team1Score,
              team2Score: _team2Score,
              targetScore: _targetScore,
              turnFraction: _turnFraction,
              onMenu: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ClipRect(
                child: Stack(
                  children: [
                    const Positioned.fill(child: _Felt()),
                    // Drop anywhere on the table: if only one end fits, play there.
                    Positioned.fill(
                      child: DragTarget<DominoTile>(
                        onWillAcceptWithDetails: (details) {
                          if (_current != 0 || _handOver || _animating) {
                            return false;
                          }
                          final ends = _endsFor(details.data);
                          return ends.left != ends.right;
                        },
                        onAcceptWithDetails: (details) {
                          final ends = _endsFor(details.data);
                          _onDropTile(
                            details.data,
                            ends.left ? 'left' : 'right',
                            details.offset,
                          );
                        },
                        builder: (context, candidate, rejected) =>
                            const SizedBox.expand(),
                      ),
                    ),
                    // Partner across the table (team 1).
                    Positioned(
                      key: _seatKeys[2],
                      top: 4,
                      left: 0,
                      right: 0,
                      child: OpponentSeat(
                        player: _players[2],
                        playerIndex: 2,
                        isCurrentTurn: _current == 2,
                        turnProgress: _current == 2 ? _turnFraction : 1,
                      ),
                    ),
                    // Left opponent (team 2).
                    Positioned(
                      key: _seatKeys[1],
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: OpponentSeat(
                          player: _players[1],
                          playerIndex: 1,
                          isCurrentTurn: _current == 1,
                          turnProgress: _current == 1 ? _turnFraction : 1,
                          direction: Axis.vertical,
                        ),
                      ),
                    ),
                    // Right opponent (team 2).
                    Positioned(
                      key: _seatKeys[3],
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: OpponentSeat(
                          player: _players[3],
                          playerIndex: 3,
                          isCurrentTurn: _current == 3,
                          turnProgress: _current == 3 ? _turnFraction : 1,
                          direction: Axis.vertical,
                        ),
                      ),
                    ),
                    // The domino board.
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(58, 50, 58, 28),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GameBoard(
                              key: _boardKey,
                              board: _board,
                              tileBuilder:
                                  (
                                    tile, {
                                    required bool horizontal,
                                    required bool isFlipped,
                                    required double scale,
                                  }) {
                                    return SpriteDominoTile(
                                      tile: tile,
                                      horizontal: horizontal,
                                      isFlipped: isFlipped,
                                      scale: scale,
                                    );
                                  },
                            ),
                            ..._buildEndTargets(),
                          ],
                        ),
                      ),
                    ),
                    // Whose turn it is.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 6,
                      child: Center(child: _turnPill(_current == 0)),
                    ),
                  ],
                ),
              ),
            ),
            PlayerRack(
              hand: _hand,
              playable: _playable,
              isMyTurn: _current == 0,
              turnFraction: _turnFraction,
              onTileTap: _playHuman,
              onSort: () {},
              onReorder: _reorderHand,
              onPlayDragChanged: (tile) {
                if (_dragTile != tile) {
                  setState(() => _dragTile = tile);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _turnPill(bool isHumanTurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHumanTurn ? const Color(0xFFFFD700) : Colors.white24,
          width: 1.2,
        ),
      ),
      child: Text(
        isHumanTurn ? 'YOUR TURN' : 'Bot is thinking...',
        style: TextStyle(
          color: isHumanTurn ? const Color(0xFFFFD700) : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Green felt table background.
class _Felt extends StatelessWidget {
  const _Felt();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.0,
              colors: [Color(0xFF26703F), Color(0xFF17512F), Color(0xFF0A2A19)],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x14FFFFFF), Color(0x00FFFFFF), Color(0x22000000)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.0,
              colors: [Color(0x00000000), Color(0x73000000)],
              stops: [0.6, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
