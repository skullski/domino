import 'package:flutter/material.dart';

/// Palette shared by the menu, the in-game header and the result dialog.
class ArcadeColors {
  ArcadeColors._();

  static const skyTop = Color(0xFF7AD7FF);
  static const skyMid = Color(0xFF2E94EA);
  static const skyDeep = Color(0xFF1456B8);
  static const aqua = Color(0xFF45F0D2);
  static const aquaDeep = Color(0xFF14B39B);
  static const gold = Color(0xFFFFD84D);
  static const goldDeep = Color(0xFFF2A100);
  static const goldEdge = Color(0xFF8A4A00);
  static const green = Color(0xFF6BE46F);
  static const greenDeep = Color(0xFF1E9E3A);
  static const greenEdge = Color(0xFF0B6320);
  static const navy = Color(0xFF0B2A5B);
  static const navyDeep = Color(0xFF071C3F);
  static const pink = Color(0xFFFF5FA2);
  static const frost = Color(0xFFD9EEFF);
  static const frostEdge = Color(0xFF6E9FCF);
}

/// White rounded panel with a soft navy shadow, as used on the menu.
class ArcadePanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const ArcadePanel({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding = EdgeInsets.zero,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: ArcadeColors.navy.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFEAF5FF)],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor ?? Colors.white,
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Chunky button with a visible lower edge that sinks when pressed.
class ArcadeButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final List<Color> faceColors;
  final Color edgeColor;
  final double height;
  final double depth;
  final double radius;

  const ArcadeButton({
    super.key,
    required this.onTap,
    required this.child,
    required this.faceColors,
    required this.edgeColor,
    this.height = 54,
    this.depth = 8,
    this.radius = 18,
  });

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    final d = widget.depth;
    final radius = BorderRadius.circular(widget.radius);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: SizedBox(
        height: h + d,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.edgeColor,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _down ? d : 0,
              height: h,
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: widget.faceColors,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.5,
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.35),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(child: widget.child),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.2,
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
      ),
    );
  }
}

/// Extruded arcade text: navy outline plus a glossy gradient face.
class ArcadeTitleText extends StatelessWidget {
  final String text;
  final double fontSize;
  final List<Color> colors;
  final Color strokeColor;
  final double letterSpacing;

  const ArcadeTitleText(
    this.text, {
    super.key,
    this.fontSize = 30,
    this.colors = const [
      Color(0xFFFFFBE0),
      ArcadeColors.gold,
      ArcadeColors.goldDeep,
      Color(0xFFFFE680),
      Color(0xFFC77800),
    ],
    this.strokeColor = ArcadeColors.navyDeep,
    this.letterSpacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: letterSpacing,
      height: 1.0,
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (int i = 6; i >= 1; i--)
          Transform.translate(
            offset: Offset(0.3 * i, 0.7 * i),
            child: Text(
              text,
              style: style.copyWith(
                color: Color.lerp(strokeColor, Colors.black, (i - 1) / 5),
              ),
            ),
          ),
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.18
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
            stops: const [0.0, 0.42, 0.5, 0.56, 1.0],
          ).createShader(bounds),
          child: Text(text, style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}

/// Three-bar menu glyph drawn without the icon font.
class ArcadeMenuGlyph extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const ArcadeMenuGlyph({
    super.key,
    this.color = Colors.white,
    this.width = 20,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _MenuGlyphPainter(color),
    );
  }
}

class _MenuGlyphPainter extends CustomPainter {
  final Color color;

  const _MenuGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final barH = size.height / 5;
    final radius = Radius.circular(barH / 2);
    final paint = Paint()..color = color;
    for (final y in [
      0.0,
      size.height / 2 - barH / 2,
      size.height - barH,
    ]) {
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
  bool shouldRepaint(covariant _MenuGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
