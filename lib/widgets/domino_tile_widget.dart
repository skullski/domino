import 'package:flutter/material.dart';
import '../models/domino_tile.dart';

/// Domino tile widget matching the open-source hendersonh design:
/// ivory radial-gradient body, colored pips by value, gold marker on doubles,
/// 102:50 aspect ratio. `horizontal` tiles lie flat; `vertical` tiles stand up
/// (used for the player's hand rack and side opponents).
class DominoTileWidget extends StatelessWidget {
  final DominoTile tile;
  final bool isSelected;
  final bool isPlayable;
  final VoidCallback? onTap;
  final bool horizontal;
  final bool isFlipped;
  final double scale;
  final bool faceDown;

  const DominoTileWidget({
    super.key,
    required this.tile,
    this.isSelected = false,
    this.isPlayable = false,
    this.onTap,
    this.horizontal = true,
    this.isFlipped = false,
    this.scale = 1.0,
    this.faceDown = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = (horizontal ? 102.0 : 50.0) * scale;
    final h = (horizontal ? 50.0 : 102.0) * scale;

    final borderColor = isSelected
        ? const Color(0xFF2BEE4B)
        : isPlayable
            ? const Color(0xFF2BEE4B).withValues(alpha: 0.5)
            : const Color(0xFF9CA3AF).withValues(alpha: 0.4);
    final borderWidth = isSelected
        ? 4.0 * scale
        : isPlayable
            ? 2.0 * scale
            : 1.5 * scale;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: w,
            height: h,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(-0.2, -0.4),
                radius: 1.2,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFDFBF7),
                  Color(0xFFF3F0E8),
                ],
              ),
              borderRadius: BorderRadius.circular(6 * scale),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF2BEE4B).withValues(alpha: 0.6),
                    blurRadius: 15 * scale,
                    spreadRadius: 2 * scale,
                  )
                else ...[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8 * scale,
                    offset: Offset(2 * scale, 4 * scale),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2 * scale,
                    offset: const Offset(0, 1),
                    spreadRadius: -1 * scale,
                  ),
                ],
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4 * scale),
              child: faceDown
                  ? _buildFaceDown(horizontal)
                  : _buildFace(horizontal),
            ),
          ),
          // Single gold marker on the divider for doubles (ref2 style).
          if (!faceDown && tile.isDouble)
            Container(
              width: 10 * scale,
              height: 10 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  radius: 1.0,
                  colors: [Color(0xFFFBBF24), Color(0xFFB45309)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 3 * scale,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaceDown(bool horizontal) {
    return Center(
      child: Container(
        width: (horizontal ? 34.0 : 28.0) * scale,
        height: (horizontal ? 28.0 : 34.0) * scale,
        decoration: BoxDecoration(
          color: const Color(0xFF546E7A),
          borderRadius: BorderRadius.circular(4 * scale),
          border: Border.all(color: const Color(0xFF78909C), width: 1 * scale),
        ),
        child: Icon(
          Icons.question_answer_rounded,
          color: const Color(0xFF90A4AE),
          size: 14 * scale,
        ),
      ),
    );
  }

  Widget _buildFace(bool horizontal) {
    final first = isFlipped ? tile.bottom : tile.top;
    final second = isFlipped ? tile.top : tile.bottom;
    return horizontal
        ? Row(
            children: [
              Expanded(child: _buildHalf(first, horizontal)),
              _buildDivider(vertical: true),
              Expanded(child: _buildHalf(second, horizontal)),
            ],
          )
        : Column(
            children: [
              Expanded(child: _buildHalf(first, horizontal)),
              _buildDivider(vertical: false),
              Expanded(child: _buildHalf(second, horizontal)),
            ],
          );
  }

  Widget _buildHalf(int value, bool horizontal) {
    return Center(
      child: SizedBox(
        width: 40 * scale,
        height: 40 * scale,
        child: CustomPaint(
          painter: _PipsPainter(
            count: value,
            color: _pipColor(value),
            scale: scale,
            isVertical: !horizontal,
          ),
        ),
      ),
    );
  }

  Color _pipColor(int value) {
    switch (value) {
      case 1:
        return const Color(0xFF3B82F6);
      case 2:
        return const Color(0xFF10B981);
      case 3:
        return const Color(0xFFEF4444);
      case 4:
        return const Color(0xFFF59E0B);
      case 5:
        return const Color(0xFF8B5CF6);
      case 6:
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF374151);
    }
  }

  Widget _buildDivider({required bool vertical}) {
    return vertical
        ? Container(width: 1.5 * scale, color: const Color(0xFF9CA3AF))
        : Container(height: 1.5 * scale, color: const Color(0xFF9CA3AF));
  }
}

class _PipsPainter extends CustomPainter {
  final int count;
  final Color color;
  final double scale;
  final bool isVertical;

  _PipsPainter({
    required this.count,
    required this.color,
    required this.scale,
    required this.isVertical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double dotSize = 8.0 * scale;
    final double w = size.width;
    final double h = size.height;
    final double pad = 8.0 * scale;

    void drawDot(double cx, double cy) {
      final center = Offset(cx, cy);
      canvas.drawCircle(
        center.translate(0.5 * scale, 0.5 * scale),
        dotSize / 2,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 * scale),
      );
      canvas.drawCircle(center, dotSize / 2, paint);
      canvas.drawCircle(
        center.translate(-0.5 * scale, -0.5 * scale),
        dotSize / 2.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5 * scale,
      );
    }

    if (count % 2 == 1) drawDot(w / 2, h / 2);

    if (count == 2 || count == 3) {
      if (isVertical) {
        drawDot(pad, pad);
        drawDot(w - pad, h - pad);
      } else {
        drawDot(w - pad, pad);
        drawDot(pad, h - pad);
      }
    }

    if (count >= 4) {
      drawDot(pad, pad);
      drawDot(w - pad, pad);
      drawDot(pad, h - pad);
      drawDot(w - pad, h - pad);
    }

    if (count == 6) {
      if (isVertical) {
        drawDot(pad, h / 2);
        drawDot(w - pad, h / 2);
      } else {
        drawDot(w / 2, pad);
        drawDot(w / 2, h - pad);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PipsPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.color != color ||
      oldDelegate.isVertical != isVertical ||
      oldDelegate.scale != scale;
}
