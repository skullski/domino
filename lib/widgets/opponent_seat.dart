import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/player.dart';
import 'sprite_domino_tile.dart';

/// An opponent seat: avatar, name plate, tile fan and turn timer.
class OpponentSeat extends StatelessWidget {
  final Player player;
  final int playerIndex;
  final bool isCurrentTurn;
  final double turnProgress;
  final Axis direction;

  const OpponentSeat({
    super.key,
    required this.player,
    required this.playerIndex,
    this.isCurrentTurn = false,
    this.turnProgress = 1.0,
    this.direction = Axis.horizontal,
  });

  static const List<Color> _colors = [
    Color(0xFF42A5F5),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
  ];

  /// Fan tile scale: 0.504 scaled up by 20%.
  static const double _tileScale = 0.6048;

  @override
  Widget build(BuildContext context) {
    final color = _colors[playerIndex % _colors.length];

    if (direction == Axis.horizontal) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Tiles centred; 70% hidden under the top edge (30% visible).
          Transform.translate(
            offset: Offset(0, -(130 * _tileScale) * 0.7),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, left: 8),
              child: _tileFan(context),
            ),
          ),
          // Avatar + name take whatever space is free on the right.
          Positioned(
            right: 6,
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _avatar(color),
                const SizedBox(height: 3),
                _namePlate(color),
              ],
            ),
          ),
        ],
      );
    }

    // Avatars sit clockwise around the table: left seat on top, right seat
    // at the bottom.
    final avatarDown = playerIndex == 3;
    return Padding(
      padding: EdgeInsets.only(
        left: playerIndex == 1 ? 8 : 0,
        right: playerIndex == 3 ? 8 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: playerIndex == 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (!avatarDown) ...[
            _avatar(color),
            const SizedBox(height: 4),
            _namePlate(color),
          ],
          const SizedBox(height: 3),
          Transform.translate(
            // Hide 70% of the tiles under the side edge (30% visible).
            offset: Offset(
              (playerIndex == 1 ? -1 : 1) * (130 * _tileScale * 0.7),
              0,
            ),
            child: _tileFan(context),
          ),
          if (avatarDown) ...[
            const SizedBox(height: 4),
            _avatar(color),
            const SizedBox(height: 4),
            _namePlate(color),
          ],
        ],
      ),
    );
  }

  Widget _avatar(Color color) {
    final avatar = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: isCurrentTurn ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.5),
          width: isCurrentTurn ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          if (isCurrentTurn)
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              blurRadius: 12,
            ),
        ],
      ),
      child: Center(
        child: Text(
          player.name.isEmpty ? '?' : player.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCurrentTurn)
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                value: turnProgress.clamp(0.0, 1.0),
                strokeWidth: 3,
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
              ),
            ),
          avatar,
        ],
      ),
    );
  }

  Widget _namePlate(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentTurn
              ? const Color(0xFFFFD700).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${player.hand.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timer() {
    final f = turnProgress.clamp(0.0, 1.0);
    final color = f > 0.5
        ? const Color(0xFF69F0AE)
        : f > 0.25
            ? const Color(0xFFFFD740)
            : const Color(0xFFFF5252);
    return Container(
      width: direction == Axis.horizontal ? 92 : 60,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: f,
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }

  Widget _tileFan(BuildContext context) {
    final count = player.hand.length.clamp(0, 7);
    if (count == 0) return const SizedBox.shrink();

    // Keep the big tile size. Tiles overlap only when the row/stack would
    // otherwise not fit, so the whole hand stays on screen.
    const scale = _tileScale;
    final isTop = direction == Axis.horizontal;
    // Side seats lie flat and point at the table; the top seat stands up.
    final tileW =
        (isTop ? SpriteDominoTile.spriteWidth : SpriteDominoTile.spriteHeight) *
            scale;
    final tileH =
        (isTop ? SpriteDominoTile.spriteHeight : SpriteDominoTile.spriteWidth) *
            scale;
    final long = isTop ? tileW : tileH;

    final screen = MediaQuery.sizeOf(context);
    final maxLong = isTop ? screen.width - 130 : screen.height * 0.52;
    final step = count > 1
        ? math.min(
            long + 2,
            math.max(long * 0.45, (maxLong - long) / (count - 1)),
          )
        : long + 2;
    final total = long + (count - 1) * step;

    return SizedBox(
      width: isTop ? total : tileW,
      height: isTop ? tileH : total,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: isTop ? i * step : 0,
              top: isTop ? 0 : i * step,
              child: SpriteDominoTile(
                tile: player.hand[i],
                faceDown: true,
                horizontal: !isTop,
                scale: scale,
              ),
            ),
        ],
      ),
    );
  }
}
