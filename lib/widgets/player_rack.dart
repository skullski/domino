import 'package:flutter/material.dart';

import '../models/domino_tile.dart';
import 'sprite_domino_tile.dart';

/// The player's hand tray: bench background, tiles, sort and pass buttons.
class PlayerRack extends StatelessWidget {
  final List<DominoTile> hand;
  final Set<DominoTile> playable;
  final bool isMyTurn;
  final double turnFraction;
  final void Function(DominoTile tile, Rect? fromRect) onTileTap;
  final VoidCallback onSort;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<DominoTile?>? onPlayDragChanged;

  const PlayerRack({
    super.key,
    required this.hand,
    required this.playable,
    required this.isMyTurn,
    required this.turnFraction,
    required this.onTileTap,
    required this.onSort,
    required this.onReorder,
    this.onPlayDragChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 117,
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8D6E63),
                    Color(0xFF5D4037),
                    Color(0xFF3A2520),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 56,
            right: 12,
            top: 0,
            bottom: 6,
            child: hand.isEmpty
                ? const Center(
                    child: Text(
                      'No tiles',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : _SmoothHand(
                    hand: hand,
                    playable: playable,
                    isMyTurn: isMyTurn,
                    onTileTap: onTileTap,
                    onReorder: onReorder,
                    onPlayDragChanged: onPlayDragChanged,
                  ),
          ),
          Positioned(
            left: 6,
            top: 6,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isMyTurn)
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: turnFraction.clamp(0.0, 1.0),
                        strokeWidth: 3,
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                      ),
                    ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Y',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A hand of tiles that can be reordered with a responsive horizontal drag.
///
/// The grabbed tile follows the finger, while the remaining tiles glide to
/// their new slots with an implicit animation.
class _SmoothHand extends StatefulWidget {
  final List<DominoTile> hand;
  final Set<DominoTile> playable;
  final bool isMyTurn;
  final void Function(DominoTile tile, Rect? fromRect) onTileTap;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<DominoTile?>? onPlayDragChanged;

  const _SmoothHand({
    required this.hand,
    required this.playable,
    required this.isMyTurn,
    required this.onTileTap,
    required this.onReorder,
    this.onPlayDragChanged,
  });

  @override
  State<_SmoothHand> createState() => _SmoothHandState();
}

class _SmoothHandState extends State<_SmoothHand> {
  int? _dragIndex;
  int? _targetIndex;
  Rect? _tapRect;
  bool _droppedInHand = false;

  // Layout metrics cached from the last build so drag callbacks can map a
  // global pointer position to a slot index.
  double _leftPad = 0;
  double _slotW = 1;
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = widget.hand.length;
        final scale = ((constraints.maxWidth / n - 4) / 60)
            .clamp(0.25, 0.8)
            .toDouble();
        final tileW = 60 * scale;
        final tileH = 130 * scale;
        final slotW = tileW + 4;
        final totalW = n * slotW - 4;
        final leftPad = (constraints.maxWidth - totalW) / 2;
        final topPad = (constraints.maxHeight - tileH) / 2;

        _leftPad = leftPad;
        _slotW = slotW;
        _count = n;

        double xFor(int i) {
          final from = _dragIndex;
          final to = _targetIndex;
          final base = leftPad + i * slotW;
          if (from == null || to == null) return base;
          if (i == from) return base;
          if (from < to && i > from && i <= to) {
            return leftPad + (i - 1) * slotW;
          }
          if (from > to && i >= to && i < from) {
            return leftPad + (i + 1) * slotW;
          }
          return base;
        }

        return DragTarget<DominoTile>(
          onWillAcceptWithDetails: (_) => true,
          onMove: (details) => _updateTarget(details.offset),
          onAcceptWithDetails: (details) {
            _droppedInHand = true;
            _updateTarget(details.offset);
            _finishDrag();
          },
          builder: (context, candidate, rejected) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < n; i++)
                  _buildTile(i, xFor(i), topPad, scale, tileW, tileH, slotW),
              ],
            );
          },
        );
      },
    );
  }

  void _updateTarget(Offset global) {
    if (_count == 0) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global);
    final t = ((local.dx - _leftPad) / _slotW).round().clamp(0, _count - 1);
    if (t != _targetIndex) {
      setState(() => _targetIndex = t);
    }
  }

  void _finishDrag() {
    final from = _dragIndex;
    final to = _targetIndex;
    final dropped = _droppedInHand;
    _droppedInHand = false;
    setState(() {
      _dragIndex = null;
      _targetIndex = null;
    });
    if (dropped && from != null && to != null && from != to) {
      widget.onReorder(from, to);
    }
  }

  Widget _buildTile(
    int i,
    double x,
    double topPad,
    double scale,
    double tileW,
    double tileH,
    double slotW,
  ) {
    final tile = widget.hand[i];
    final canPlay = widget.isMyTurn && widget.playable.contains(tile);
    // The tile's extruded side and shadow reach right and down; shift the box
    // up-left by half of that so the visible tile sits centred in its slot.
    final shiftX = 1.4 * scale;
    final shiftY = 2.0 * scale;

    return AnimatedPositioned(
      key: ValueKey(tile),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      left: x - shiftX,
      top: topPad - shiftY,
      width: tileW,
      height: tileH,
      child: Draggable<DominoTile>(
        data: tile,
        feedback: Material(
          color: Colors.transparent,
          child: SpriteDominoTile(tile: tile, scale: scale, isSelected: true),
        ),
        childWhenDragging: const SizedBox.shrink(),
        onDragStarted: () {
          setState(() {
            _dragIndex = i;
            _targetIndex = i;
          });
          widget.onPlayDragChanged?.call(tile);
        },
        onDragUpdate: (details) => _updateTarget(details.globalPosition),
        onDragEnd: (_) {
          widget.onPlayDragChanged?.call(null);
          _finishDrag();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _tapRect = Rect.fromCenter(
              center: details.globalPosition,
              width: tileW,
              height: tileH,
            );
          },
          onTap: canPlay ? () => widget.onTileTap(tile, _tapRect) : null,
          child: SpriteDominoTile(
            tile: tile,
            scale: scale,
            isPlayable: canPlay,
            dimmed: widget.isMyTurn && !canPlay,
          ),
        ),
      ),
    );
  }
}
