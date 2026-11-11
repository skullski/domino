import 'package:flutter/material.dart';

/// Match header: each team races from its own side of the bar toward the
/// center. The first team whose bar reaches the center (target score) wins.
class ScoreHeader extends StatelessWidget {
  final int team1Score;
  final int team2Score;
  final int targetScore;
  final double turnFraction;
  final String team1Name;
  final String team2Name;
  final VoidCallback? onMenu;

  const ScoreHeader({
    super.key,
    required this.team1Score,
    required this.team2Score,
    required this.targetScore,
    required this.turnFraction,
    this.team1Name = 'TEAM 1',
    this.team2Name = 'TEAM 2',
    this.onMenu,
  });

  static const _team1 = Color(0xFF4FC3F7);
  static const _team1Deep = Color(0xFF0277BD);
  static const _team2 = Color(0xFFF06292);
  static const _team2Deep = Color(0xFF880E4F);
  static const _gold = Color(0xFFFFD54A);

  @override
  Widget build(BuildContext context) {
    final target = targetScore <= 0 ? 1 : targetScore;
    final p1 = (team1Score / target).clamp(0.0, 1.0);
    final p2 = (team2Score / target).clamp(0.0, 1.0);
    final leader = team1Score == team2Score
        ? 0
        : (team1Score > team2Score ? 1 : 2);

    return SizedBox(
      height: 112,
      child: Stack(
        children: [
          Positioned.fill(child: _banner()),
          Positioned(
            left: 16,
            top: 12,
            child: _teamBlock(
              team1Name,
              team1Score,
              _team1,
              leading: leader == 1,
            ),
          ),
          Positioned(
            right: 58,
            top: 12,
            child: _teamBlock(
              team2Name,
              team2Score,
              _team2,
              leading: leader == 2,
              alignRight: true,
            ),
          ),
          Positioned(top: 6, left: 0, right: 0, child: Center(child: _trophy())),
          Positioned(right: 8, top: 10, child: _menuButton()),
          Positioned(
            left: 16,
            right: 16,
            top: 68,
            height: 18,
            child: _raceTrack(p1, p2),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 90,
            child: _toGoRow(target),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 4,
            child: _turnStrip(),
          ),
        ],
      ),
    );
  }

  Widget _banner() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF233A8F), Color(0xFF0E1A4A)],
        ),
        border: Border(
          bottom: BorderSide(color: _gold.withValues(alpha: 0.5), width: 1.5),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.2),
            radius: 1.0,
            colors: [Colors.white.withValues(alpha: 0.14), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _teamBlock(
    String name,
    int score,
    Color color, {
    required bool leading,
    bool alignRight = false,
  }) {
    final crossAlign = alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final nameRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!alignRight) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          name.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        if (alignRight) ...[
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
        ],
      ],
    );

    final scoreRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading && !alignRight)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: _gold,
              size: 16,
            ),
          ),
        Text(
          '$score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.0,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.7), blurRadius: 12),
              const Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
        if (leading && alignRight)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: _gold,
              size: 16,
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: crossAlign,
      mainAxisSize: MainAxisSize.min,
      children: [nameRow, const SizedBox(height: 2), scoreRow],
    );
  }

  Widget _raceTrack(double p1, double p2) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth / 2;
        final w1 = half * p1;
        final w2 = half * p2;

        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              children: [
                for (final q in const [0.25, 0.75])
                  Positioned(
                    left: constraints.maxWidth * q,
                    top: 0,
                    bottom: 0,
                    width: 1,
                    child: Container(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: w1,
                  child: _fill(_team1, _team1Deep, fromLeft: true),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: w2,
                  child: _fill(_team2, _team2Deep, fromLeft: false),
                ),
                Positioned(
                  left: half - 1.5,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _gold,
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fill(Color light, Color deep, {required bool fromLeft}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [light, deep],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _toGoRow(int target) {
    final toGo1 = (target - team1Score).clamp(0, target);
    final toGo2 = (target - team2Score).clamp(0, target);
    return Row(
      children: [
        Expanded(
          child: _toGoLabel(toGo1, _team1, alignRight: false),
        ),
        Text(
          'FIRST TO $target',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        Expanded(
          child: _toGoLabel(toGo2, _team2, alignRight: true),
        ),
      ],
    );
  }

  Widget _toGoLabel(int toGo, Color color, {required bool alignRight}) {
    final text = toGo == 0 ? 'REACHED' : '$toGo TO GO';
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _turnStrip() {
    final f = turnFraction.clamp(0.0, 1.0);
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: f,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trophy() {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3B0), Color(0xFFFFB300), Color(0xFFB86A00)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2F4BB8), Color(0xFF162A7A)],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded, color: _gold, size: 12),
            Text(
              '$targetScore',
              style: const TextStyle(
                color: Color(0xFFFFF3C4),
                fontSize: 15,
                fontWeight: FontWeight.w900,
                height: 1.0,
                shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton() {
    return GestureDetector(
      onTap: onMenu,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A7DFF), Color(0xFF1F4FC4)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: CustomPaint(size: Size(20, 16), painter: _MenuIconPainter()),
        ),
      ),
    );
  }
}

class _MenuIconPainter extends CustomPainter {
  const _MenuIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final barH = size.height / 5;
    final radius = Radius.circular(barH / 2);
    final paint = Paint()..color = Colors.white;
    for (final y in [0.0, size.height / 2 - barH / 2, size.height - barH]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, size.width, barH),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MenuIconPainter oldDelegate) => false;
}
