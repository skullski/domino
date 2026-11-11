import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/domino_tile.dart';

/// Renders a domino tile with the extracted game sprites.
///
/// The source faces are portrait (60x130) with the larger value on top.
/// [horizontal] lays the tile on its side, [isFlipped] swaps the two halves.
class SpriteDominoTile extends StatelessWidget {
  final DominoTile tile;
  final bool horizontal;
  final bool isFlipped;
  final bool faceDown;
  final double scale;
  final bool isSelected;
  final bool isPlayable;
  final bool dimmed;
  final VoidCallback? onTap;

  const SpriteDominoTile({
    super.key,
    required this.tile,
    this.horizontal = false,
    this.isFlipped = false,
    this.faceDown = false,
    this.scale = 1.0,
    this.isSelected = false,
    this.isPlayable = false,
    this.dimmed = false,
    this.onTap,
  });

  static const double spriteWidth = 60.0;
  static const double spriteHeight = 130.0;

  String get _asset {
    if (faceDown) return 'assets/tiles/t1back.png';
    final hi = math.max(tile.top, tile.bottom);
    final lo = math.min(tile.top, tile.bottom);
    return 'assets/tiles/t1d$hi$lo.png';
  }

  @override
  Widget build(BuildContext context) {
    final w = (horizontal ? spriteHeight : spriteWidth) * scale;
    final h = (horizontal ? spriteWidth : spriteHeight) * scale;
    final quarterTurns =
        ((horizontal ? 1 : 0) + (!faceDown && isFlipped ? 2 : 0)) % 4;

    Widget image(String asset, {double opacity = 1.0, Color? tint}) {
      return RotatedBox(
        quarterTurns: quarterTurns,
        child: Opacity(
          opacity: opacity,
          child: Image.asset(
            asset,
            width: spriteWidth * scale,
            height: spriteHeight * scale,
            fit: BoxFit.fill,
            color: tint,
            colorBlendMode: BlendMode.modulate,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: w,
        height: h,
        transform: Matrix4.translationValues(0, isSelected ? -8 * scale : 0, 0),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(4 * scale, 6 * scale),
              child: image('assets/tiles/t1shadow.png', opacity: 0.35),
            ),
            // Extruded side wall: stacked copies behind the face.
            for (int i = 5; i >= 1; i--)
              Transform.translate(
                offset: Offset(0.55 * i * scale, 0.8 * i * scale),
                child: image(_asset, tint: const Color(0xFF43301B)),
              ),
            image(_asset),
            if (!faceDown)
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3 * scale),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.10),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            if (dimmed && !faceDown)
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3 * scale),
                  color: const Color(0xFF0A1A2E).withValues(alpha: 0.42),
                ),
              ),
            if (isSelected || isPlayable)
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7 * scale),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF64B5F6),
                    width: (isSelected ? 3.0 : 2.0) * scale,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.55),
                        blurRadius: 14 * scale,
                        spreadRadius: 1 * scale,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
