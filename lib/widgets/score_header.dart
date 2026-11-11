import 'package:flutter/material.dart';

import '../theme/arcade_ui.dart';

/// Match header in the menu's arcade style: each team races from its own side
/// of the bar toward the centre. First team to the target wins.
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

  static const _team1 = ArcadeColors.aqua;
  static const _team1Deep = ArcadeColors.aquaDeep;
  static const _team2 = ArcadeColors.pink;
  static const _team2Deep = Color(0xFFD6336C);

  @override
  Widget build(BuildContext context) {
    final target = targetScore <= 0 ? 1 : targetScore;
    final p1 = (team1Score / target).clamp(0.0, 1.0);
    final p2 = (team2Score / target).clamp(0.0, 1.0);
    final leader = team1Score == team2Score
        ? 0
        : (team1Score > team2Score ? 1 : 2);

    return SizedBox(
      height: 107,
      child: Stack(
        children: [
          Positioned.fill(child: _backdrop()),
          Positioned(
            left: 10,
            right: 10,
            top: 6,
            height: 93,
            child: ArcadePanel(
              radius: 22,
              child: Stack(
                children: [
                  Positioned(
                    left: 14,
                    top: 6,
                    child: _teamBlock(
                      team1Name,
                      team1Score,
                      _team1,
                      _team1Deep,
                      leading: leader == 1,
                    ),
                  ),
                  Positioned(
                    right: 46,
                    top: 6,
                    child: _teamBlock(
                      team2Name,
                      team2Score,
                      _team2,
                      _team2Deep,
                      leading: leader == 2,
                      alignRight: true,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(child: _medallion(target)),
                  ),
                  Positioned(right: 6, top: 6, child: _menuButton()),
                  Positioned(
                    left: 10,
                    right: 10,
                    top: 54,
                    height: 16,
                    child: _raceTrack(p1, p2),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 74,
                    child: _toGoRow(target),
                  ),
                ],
              ),
            ),
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

  Widget _backdrop() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ArcadeColors.skyTop, ArcadeColors.skyMid],
        ),
        border: Border(
          bottom: BorderSide(
            color: ArcadeColors.gold.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.3),
            radius: 0.9,
            colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _teamBlock(
    String name,
    int score,
    Color color,
    Color deep, {
    required bool leading,
    bool alignRight = false,
  }) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 5)],
      ),
    );

    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignRight) ...[dot, const SizedBox(width: 5)],
            Text(
              name.toUpperCase(),
              style: TextStyle(
                color: ArcadeColors.navy.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            if (alignRight) ...[const SizedBox(width: 5), dot],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          '$score',
          style: const TextStyle(
            color: ArcadeColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        if (leading)
          Container(
            width: 26,
            height: 3,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ArcadeColors.gold, ArcadeColors.goldDeep],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
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
            color: ArcadeColors.navy,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ArcadeColors.navyDeep.withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: ArcadeColors.navy.withValues(alpha: 0.25),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
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
                      color: ArcadeColors.gold,
                      boxShadow: [
                        BoxShadow(
                          color: ArcadeColors.gold.withValues(alpha: 0.8),
                          blurRadius: 7,
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
            colors: [Colors.white.withValues(alpha: 0.38), Colors.transparent],
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
        Expanded(child: _toGoLabel(toGo1, _team1Deep, alignRight: false)),
        Text(
          'FIRST TO $target',
          style: TextStyle(
            color: ArcadeColors.navy.withValues(alpha: 0.55),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        Expanded(child: _toGoLabel(toGo2, _team2Deep, alignRight: true)),
      ],
    );
  }

  Widget _toGoLabel(int toGo, Color color, {required bool alignRight}) {
    return Text(
      toGo == 0 ? 'REACHED' : '$toGo TO GO',
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _medallion(int target) {
    return Container(
      width: 45,
      height: 45,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArcadeColors.gold, ArcadeColors.goldDeep, Color(0xFFC77800)],
        ),
        boxShadow: [
          BoxShadow(
            color: ArcadeColors.goldDeep.withValues(alpha: 0.45),
            blurRadius: 10,
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
            colors: [Color(0xFF1D3C86), ArcadeColors.navyDeep],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$target',
          style: const TextStyle(
            color: ArcadeColors.gold,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
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
            colors: [ArcadeColors.skyMid, ArcadeColors.skyDeep],
          ),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: ArcadeColors.navy.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: ArcadeMenuGlyph(color: Colors.white, width: 18, height: 14),
        ),
      ),
    );
  }

  Widget _turnStrip() {
    final f = turnFraction.clamp(0.0, 1.0);
    return Container(
      color: ArcadeColors.navy,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: f,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ArcadeColors.gold, ArcadeColors.goldDeep],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
