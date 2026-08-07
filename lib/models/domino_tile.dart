class DominoTile {
  final int top;
  final int bottom;

  const DominoTile(this.top, this.bottom);

  bool get isDouble => top == bottom;

  int get minor => top < bottom ? top : bottom;

  int get major => top > bottom ? top : bottom;

  int get score => top + bottom;

  bool matches(int value) => top == value || bottom == value;

  int getOtherEnd(int value) {
    if (top == value) return bottom;
    if (bottom == value) return top;
    return -1;
  }

  DominoTile rotated() => DominoTile(bottom, top);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DominoTile && top == other.top && bottom == other.bottom;

  @override
  int get hashCode => top.hashCode ^ bottom.hashCode;

  @override
  String toString() => '$top-$bottom';
}
