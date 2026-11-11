import 'package:flutter/material.dart';
import '../models/domino_tile.dart';
import 'domino_tile_widget.dart';

/// The player's hand rendered as a vertical (portrait) rack of tiles,
/// matching the open-source hendersonh "Vertical Rack" layout.
class PlayerHandWidget extends StatelessWidget {
  final List<DominoTile> hand;
  final List<DominoTile> playableTiles;
  final DominoTile? selectedTile;
  final Function(DominoTile) onTileTap;
  final bool isCurrentPlayer;

  const PlayerHandWidget({
    super.key,
    required this.hand,
    required this.playableTiles,
    this.selectedTile,
    required this.onTileTap,
    this.isCurrentPlayer = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      itemCount: hand.length,
      itemBuilder: (context, index) {
        final tile = hand[index];
        final isPlayable = isCurrentPlayer && playableTiles.contains(tile);
        final isSelected = selectedTile == tile;

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: DominoTileWidget(
            tile: tile,
            isSelected: isSelected,
            isPlayable: isPlayable,
            horizontal: false,
            isFlipped: false,
            scale: 0.85,
            onTap: isPlayable ? () => onTileTap(tile) : null,
          ),
        );
      },
    );
  }
}
