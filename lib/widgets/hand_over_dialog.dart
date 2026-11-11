import 'package:flutter/material.dart';

import '../theme/arcade_ui.dart';

/// Result card shown after a hand or match ends, in the menu's arcade style.
class HandOverDialog extends StatelessWidget {
  final bool isWin;
  final bool isGameOver;
  final int winningTeam;
  final int points;
  final int team1Score;
  final int team2Score;
  final int targetScore;
  final VoidCallback onPrimary;
  final VoidCallback onMenu;

  const HandOverDialog({
    super.key,
    required this.isWin,
    required this.isGameOver,
    required this.winningTeam,
    required this.points,
    required this.team1Score,
    required this.team2Score,
    required this.targetScore,
    required this.onPrimary,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final title = isGameOver
        ? (isWin ? 'VICTORY' : 'DEFEAT')
        : (isWin ? 'HAND WON' : 'HAND LOST');
    final subtitle = isGameOver
        ? 'First to $targetScore — match complete'
        : isWin
            ? 'Your team won the hand'
            : 'Team ${winningTeam + 1} won the hand';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 336,
        child: ArcadePanel(
          radius: 26,
          borderColor: ArcadeColors.gold.withValues(alpha: 0.85),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(title),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ArcadeColors.navy.withValues(alpha: 0.6),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '+$points',
                        style: const TextStyle(
                          color: ArcadeColors.goldDeep,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'POINTS',
                        style: TextStyle(
                          color: ArcadeColors.navy.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _scoreTile(
                              'TEAM 1',
                              team1Score,
                              ArcadeColors.aquaDeep,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _scoreTile(
                              'TEAM 2',
                              team2Score,
                              const Color(0xFFD6336C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ArcadeButton(
                        onTap: onPrimary,
                        height: 52,
                        depth: 8,
                        radius: 18,
                        faceColors: const [
                          ArcadeColors.green,
                          ArcadeColors.greenDeep,
                        ],
                        edgeColor: ArcadeColors.greenEdge,
                        child: Text(
                          isGameOver ? 'NEW GAME' : 'NEXT HAND',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: ArcadeColors.greenEdge,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ArcadeButton(
                        onTap: onMenu,
                        height: 46,
                        depth: 6,
                        radius: 16,
                        faceColors: const [Colors.white, ArcadeColors.frost],
                        edgeColor: ArcadeColors.frostEdge,
                        child: const Text(
                          'MENU',
                          style: TextStyle(
                            color: ArcadeColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(String title) {
    return Container(
      width: double.infinity,
      height: 82,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ArcadeColors.skyTop, ArcadeColors.skyMid],
        ),
      ),
      child: ArcadeTitleText(
        title,
        fontSize: 27,
        letterSpacing: 2,
        colors: isWin
            ? const [
                Color(0xFFFFFBE0),
                ArcadeColors.gold,
                ArcadeColors.goldDeep,
                Color(0xFFFFE680),
                Color(0xFFC77800),
              ]
            : const [
                Colors.white,
                Color(0xFFD6E6F7),
                Color(0xFFA9C2DC),
                Color(0xFFD6E6F7),
                Color(0xFF7590AC),
              ],
      ),
    );
  }

  Widget _scoreTile(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.16), Colors.white],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: const TextStyle(
              color: ArcadeColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
