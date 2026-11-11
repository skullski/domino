import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/domino_tile.dart';
import '../widgets/sprite_domino_tile.dart';
import 'game_screen.dart';

class _C {
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

/// The first screen the player sees: profile, title, match setup and play.
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _float;
  late final AnimationController _shine;

  int _mode = 0; // 0 = 2v2 Teams, 1 = 1v1
  int _rule = 0; // 0 = Block, 1 = Draw, 2 = All Fives

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _float.dispose();
    _shine.dispose();
    super.dispose();
  }

  void _openGame() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  void _comingSoon(String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$name is coming soon'),
          duration: const Duration(milliseconds: 900),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) => _Backdrop(t: _float.value),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(child: _buildContent()),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _reveal(0.0, 0.40, _buildTopBar()),
        const Spacer(),
        _reveal(0.10, 0.55, _buildTitle()),
        const SizedBox(height: 18),
        _reveal(0.25, 0.80, _buildSetup()),
        const SizedBox(height: 18),
        _reveal(0.40, 0.90, _buildPlayButton()),
        const Spacer(),
        _reveal(0.60, 1.0, _buildNavRow()),
        const SizedBox(height: 14),
      ],
    );
  }

  /// Staggered fade + rise reveal driven by [_entrance].
  Widget _reveal(double start, double end, Widget child) {
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 36),
            child: child,
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Top bar
  // -----------------------------------------------------------------------

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(child: _buildProfileCard()),
          const SizedBox(width: 8),
          _currencyPill('assets/ui/icon_ico_coin.png', '1,250'),
          const SizedBox(width: 6),
          _currencyPill('assets/ui/icon_ico_gem.png', '112'),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return _Panel(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_C.gold, _C.goldDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_C.skyTop, _C.skyDeep],
                        ),
                      ),
                      child: const Center(
                        child: CustomPaint(
                          size: Size(22, 22),
                          painter: _PersonPainter(),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _C.navy,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _C.gold, width: 1.5),
                    ),
                    child: const Text(
                      '15',
                      style: TextStyle(
                        color: _C.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAYER',
                  style: TextStyle(
                    color: _C.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 7,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _C.navy.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.62,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_C.aqua, _C.aquaDeep],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '1,240 / 2,000 XP',
                  style: TextStyle(
                    color: _C.navy.withValues(alpha: 0.6),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currencyPill(String asset, String value) {
    return _Panel(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 22, height: 22),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: _C.navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Title
  // -----------------------------------------------------------------------

  Widget _buildTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: _perspective(ry: 0.5)..rotateZ(-0.22),
              child: const SpriteDominoTile(
                tile: DominoTile(6, 6),
                scale: 0.42,
              ),
            ),
            const SizedBox(width: 8),
            _extrudedTitle('DOMINO'),
            const SizedBox(width: 8),
            Transform(
              alignment: Alignment.center,
              transform: _perspective(ry: -0.5)..rotateZ(0.22),
              child: const SpriteDominoTile(
                tile: DominoTile(4, 1),
                scale: 0.42,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          decoration: BoxDecoration(
            color: _C.navy,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _C.navyDeep.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'BATTLE ARENA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _extrudedTitle(String text) {
    const style = TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w900,
      letterSpacing: 3,
      height: 1.0,
    );
    const layers = 16;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        for (int i = layers; i >= 1; i--)
          Transform.translate(
            offset: Offset(0.4 * i, 0.8 * i),
            child: Text(
              text,
              style: style.copyWith(
                color: Color.lerp(
                  _C.goldEdge,
                  _C.navyDeep,
                  (i - 1) / (layers - 1),
                ),
              ),
            ),
          ),
        Text(
          text,
          style: style.copyWith(
            foreground: ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 9
              ..strokeJoin = ui.StrokeJoin.round
              ..color = _C.navyDeep,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBE0),
              _C.gold,
              _C.goldDeep,
              Color(0xFFFFE680),
              Color(0xFFC77800),
            ],
            stops: [0.0, 0.42, 0.5, 0.56, 1.0],
          ).createShader(bounds),
          child: Text(
            text,
            style: style.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Setup
  // -----------------------------------------------------------------------

  Widget _buildSetup() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildModeTabs(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ruleChip(0, 'assets/ui/icon_ico_mode_block.png', 'BLOCK'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ruleChip(1, 'assets/ui/icon_ico_mode_draw.png', 'DRAW'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ruleChip(
                  2,
                  'assets/ui/icon_ico_mode_allfives.png',
                  'FIVES',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStats(),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return _Panel(
      radius: 20,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: _modeTab(0, 'assets/ui/icon_ico_white_tiles.png', '2 v 2 TEAMS'),
          ),
          Expanded(
            child: _modeTab(1, 'assets/ui/icon_ico_mode_fast.png', '1 v 1 DUEL'),
          ),
        ],
      ),
    );
  }

  Widget _modeTab(int index, String icon, String label) {
    final selected = _mode == index;
    return GestureDetector(
      onTap: () => setState(() => _mode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_C.aqua, _C.aquaDeep],
                )
              : null,
          borderRadius: BorderRadius.circular(15),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _C.aquaDeep.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(icon, width: 20, height: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? _C.navy : _C.skyDeep,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleChip(int index, String icon, String label) {
    final selected = _rule == index;
    return _PressButton(
      onTap: () => setState(() => _rule = index),
      height: 46,
      depth: 5,
      radius: 15,
      faceColors: selected
          ? const [_C.gold, _C.goldDeep]
          : const [Colors.white, _C.frost],
      edgeColor: selected ? _C.goldEdge : _C.frostEdge,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icon, width: 20, height: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? _C.navy : _C.skyDeep,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return _Panel(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          _stat('6', 'WINS', _C.greenDeep),
          _statDivider(),
          _stat('2', 'LOSSES', _C.pink),
          _statDivider(),
          _stat('3', 'STREAK', const Color(0xFFF57C00)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _C.navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: _C.skyDeep,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: _C.navy.withValues(alpha: 0.1),
    );
  }

  // -----------------------------------------------------------------------
  // Play + nav
  // -----------------------------------------------------------------------

  Widget _buildPlayButton() {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final scale = 1 + math.sin(_float.value * math.pi) * 0.015;
        return Transform.scale(scale: scale, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _C.green.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SizedBox(
          width: 268,
          child: _PressButton(
            onTap: _openGame,
            height: 68,
            depth: 12,
            radius: 24,
            faceColors: const [_C.green, _C.greenDeep],
            edgeColor: _C.greenEdge,
            sheen: _shine,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: CustomPaint(
                      size: Size(12, 14),
                      painter: _PlayPainter(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'PLAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                    shadows: [
                      Shadow(
                        color: _C.greenEdge,
                        offset: Offset(0, 2.5),
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

  Widget _buildNavRow() {
    final modeLabel = _mode == 0 ? '2V2' : '1V1';
    const ruleLabels = ['BLOCK', 'DRAW', 'FIVES'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _navButton(
                  'assets/ui/icon_ico_stats.png',
                  'RANKS',
                  () => _comingSoon('Ranks'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _navButton(
                  'assets/ui/icon_ico_options.png',
                  'MISSIONS',
                  () => _comingSoon('Missions'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _navButton(
                  'assets/ui/icon_ico_chatmessage.png',
                  'FRIENDS',
                  () => _comingSoon('Friends'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _navButton(
                  'assets/ui/icon_ico_settings.png',
                  'SETTINGS',
                  () => _comingSoon('Settings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'v1.0  ·  $modeLabel ${ruleLabels[_rule]} MODE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: _C.navyDeep.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String icon, String label, VoidCallback onTap) {
    return _PressButton(
      onTap: onTap,
      height: 72,
      depth: 6,
      radius: 16,
      faceColors: const [Colors.white, _C.frost],
      edgeColor: _C.frostEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icon, width: 28, height: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _C.navy,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Shared pieces
// -----------------------------------------------------------------------

Matrix4 _perspective({double rx = 0, double ry = 0}) {
  return Matrix4.identity()
    ..setEntry(3, 2, 0.0014)
    ..rotateX(rx)
    ..rotateY(ry);
}

class _PersonPainter extends CustomPainter {
  const _PersonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w / 2, h * 0.3), w * 0.24, paint);
    final body = Path()
      ..addArc(
        Rect.fromLTWH(w * 0.1, h * 0.55, w * 0.8, h * 0.9),
        math.pi,
        math.pi,
      )
      ..close();
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(covariant _PersonPainter oldDelegate) => false;
}

class _PlayPainter extends CustomPainter {
  const _PlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PlayPainter oldDelegate) => false;
}

/// White rounded panel with a soft navy shadow.
class _Panel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    this.radius = 16,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: _C.navy.withValues(alpha: 0.22),
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
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: child,
      ),
    );
  }
}

/// Button with a visible lower edge that sinks when pressed.
class _PressButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final List<Color> faceColors;
  final Color edgeColor;
  final double height;
  final double depth;
  final double radius;
  final Animation<double>? sheen;

  const _PressButton({
    required this.onTap,
    required this.child,
    required this.faceColors,
    required this.edgeColor,
    this.height = 56,
    this.depth = 6,
    this.radius = 16,
    this.sheen,
  });

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
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
                      color: Colors.black.withValues(alpha: 0.3),
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
                    if (widget.sheen != null) _Sheen(animation: widget.sheen!),
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

/// A diagonal light band that sweeps across a button, then rests.
class _Sheen extends StatelessWidget {
  final Animation<double> animation;

  const _Sheen({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final p = ((animation.value - 0.2) / 0.6).clamp(0.0, 1.0);
        return Align(
          alignment: Alignment(-1.8 + 3.6 * p, 0),
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 36,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------
// Backdrop: sky gradient, drifting bubbles, floating tiles
// -----------------------------------------------------------------------

class _Backdrop extends StatelessWidget {
  final double t;

  const _Backdrop({required this.t});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_C.skyTop, _C.skyMid, _C.skyDeep],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.9),
              radius: 0.9,
              colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
            ),
          ),
        ),
        CustomPaint(painter: _BubblePainter(t: t)),
        _drift(const DominoTile(6, 6), const Alignment(-0.95, -0.55), 0.6, -0.4, 0.0),
        _drift(const DominoTile(5, 2), const Alignment(0.95, -0.25), 0.55, 0.35, 0.4),
        _drift(const DominoTile(3, 1), const Alignment(-0.9, 0.7), 0.5, 0.3, 0.7),
        _drift(const DominoTile(4, 4), const Alignment(0.92, 0.75), 0.55, -0.3, 0.2),
      ],
    );
  }

  Widget _drift(
    DominoTile tile,
    Alignment at,
    double scale,
    double angle,
    double phase,
  ) {
    final wave = math.sin((t + phase) * 2 * math.pi);
    return Align(
      alignment: at,
      child: Transform.translate(
        offset: Offset(0, wave * 12),
        child: Transform.rotate(
          angle: angle + wave * 0.05,
          child: Opacity(
            opacity: 0.55,
            child: SpriteDominoTile(tile: tile, scale: scale),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double t;

  const _BubblePainter({required this.t});

  static const _seeds = <List<double>>[
    [0.12, 0.10, 22, 0.15],
    [0.80, 0.08, 16, 0.10],
    [0.45, 0.22, 30, 0.12],
    [0.90, 0.36, 12, 0.18],
    [0.08, 0.42, 26, 0.10],
    [0.62, 0.52, 14, 0.14],
    [0.30, 0.66, 34, 0.09],
    [0.86, 0.72, 20, 0.12],
    [0.18, 0.90, 18, 0.15],
    [0.55, 0.92, 28, 0.10],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < _seeds.length; i++) {
      final s = _seeds[i];
      final drift = (t * (0.4 + (i % 3) * 0.2) + s[1]) % 1.0;
      final center = Offset(
        s[0] * size.width + math.sin((t + i) * math.pi) * 10,
        (1 - drift) * size.height,
      );
      final r = s[2];
      fill.color = Colors.white.withValues(alpha: s[3]);
      ring.color = Colors.white.withValues(alpha: s[3] + 0.12);
      canvas.drawCircle(center, r, fill);
      canvas.drawCircle(center, r, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.t != t;
}
