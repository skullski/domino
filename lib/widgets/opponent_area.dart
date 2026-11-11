import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/player.dart';

class OpponentArea extends StatelessWidget {
  final Player player;
  final int playerIndex;
  final bool isCurrentPlayer;
  final Axis tileDirection;
  final double? timerFraction;

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
      const Color(0xFF42A5F5),
      const Color(0xFFEF5350),
      const Color(0xFF66BB6A),
      const Color(0xFFFFA726),
    ];
    final color = colors[playerIndex % colors.length];
    return tileDirection == Axis.horizontal ? _buildHorizontal(color) : _buildVertical(color);
  }

  Widget _buildHorizontal(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [_buildAvatar(color), const SizedBox(width: 6), _buildNamePlate(color)]),
        if (timerFraction != null) ...[const SizedBox(height: 4), _buildTimerBar()],
        const SizedBox(height: 4),
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
        const SizedBox(height: 4),
        _buildNamePlate(color),
        if (timerFraction != null) ...[const SizedBox(height: 4), _buildTimerBar()],
        const SizedBox(height: 4),
        _buildTileFan(),
      ],
    );
  }

  Widget _buildAvatar(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withOpacity(0.65)]),
        border: Border.all(
          color: isCurrentPlayer ? const Color(0xFFFFD60A) : Colors.white.withOpacity(0.6),
          width: isCurrentPlayer ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2)),
          if (isCurrentPlayer) BoxShadow(color: const Color(0xFFFFD60A).withOpacity(0.5), blurRadius: 14),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isCurrentPlayer)
            ...List.generate(4, (i) {
              final angle = i * math.pi / 2;
              return Positioned(
                left: 21 + math.cos(angle) * 20 - 6,
                top: 21 + math.sin(angle) * 20 - 3,
                child: Transform.rotate(
                  angle: angle + math.pi / 2,
                  child: CustomPaint(size: const Size(12, 6), painter: _WingPainter(color: const Color(0xFFFFD60A))),
                ),
              );
            }),
          Text(
            player.name.characters.first,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNamePlate(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCurrentPlayer ? const Color(0xFFFFD60A).withOpacity(0.5) : Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(player.name, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 4)])),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
            ),
            child: Text('${player.hand.length}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final fraction = (timerFraction ?? 1).clamp(0.0, 1.0);
    final color = fraction > 0.5 ? const Color(0xFF4CAF50) : fraction > 0.25 ? const Color(0xFFFFA726) : const Color(0xFFEF5350);
    return Container(
      width: tileDirection == Axis.horizontal ? 110 : 32,
      height: 7,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: Stack(children: [
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.65)]),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTileFan() {
    final count = player.hand.length.clamp(0, 7);
    if (count == 0) return const SizedBox.shrink();
    return tileDirection == Axis.horizontal
        ? Row(mainAxisSize: MainAxisSize.min, children: List.generate(count, _faceDownTile))
        : Column(mainAxisSize: MainAxisSize.min, children: List.generate(count, _faceDownTile));
  }

  Widget _faceDownTile(int index) {
    final horizontal = tileDirection == Axis.horizontal;
    final margin = horizontal ? const EdgeInsets.symmetric(horizontal: 1.5) : const EdgeInsets.symmetric(vertical: 1.5);
    final tw = horizontal ? 24.0 : 28.0;
    final th = horizontal ? 36.0 : 20.0;

    return Container(
      width: tw,
      height: th,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF5F5F5),
            const Color(0xFFE8E8E8),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCurrentPlayer ? const Color(0xFFFFD60A) : const Color(0xFFBDBDBD),
          width: isCurrentPlayer ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 1, offset: const Offset(0, -1)),
        ],
      ),
      child: Center(
        child: Container(
          width: horizontal ? 1.0 : tw * 0.6,
          height: horizontal ? th * 0.6 : 1.0,
          color: const Color(0xFFBDBDBD),
        ),
      ),
    );
  }
}

class _WingPainter extends CustomPainter {
  final Color color;
  _WingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..quadraticBezierTo(size.width * 0.3, -size.height * 0.3, size.width, 0)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.3, 0, size.height / 2);

    canvas.drawPath(path, Paint()..color = color.withOpacity(0.7));
    canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant _WingPainter old) => false;
}
