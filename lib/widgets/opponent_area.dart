import 'package:flutter/material.dart';
import '../models/player.dart';

/// Opponent area widget matching the Dominoes Battle 2x2 table style.
/// Shows avatar, name plate, timer bar, and face-down tiles fanned in the
/// correct direction (horizontal for the top partner, vertical for sides).
class OpponentArea extends StatelessWidget {
  final Player player;
  final int playerIndex;
  final bool isCurrentPlayer;
  final Axis tileDirection; // horizontal for top, vertical for left/right
  final double? timerFraction; // 0..1 remaining time for the current player

  const OpponentArea({
    super.key,
    required this.player,
    required this.playerIndex,
    this.isCurrentPlayer = false,
    this.tileDirection = Axis.horizontal,
    this.timerFraction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF1565C0), // Blue
      const Color(0xFF6A1B9A), // Purple
      const Color(0xFF2E7D32), // Green
      const Color(0xFFE65100), // Orange
    ];
    final color = colors[playerIndex % colors.length];

    return tileDirection == Axis.horizontal
        ? _buildHorizontal(color)
        : _buildVertical(color);
  }

  Widget _buildHorizontal(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatar(color),
            const SizedBox(width: 8),
            _buildNamePlate(color),
          ],
        ),
        if (timerFraction != null) ...[
          const SizedBox(height: 6),
          _buildTimerBar(),
        ],
        const SizedBox(height: 6),
        _buildTileFan(),
      ],
    );
  }

  Widget _buildVertical(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildAvatar(color),
        const SizedBox(height: 6),
        _buildNamePlate(color),
        if (timerFraction != null) ...[
          const SizedBox(height: 6),
          _buildTimerBar(),
        ],
        const SizedBox(height: 6),
        _buildTileFan(),
      ],
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        border: Border.all(
          color: isCurrentPlayer ? const Color(0xFFFFD54F) : Colors.white,
          width: isCurrentPlayer ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          player.name.characters.first,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildNamePlate(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentPlayer ? const Color(0xFFFFD54F) : Colors.white24,
          width: isCurrentPlayer ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.9), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${player.hand.length}',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final fraction = (timerFraction ?? 1).clamp(0.0, 1.0);
    final color = fraction > 0.5
        ? const Color(0xFF66BB6A)
        : fraction > 0.25
            ? const Color(0xFFFFA726)
            : const Color(0xFFE53935);
    return Container(
      width: tileDirection == Axis.horizontal ? 120 : 34,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileFan() {
    final count = player.hand.length.clamp(0, 7);
    if (count == 0) return const SizedBox.shrink();

    if (tileDirection == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) => _faceDownTile(i, count)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) => _faceDownTile(i, count)),
    );
  }

  Widget _faceDownTile(int index, int total) {
    final horizontal = tileDirection == Axis.horizontal;
    final margin = horizontal
        ? const EdgeInsets.symmetric(horizontal: 1.5)
        : const EdgeInsets.symmetric(vertical: 1.5);

    return Container(
      width: horizontal ? 26.0 : 30.0,
      height: horizontal ? 38.0 : 22.0,
      margin: margin,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF78909C), Color(0xFF546E7A)],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCurrentPlayer ? const Color(0xFFFFD54F) : const Color(0xFF455A64),
          width: isCurrentPlayer ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
            ),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFFFFC107), width: 0.5),
          ),
        ),
      ),
    );
  }
}
