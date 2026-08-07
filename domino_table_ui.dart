import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const DominoGameApp());
}

/// Root Application Widget
class DominoGameApp extends StatelessWidget {
  const DominoGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domino Pro Table',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFF2ECC71),
          surface: Color(0xFF1E2D24),
        ),
      ),
      home: const DominoGameScreen(),
    );
  }
}

// ============================================================================
// ASSET PATHS (extracted from the Dominoes Battle APK sprite atlases)
// ============================================================================

class AppAssets {
  AppAssets._();

  static const String header = 'assets/ui/match_header_bg.png';
  static const String bench = 'assets/ui/match_tiles_bench.png';
  static const String feltPattern = 'assets/ui/table_felt_pattern.png';
  static const String tileSlot = 'assets/ui/match_tile_area_1_normal.png';
  static const String tileSlotSelected = 'assets/ui/match_tile_area_1_selected.png';
  static const String timerBg = 'assets/ui/match_timer_bar_bg.png';
  static const String timerFill = 'assets/ui/match_timer_bar_fill.png';
  static const String trophy = 'assets/ui/match_match_trophy.png';
  static const String trophyLeague = 'assets/ui/match_match_league_header_banner.png';
  static const String barBlue = 'assets/ui/bar_bar_progress_blue.png';
  static const String barRed = 'assets/ui/bar_bar_progress_red.png';
  static const String barBase = 'assets/ui/bar_bar_progress_base.png';

  static const String btnMenu = 'assets/ui/button_btn_square_blue_normal.png';
  static const String btnSquare = 'assets/ui/button_btn_square_gray_normal.png';
  static const String btnGreen = 'assets/ui/button_btn_square_green_normal.png';
  static const String bkgRounded = 'assets/ui/background_bkg_rounded.png';
  static const String bkgSeparator = 'assets/ui/background_bkg_separator.png';

  static const String icoSettings = 'assets/ui/icon_ico_settings.png';
  static const String icoOptions = 'assets/ui/icon_ico_options.png';
  static const String icoQuit = 'assets/ui/icon_ico_quit_white.png';
  static const String icoChat = 'assets/ui/icon_ico_chatmessage.png';
  static const String icoChatMuted = 'assets/ui/icon_ico_chatmessage_muted.png';
  static const String icoHelp = 'assets/ui/icon_ico_help.png';
  static const String icoStats = 'assets/ui/icon_ico_stats.png';
  static const String icoSkip = 'assets/ui/icon_ico_skip.png';
  static const String icoCoin = 'assets/ui/icon_ico_coin.png';
  static const String icoModeFast = 'assets/ui/icon_ico_mode_fast.png';
  static const String icoModeBlock = 'assets/ui/icon_ico_mode_block.png';

  static const String tileBack = 'assets/tiles/t1back.png';
  static const String tileShadow = 'assets/tiles/t1shadow.png';

  static String tileFace(int p1, int p2) {
    final a = math.max(p1, p2);
    final b = math.min(p1, p2);
    return 'assets/tiles/t1d$a$b.png';
  }
}

// ============================================================================
// MODELS
// ============================================================================

/// Represents a individual domino tile with top and bottom pips.
class DominoTileModel {
  final String id;
  final int pip1;
  final int pip2;
  bool isSelected;
  bool isPlayable;

  DominoTileModel({
    required this.id,
    required this.pip1,
    required this.pip2,
    this.isSelected = false,
    this.isPlayable = false,
  });

  bool get isDouble => pip1 == pip2;
  int get totalPips => pip1 + pip2;
}

/// Represents a played tile positioned on the board chain.
class PlayedDomino {
  final DominoTileModel tile;
  final bool isHorizontal;
  final bool isFlipped; // Swap pip1 and pip2 visually for chain matching
  final Offset positionOffset;

  PlayedDomino({
    required this.tile,
    this.isHorizontal = true,
    this.isFlipped = false,
    this.positionOffset = Offset.zero,
  });
}

/// Represents a player in the match.
class PlayerModel {
  final String id;
  final String name;
  final String avatarUrl;
  final int tileCount;
  final int score;
  final bool isHuman;
  final int team; // 1 or 2

  PlayerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.tileCount,
    required this.score,
    this.isHuman = false,
    required this.team,
  });

  PlayerModel copyWith({int? tileCount, int? score}) {
    return PlayerModel(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      tileCount: tileCount ?? this.tileCount,
      score: score ?? this.score,
      isHuman: isHuman,
      team: team,
    );
  }
}

// ============================================================================
// NINE-SLICE SPRITE HELPER
// ============================================================================

/// Renders a 9-patch PNG at an arbitrary size using [centerSlice].
///
/// [sourceWidth]/[sourceHeight] are the pixel size of the source PNG so the
/// stretchable center region can be computed from [margins]. When margins are
/// zero (or degenerate) the image is simply stretched with [BoxFit.fill].
class NineSliceImage extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final EdgeInsets margins;
  final double? sourceWidth;
  final double? sourceHeight;

  const NineSliceImage({
    Key? key,
    required this.asset,
    required this.width,
    required this.height,
    this.margins = EdgeInsets.zero,
    this.sourceWidth,
    this.sourceHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Rect? centerSlice;
    if (margins != EdgeInsets.zero && sourceWidth != null && sourceHeight != null) {
      final cw = sourceWidth! - margins.left - margins.right;
      final ch = sourceHeight! - margins.top - margins.bottom;
      if (cw > 1 && ch > 1) {
        centerSlice = Rect.fromLTRB(
          margins.left,
          margins.top,
          sourceWidth! - margins.right,
          sourceHeight! - margins.bottom,
        );
      }
    }
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.fill,
      centerSlice: centerSlice,
    );
  }
}

// ============================================================================
// DOMINO TILE SPRITE (real PNG face + shadow)
// ============================================================================

class DominoTileSprite extends StatelessWidget {
  final DominoTileModel tile;
  final double width;
  final double height;
  final bool faceDown;
  final bool isSelected;
  final bool isPlayable;
  final VoidCallback? onTap;

  const DominoTileSprite({
    Key? key,
    required this.tile,
    this.width = 54,
    this.height = 117,
    this.faceDown = false,
    this.isSelected = false,
    this.isPlayable = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The atlas face is canonical (max pip on top). Rotate 180° so pip1 is up.
    final needFlip = !faceDown && tile.pip1 != math.max(tile.pip1, tile.pip2);
    final asset = faceDown ? AppAssets.tileBack : AppAssets.tileFace(tile.pip1, tile.pip2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, isSelected ? -16 : 0, 0),
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 3,
              top: 4,
              child: Image.asset(
                AppAssets.tileShadow,
                width: width,
                height: height,
                fit: BoxFit.fill,
                opacity: const AlwaysStoppedAnimation(0.5),
              ),
            ),
            if (isSelected || isPlayable)
              Positioned.fill(
                child: Image.asset(
                  AppAssets.tileSlotSelected,
                  fit: BoxFit.fill,
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF90EE90),
                  colorBlendMode: BlendMode.modulate,
                ),
              ),
            Transform.rotate(
              angle: needFlip ? math.pi : 0,
              child: Image.asset(
                asset,
                width: width,
                height: height,
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small face-down fan used for opponent seats.
class OpponentTilesFan extends StatelessWidget {
  final int count;
  final Axis direction; // horizontal for top seat, vertical for sides

  const OpponentTilesFan({
    Key? key,
    required this.count,
    this.direction = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final shown = math.min(count, 7);
    final tileW = direction == Axis.horizontal ? 24.0 : 22.0;
    final tileH = direction == Axis.horizontal ? 52.0 : 36.0;
    final overlap = direction == Axis.horizontal ? 12.0 : 10.0;
    final totalLen = shown * tileW - (shown - 1) * overlap;

    final tiles = <Widget>[];
    for (int i = 0; i < shown; i++) {
      tiles.add(
        Positioned(
          left: direction == Axis.horizontal ? i * (tileW - overlap) : 0,
          top: direction == Axis.horizontal ? 0 : i * (tileH - overlap),
          child: Image.asset(
            AppAssets.tileBack,
            width: tileW,
            height: tileH,
            fit: BoxFit.fill,
          ),
        ),
      );
    }

    return SizedBox(
      width: direction == Axis.horizontal ? totalLen : tileW,
      height: direction == Axis.horizontal ? tileH : totalLen,
      child: Stack(children: tiles),
    );
  }
}

// ============================================================================
// FELT TABLE BACKGROUND (tiled pattern from the app)
// ============================================================================

class FeltBackground extends StatelessWidget {
  const FeltBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.92,
          colors: [
            Color(0xFF1A4D2E),
            Color(0xFF0F3520),
            Color(0xFF0A2518),
          ],
          stops: [0.0, 0.65, 1.0],
        ),
      ),
    );
  }
}

// ============================================================================
// SCORE / HEADER BAR (real app header art)
// ============================================================================

class ScoreHeaderWidget extends StatelessWidget {
  final int team1Score;
  final int team2Score;
  final int targetScore;
  final VoidCallback? onSettingsPressed;

  const ScoreHeaderWidget({
    Key? key,
    required this.team1Score,
    required this.team2Score,
    required this.targetScore,
    this.onSettingsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 563,
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: NineSliceImage(
              asset: AppAssets.header,
              width: 563,
              height: 200,
              margins: const EdgeInsets.all(25),
              sourceWidth: 125,
              sourceHeight: 125,
            ),
          ),

          // Game mode icon (Fast)
          Positioned(
            left: 30,
            top: 26,
            child: Image.asset(AppAssets.icoModeFast, width: 46, height: 40),
          ),

          // Chat + mute buttons (top right)
          Positioned(
            right: 96,
            top: 16,
            child: _squareButton(AppAssets.icoChat, () {}),
          ),
          Positioned(
            right: 30,
            top: 16,
            child: _squareButton(AppAssets.icoChatMuted, () {}),
          ),

          // Trophy + target score banner (center, overlapping top edge)
          Positioned(
            left: 0,
            right: 0,
            top: -26,
            child: Center(
              child: SizedBox(
                width: 128,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(child: Image.asset(AppAssets.trophy, fit: BoxFit.fill)),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 30,
                      child: Text(
                        '$targetScore',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Team 1 score bar (left of center)
          Positioned(
            left: 84,
            top: 96,
            child: _teamBar('TEAM 1', team1Score, AppAssets.barBlue, const Color(0xFF64B5F6)),
          ),

          // Team 2 score bar (right of center)
          Positioned(
            right: 84,
            top: 96,
            child: _teamBar('TEAM 2', team2Score, AppAssets.barRed, const Color(0xFFEF9A9A)),
          ),

          // Coins (bottom left)
          Positioned(
            left: 22,
            bottom: 14,
            child: Row(
              children: [
                Image.asset(AppAssets.icoCoin, width: 30, height: 31),
                const SizedBox(width: 5),
                Text(
                  '${team1Score + team2Score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                  ),
                ),
              ],
            ),
          ),

          // Menu button (bottom right)
          Positioned(
            right: 16,
            bottom: 12,
            child: GestureDetector(
              onTap: onSettingsPressed,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(AppAssets.btnMenu, fit: BoxFit.fill),
                    ),
                    Image.asset(AppAssets.icoOptions, width: 26, height: 26),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _squareButton(String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: NineSliceImage(
                asset: AppAssets.btnSquare,
                width: 54,
                height: 54,
                margins: const EdgeInsets.all(24),
                sourceWidth: 77,
                sourceHeight: 72,
              ),
            ),
            Image.asset(icon, width: 26, height: 26),
          ],
        ),
      ),
    );
  }

  Widget _teamBar(String label, int score, String fillAsset, Color accent) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 150,
              height: 18,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(AppAssets.barBase, fit: BoxFit.fill),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (score.clamp(0, 100)) / 100.0,
                    child: Image.asset(fillAsset, fit: BoxFit.fill),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// OPPONENT SEAT (avatar + name + tile count + turn timer bar)
// ============================================================================

class OpponentSeat extends StatelessWidget {
  final PlayerModel player;
  final bool isCurrentTurn;
  final double turnProgress;
  final Axis direction;

  const OpponentSeat({
    Key? key,
    required this.player,
    required this.isCurrentTurn,
    required this.turnProgress,
    this.direction = Axis.horizontal,
  }) : super(key: key);

  static const _teamColors = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _teamColors[player.team];

    final avatar = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.6)],
        ),
        border: Border.all(
          color: isCurrentTurn ? const Color(0xFFFFD54F) : Colors.white24,
          width: 2,
        ),
        boxShadow: [
          if (isCurrentTurn)
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Center(
        child: Text(
          player.name.isEmpty ? '?' : player.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    final nameplate = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTurn ? const Color(0xFFFFD54F) : Colors.white12,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Text(
              '${player.tileCount}',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    final timer = SizedBox(
      width: direction == Axis.horizontal ? 110 : 8,
      height: direction == Axis.horizontal ? 8 : 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.timerBg,
              fit: BoxFit.fill,
              color: isCurrentTurn ? Colors.white70 : Colors.white24,
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          FractionallySizedBox(
            alignment: direction == Axis.horizontal
                ? Alignment.centerLeft
                : Alignment.bottomCenter,
            widthFactor: direction == Axis.horizontal ? turnProgress : 1,
            heightFactor: direction == Axis.horizontal ? 1 : turnProgress,
            child: Image.asset(
              AppAssets.timerFill,
              fit: BoxFit.fill,
              color: turnProgress < 0.25
                  ? const Color(0xFFE65100)
                  : const Color(0xFFFFC107),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
        ],
      ),
    );

    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [avatar, const SizedBox(height: 5), nameplate, const SizedBox(height: 5), timer],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [avatar, const SizedBox(height: 5), nameplate, const SizedBox(height: 5), timer],
    );
  }
}

// ============================================================================
// BOARD TABLE (center chain on the felt)
// ============================================================================

class DominoBoardView extends StatelessWidget {
  final List<PlayedDomino> chain;
  final Function(bool isLeftEnd)? onPlayOnEndTap;

  const DominoBoardView({
    Key? key,
    required this.chain,
    this.onPlayOnEndTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (chain.isEmpty) {
      return const Center(
        child: Text(
          'Play a tile to open the chain',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 500,
        height: 380,
        child: Stack(
          children: [
            for (int i = 0; i < chain.length; i++)
              _buildChainTile(chain[i], i, chain.length),
          ],
        ),
      ),
    );
  }

  Widget _buildChainTile(PlayedDomino item, int index, int total) {
    const centerX = 250.0;
    const centerY = 190.0;

    double xOffset = (index - (total / 2)) * 38.0;
    double yOffset = 0.0;

    if (xOffset > 160) {
      yOffset = 50.0;
      xOffset = 160 - (xOffset - 160);
    } else if (xOffset < -160) {
      yOffset = -50.0;
      xOffset = -160 - (xOffset + 160);
    }

    return Positioned(
      left: centerX + xOffset - 24,
      top: centerY + yOffset - 52,
      child: Transform.rotate(
        angle: item.isHorizontal ? math.pi / 2 : 0,
        child: DominoTileSprite(
          tile: item.tile,
          width: 48,
          height: 104,
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM BENCH (real wooden tray + hand tiles + actions)
// ============================================================================

class PlayerTrayWidget extends StatelessWidget {
  final List<DominoTileModel> handTiles;
  final Function(DominoTileModel) onTileTap;
  final VoidCallback onPassTap;
  final VoidCallback onSortTap;
  final bool isMyTurn;

  const PlayerTrayWidget({
    Key? key,
    required this.handTiles,
    required this.onTileTap,
    required this.onPassTap,
    required this.onSortTap,
    required this.isMyTurn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 574,
      height: 210,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: NineSliceImage(
              asset: AppAssets.bench,
              width: 574,
              height: 210,
              margins: const EdgeInsets.only(left: 100, top: 30, right: 0, bottom: 30),
              sourceWidth: 295,
              sourceHeight: 183,
            ),
          ),

          // Hand tiles row (standing upright)
          Positioned(
            left: 70,
            right: 70,
            top: -14,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: handTiles.map((tile) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: DominoTileSprite(
                        tile: tile,
                        width: 50,
                        height: 108,
                        isSelected: tile.isSelected,
                        isPlayable: tile.isPlayable,
                        onTap: () => onTileTap(tile),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Sort button (left)
          Positioned(
            left: 10,
            top: 52,
            child: _roundButton(AppAssets.icoSkip, onSortTap),
          ),

          // Pass button (right)
          Positioned(
            right: 10,
            top: 44,
            child: GestureDetector(
              onTap: isMyTurn ? onPassTap : null,
              child: SizedBox(
                width: 96,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        AppAssets.btnGreen,
                        fit: BoxFit.fill,
                        opacity: isMyTurn ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.4),
                      ),
                    ),
                    const Text(
                      'PASS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(String icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Center(child: Image.asset(icon, width: 22, height: 22)),
      ),
    );
  }
}

// ============================================================================
// MAIN GAME SCREEN & STATE MANAGEMENT
// ============================================================================

/// Fits the 563x935 design into any screen while keeping the aspect ratio.
class DesignSpace extends StatelessWidget {
  final Widget child;

  const DesignSpace({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          constraints.maxWidth / 563,
          constraints.maxHeight / 935,
        );
        return Center(
          child: SizedBox(
            width: 563 * scale,
            height: 935 * scale,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(width: 563, height: 935, child: child),
            ),
          ),
        );
      },
    );
  }
}

class DominoGameScreen extends StatefulWidget {
  const DominoGameScreen({Key? key}) : super(key: key);

  @override
  State<DominoGameScreen> createState() => _DominoGameScreenState();
}

class _DominoGameScreenState extends State<DominoGameScreen>
    with SingleTickerProviderStateMixin {
  // Turn Countdown Timer
  late AnimationController _timerController;
  Timer? _botTurnTimer;

  // Game Data State
  int activePlayerIndex = 0; // 0: Human, 1: Bot 1, 2: Bot 2, 3: Bot 3
  int team1Score = 45;
  int team2Score = 30;
  final int targetScore = 100;

  List<PlayerModel> players = [];
  List<DominoTileModel> myHand = [];
  List<PlayedDomino> boardChain = [];

  @override
  void initState() {
    super.initState();

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleTurnTimeout();
        }
      });

    _initializeGame();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _botTurnTimer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    players = [
      PlayerModel(id: 'p0', name: 'You', avatarUrl: '', tileCount: 6, score: 45, isHuman: true, team: 1),
      PlayerModel(id: 'p1', name: 'Bot 1', avatarUrl: '', tileCount: 5, score: 30, isHuman: false, team: 2),
      PlayerModel(id: 'p2', name: 'Bot 2', avatarUrl: '', tileCount: 5, score: 45, isHuman: false, team: 1),
      PlayerModel(id: 'p3', name: 'Bot 3', avatarUrl: '', tileCount: 5, score: 30, isHuman: false, team: 2),
    ];

    myHand = [
      DominoTileModel(id: 't1', pip1: 6, pip2: 6, isPlayable: true),
      DominoTileModel(id: 't2', pip1: 5, pip2: 2, isPlayable: false),
      DominoTileModel(id: 't3', pip1: 4, pip2: 3, isPlayable: true),
      DominoTileModel(id: 't4', pip1: 0, pip2: 0, isPlayable: false),
      DominoTileModel(id: 't5', pip1: 5, pip2: 5, isPlayable: true),
      DominoTileModel(id: 't6', pip1: 6, pip2: 3, isPlayable: false),
    ];

    boardChain = [
      PlayedDomino(tile: DominoTileModel(id: 'b1', pip1: 4, pip2: 4)),
      PlayedDomino(tile: DominoTileModel(id: 'b2', pip1: 4, pip2: 2)),
      PlayedDomino(tile: DominoTileModel(id: 'b3', pip1: 2, pip2: 5)),
      PlayedDomino(tile: DominoTileModel(id: 'b4', pip1: 5, pip2: 6)),
      PlayedDomino(tile: DominoTileModel(id: 'b5', pip1: 6, pip2: 3)),
    ];

    _startTurnTimer();
  }

  void _startTurnTimer() {
    _timerController.reset();
    _timerController.forward();

    if (!players[activePlayerIndex].isHuman) {
      _botTurnTimer?.cancel();
      _botTurnTimer = Timer(const Duration(seconds: 2), () {
        _advanceTurn();
      });
    }
  }

  void _advanceTurn() {
    setState(() {
      if (!players[activePlayerIndex].isHuman) {
        final currentCount = players[activePlayerIndex].tileCount;
        if (currentCount > 0) {
          players[activePlayerIndex] =
              players[activePlayerIndex].copyWith(tileCount: currentCount - 1);
        }
      }
      activePlayerIndex = (activePlayerIndex + 1) % 4;
    });
    _startTurnTimer();
  }

  void _handleTurnTimeout() {
    _advanceTurn();
  }

  void _handleTileTap(DominoTileModel selectedTile) {
    if (activePlayerIndex != 0) return;

    setState(() {
      for (var tile in myHand) {
        if (tile.id == selectedTile.id) {
          tile.isSelected = !tile.isSelected;
        } else {
          tile.isSelected = false;
        }
      }
    });
  }

  void _playSelectedTileOnBoard(bool isLeftEnd) {
    final selectedIndex = myHand.indexWhere((t) => t.isSelected);
    if (selectedIndex == -1) return;

    final playedTile = myHand.removeAt(selectedIndex);

    setState(() {
      if (isLeftEnd) {
        boardChain.insert(0, PlayedDomino(tile: playedTile));
      } else {
        boardChain.add(PlayedDomino(tile: playedTile));
      }
      players[0] = players[0].copyWith(tileCount: myHand.length);
    });

    _advanceTurn();
  }

  void _sortHand() {
    setState(() {
      myHand.sort((a, b) => b.totalPips.compareTo(a.totalPips));
    });
  }

  void _openSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2D24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Game Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.volume_up, color: Color(0xFFFFD700)),
                title: const Text('Sound Effects'),
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
              ListTile(
                leading: const Icon(Icons.style, color: Color(0xFFFFD700)),
                title: const Text('Auto-Sort Hand'),
                trailing: Switch(value: false, onChanged: (v) {}),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Resume Match', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DesignSpace(
          child: Stack(
            children: [
              // 1. Felt table background (full 563x935)
              const Positioned.fill(child: FeltBackground()),

              // 2. Header / score board at the top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ScoreHeaderWidget(
                  team1Score: team1Score,
                  team2Score: team2Score,
                  targetScore: targetScore,
                  onSettingsPressed: _openSettingsDialog,
                ),
              ),

              // 3. Top partner seat (players[2], team 1)
              Positioned(
                top: 214,
                left: 0,
                right: 0,
                child: Center(
                  child: OpponentSeat(
                    player: players[2],
                    isCurrentTurn: activePlayerIndex == 2,
                    turnProgress: 1.0 - _timerController.value,
                  ),
                ),
              ),

              // 4. Left opponent seat (players[1], team 2)
              Positioned(
                left: 12,
                top: 420,
                child: OpponentSeat(
                  player: players[1],
                  isCurrentTurn: activePlayerIndex == 1,
                  turnProgress: 1.0 - _timerController.value,
                  direction: Axis.vertical,
                ),
              ),

              // 5. Right opponent seat (players[3], team 2)
              Positioned(
                right: 12,
                top: 420,
                child: OpponentSeat(
                  player: players[3],
                  isCurrentTurn: activePlayerIndex == 3,
                  turnProgress: 1.0 - _timerController.value,
                  direction: Axis.vertical,
                ),
              ),

              // 6. Center board chain
              Positioned(
                left: 30,
                right: 30,
                top: 300,
                bottom: 240,
                child: DominoBoardView(
                  chain: boardChain,
                  onPlayOnEndTap: _playSelectedTileOnBoard,
                ),
              ),

              // 7. Bottom bench + hand tray
              Positioned(
                left: 0,
                right: 0,
                bottom: -6,
                child: Center(
                  child: PlayerTrayWidget(
                    handTiles: myHand,
                    isMyTurn: activePlayerIndex == 0,
                    onTileTap: _handleTileTap,
                    onPassTap: _advanceTurn,
                    onSortTap: _sortHand,
                  ),
                ),
              ),

              // 8. Turn status pill
              Positioned(
                left: 0,
                right: 0,
                top: 288,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      activePlayerIndex == 0
                          ? 'YOUR TURN'
                          : '${players[activePlayerIndex].name} is thinking...',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
