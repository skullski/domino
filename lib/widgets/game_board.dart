import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/domino_tile.dart';
import '../models/game_state.dart';
import 'domino_tile_widget.dart';

// Angle constants (matching the APK's Zo/ta/ia).
const double _angleH = 0.0; // 0°
const double _angleHRev = 180.0; // Zo
const double _angleVDown = 90.0; // ta
const double _angleVUp = -90.0; // ia
const String _sa = 'T';
const String _ea = 'B';

const double _tileW = 130.0;
const double _tileH = 60.0;

/// Is horizontal angle? (matches APK's aa: 0 or 180).
bool _aa(double angle) => angle == _angleH || angle == _angleHRev;

bool _isSentinel(List<String> id) =>
    (int.tryParse(id[0]) ?? 0) < 0 || (int.tryParse(id[1]) ?? 0) < 0;

/// Weighted tile count: doubles 0.5, singles 1.0 (matches APK's ua).
double _ua(List<List<String>> t, int i, [int e = 0]) {
  double h = 0;
  for (int n = e; n < i && n < t.length; n++) {
    h += t[n][0] == t[n][1] ? 0.5 : 1;
  }
  return h;
}

/// Count tiles until weighted sum EXCEEDS threshold (matches APK's ca).
int _ca(List<List<String>> t, int i, double s, [double e = 0]) {
  int h = 0;
  double n = e;
  for (int l = i; l < t.length; l++) {
    n += t[l][0] == t[l][1] ? 0.5 : 1;
    if (n > s) break;
    h += 1;
  }
  return h;
}

/// Count tiles until weighted sum >= threshold + 1 + extra (matches da).
int _da(List<List<String>> t, int i, double s, [double e = 0]) {
  int h = 0;
  double n = 0;
  for (int l = i; l < t.length; l++) {
    n += t[l][0] == t[l][1] ? 0.5 : 1;
    h += 1;
    if (n >= s + 1 + e) break;
  }
  return h;
}

/// Place tiles radiating along X (matches APK's ra).
/// `h` (goingRight) true moves the cursor LEFT (away from center on left side).
void _ra(
  List<List<String>> t,
  String i,
  Offset s,
  double e,
  bool h,
  Size n,
  List<_Pos> ha,
) {
  var l = i;
  var r = e;
  var o = s.dx;
  for (var u = 0; u < t.length; u++) {
    final id = t[u];
    final a = id[0] == l;
    var newAngle = _angleHRev;
    if (id[0] == id[1]) {
      newAngle = h ? _angleVDown : _angleVUp;
    } else {
      String tmp;
      if (r == _angleVDown || r == _angleH) {
        tmp = h ? _ea : _sa;
      } else {
        tmp = h ? _sa : _ea;
      }
      if (tmp + (a ? _ea : _sa) == _ea + _sa ||
          tmp + (a ? _ea : _sa) == _sa + _sa) {
        newAngle = h ? _angleVUp : _angleVDown;
      } else {
        newAngle = h ? _angleVDown : _angleVUp;
      }
    }
    final c =
        (_aa(r) ? n.width : n.height) / 2 +
        (_aa(newAngle) ? n.width : n.height) / 2;
    o = h ? o - c : o + c;
    ha.add(_Pos(id, o, s.dy, newAngle));
    l = a ? id[1] : id[0];
    r = newAngle;
  }
}

/// Place tiles continuing along Y (matches APK's la).
/// `h` (goingDown) true moves the cursor DOWN (+y).
void _la(
  List<List<String>> t,
  String i,
  Offset s,
  double e,
  bool h,
  Size n,
  double l,
  List<_Pos> ha,
) {
  var r = i;
  var o = e;
  var a = s.dy;
  for (var c = 0; c < t.length; c++) {
    final id = t[c];
    final u = id[0] == r;
    var newAngle = _angleHRev;
    if (id[0] == id[1]) {
      newAngle = h ? _angleHRev : _angleH;
    } else {
      String tmp;
      if (o == _angleVDown || o == _angleH) {
        tmp = h ? _sa : _ea;
      } else {
        tmp = h ? _ea : _sa;
      }
      if (tmp + (u ? _sa : _ea) == _ea + _sa ||
          tmp + (u ? _sa : _ea) == _sa + _sa) {
        newAngle = h ? _angleH : _angleHRev;
      } else {
        newAngle = h ? _angleHRev : _angleH;
      }
    }
    final d =
        (_aa(o) ? n.height : n.width) / 2 +
        (_aa(newAngle) ? n.height : n.width) / 2;
    a = h ? a + d : a - d;
    if (_isSentinel(id) && h) a += l;
    ha.add(_Pos(id, s.dx, a, newAngle));
    r = u ? id[1] : id[0];
    o = newAngle;
  }
}

/// A position produced by the layout algorithm (id = [minor, major]).
class _Pos {
  final List<String> id;
  double x;
  double y;
  double angle;

  _Pos(this.id, this.x, this.y, this.angle);
}

/// Faithful port of the APK's `na` function: computes 4-direction snake
/// positions. Chains are [minor, major] id pairs; `left`/`right` must already
/// include their sentinel ("left"/"-1" etc). `container` is the table area,
/// `centerRect` the scaled center-tile size, `clearance` = 12 * scale.
List<_Pos> _na(
  List<String> t,
  List<List<String>> i,
  List<List<String>> s,
  List<List<String>> e,
  List<List<String>> h,
  Size n,
  Size l,
  double r,
) {
  final ha = <_Pos>[_Pos(List.of(t), 0, 0, 0)];

  final a = i.length;
  final u = s.length;
  final c = h.length;
  final d = e.length;

  final pos = {
    'left': Offset.zero,
    'right': Offset.zero,
    'top': Offset.zero,
    'bottom': Offset.zero,
  };
  final f = {'left': 0.0, 'right': 0.0, 'top': 0.0, 'bottom': 0.0};
  final p = {
    'left': <String>['0', '0'],
    'right': <String>['0', '0'],
    'top': <String>['0', '0'],
    'bottom': <String>['0', '0'],
  };
  final v = {
    'left': [a, a, a],
    'right': [u, u, u],
    'top': [c, c, c],
    'bottom': [d, d, d],
  };

  final m = t[0] == t[1] ? 0.5 : 1.0;
  final g = t[0] == t[1] ? 1.0 : 0.5;
  final b = n.width / l.height - 0.5;
  final y = n.height / l.height - 1;
  final w = _ua(i, a) + m / 2;
  final k = _ua(s, u) + m / 2;
  final S = _ua(h, c) + g / 2;
  final x = _ua(e, d) + g / 2;

  var P = S > y / 2 ? 1.0 : 0.0;
  P = k > 1.5 * b ? P + 0.75 : P;
  var T = x > y / 2 ? 1.0 : 0.0;
  T = w > 1.5 * b ? T + 0.75 : T;
  var M = k > b / 2 ? 1.5 : 0.0;
  M = x > 1.5 * y ? M + 0.75 : M;
  var E = w > b / 2 ? 1.5 : 0.0;
  E = S > 1.5 * y ? E + 0.75 : E;

  // First segment counts (left/right).
  if (w > b / 2 - P || k > b / 2 - T) {
    if (w > b / 2 - P && k > b / 2 - T) {
      v['left']![0] = math.max(1, _ca(i, 0, b / 2 - P, m / 2));
      final t2 = b - _ua(i, v['left']![0]) - P;
      v['right']![0] = math.max(1, _ca(s, 0, t2 - T, m / 2));
      final e2 = math.max(0, b - _ua(s, v['right']![0]) - T);
      v['left']![0] = math.max(1, _ca(i, 0, e2 - P, m / 2));
    } else if (w > k) {
      v['left']![0] = math.max(1, _ca(i, 0, b - P - T - k, m / 2));
    } else {
      v['right']![0] = math.max(1, _ca(s, 0, b - P - T - w, m / 2));
    }
  }

  // First segment counts (top/bottom).
  if (S > y / 2 - M || x > y / 2 - E) {
    if (S > y / 2 - M && x > y / 2 - E) {
      v['top']![0] = math.max(1, _ca(h, 0, y / 2 - M, g / 2));
      final t3 = y - _ua(h, v['top']![0]) - M;
      v['bottom']![0] = math.max(1, _ca(e, 0, t3 - E, g / 2));
      final i3 = math.max(0, y - _ua(e, v['bottom']![0]) - E);
      v['top']![0] = math.max(1, _ca(h, 0, i3 - M, g / 2));
    } else if (S > x) {
      v['top']![0] = math.max(1, _ca(h, 0, y - M - E - x, g / 2));
    } else {
      v['bottom']![0] = math.max(1, _ca(e, 0, y - M - E - S, g / 2));
    }
  }

  v['left']![0] = math.min(v['left']![0], a);
  v['right']![0] = math.min(v['right']![0], u);
  v['top']![0] = math.min(v['top']![0], c);
  v['bottom']![0] = math.min(v['bottom']![0], d);

  final N = _ua(i, v['left']![0]);
  final O = _ua(s, v['right']![0]);
  final j = _ua(h, v['top']![0]);
  final C = _ua(e, v['bottom']![0]);
  final D = _da(i, v['left']![0], math.max(1.25, C));
  final A = _da(s, v['right']![0], math.max(1.25, j));
  final R = _da(h, v['top']![0], math.max(1.25, N));
  final I = _da(e, v['bottom']![0], math.max(1.25, O));
  final L = _ca(i, v['left']![0], y / 2, 1);
  final B = _ca(s, v['right']![0], y / 2, 1);
  final z = _ca(h, v['top']![0], b / 2, 1);
  final U = _ca(e, v['bottom']![0], b / 2, 1);

  v['left']![1] = math.min(v['left']![0] + math.max(D, L), a);
  v['right']![1] = math.min(v['right']![0] + math.max(A, B), u);
  v['top']![1] = math.min(v['top']![0] + math.max(R, z), c);
  v['bottom']![1] = math.min(v['bottom']![0] + math.max(I, U), d);

  final G = math.max(j, _ua(s, v['right']![1], v['right']![0]));
  final V = math.max(C, _ua(i, v['left']![1], v['left']![0]));
  final J = math.max(N, _ua(h, v['top']![1], v['top']![0]));
  final H = math.max(O, _ua(e, v['bottom']![1], v['bottom']![0]));

  if (G + V + 1 < y) {
    if (G > V) {
      final t4 = _ca(i, v['left']![0], y - G - 1, 1);
      v['left']![1] = math.max(v['left']![0] + t4, v['left']![1]);
    } else {
      final t4 = _ca(s, v['right']![0], y - V - 1, 1);
      v['right']![1] = math.max(v['right']![0] + t4, v['right']![1]);
    }
  }
  if (J + H + 1 < b) {
    if (J > H) {
      final t5 = _ca(e, v['bottom']![0], b - J - 1, 1);
      v['bottom']![1] = math.max(v['bottom']![0] + t5, v['bottom']![1]);
    } else {
      final t5 = _ca(h, v['top']![0], b - H - 1, 1);
      v['top']![1] = math.max(v['top']![0] + t5, v['top']![1]);
    }
  }

  final q = _ua(i, a, v['left']![1]);
  final W = _ua(s, u, v['right']![1]);
  final Y = _ua(h, c, v['top']![1]);
  final X = _ua(e, d, v['bottom']![1]);
  final K = _ua(i, v['left']![1], v['left']![0]);
  final dollar = _ua(s, v['right']![1], v['right']![0]);
  final Q = _ua(h, v['top']![1], v['top']![0]);
  final Z = _ua(e, v['bottom']![1], v['bottom']![0]);

  // Third segment counts.
  if (q > N + Z + m + 1 && q > N + O + m + 1) {
    final t6 = math.max(N + Z + m + 1, N + O + m + 1);
    v['left']![2] = v['left']![1] + _ca(i, v['left']![1], t6, 0);
  } else if (q >= N + O + m + 1) {
    v['left']![2] = v['left']![1] + _ca(i, v['left']![1], N + O + m + 1, 0);
  } else if (d == 0 && q > b / 2) {
    final t6 = _da(i, v['left']![1], b / 2, 0);
    final s2 = _ua(i, a, v['left']![1] + t6);
    if (_ua(i, v['left']![1], v['left']![0]) > s2) {
      v['left']![2] = v['left']![1] + t6;
    }
  }
  if (W > O + Q + m + 1 && W > N + O + m + 1) {
    final t6 = math.max(O + Q + m + 1, N + O + m + 1);
    v['right']![2] = v['right']![1] + _ca(s, v['right']![1], t6, 0);
  } else if (W >= N + O + m + 1) {
    v['right']![2] = v['right']![1] + _ca(s, v['right']![1], N + O + m + 1, 0);
  } else if (c == 0 && W > b / 2) {
    final t6 = _da(s, v['right']![1], b / 2, 0);
    final i2 = _ua(s, u, v['right']![1] + t6);
    if (_ua(s, v['right']![1], v['right']![0]) > i2) {
      v['right']![2] = v['right']![1] + t6;
    }
  }
  if (Y > C + K + g + 1 && Y > j + C + g + 1) {
    final t6 = math.max(C + K + g + 1, j + C + g + 1);
    v['top']![2] = v['top']![1] + _ca(h, v['top']![1], t6, 0);
  } else if (Y >= j + C + g + 1) {
    v['top']![2] = v['top']![1] + _ca(h, v['top']![1], j + C + g + 1, 0);
  } else if (a == 0 && Y > b / 2) {
    final t6 = _da(h, v['top']![1], y / 2, 0);
    final i2 = _ua(h, c, v['top']![1] + t6);
    if (_ua(h, v['top']![1], v['top']![0]) > i2) {
      v['top']![2] = v['top']![1] + t6;
    }
  }
  if (X > C + dollar + g + 1 && X > j + C + g + 1) {
    final t6 = math.max(C + dollar + g + 1, j + C + g + 1);
    v['bottom']![2] = v['bottom']![1] + _ca(e, v['bottom']![1], t6, 0);
  } else if (X >= j + C + g + 1) {
    v['bottom']![2] =
        v['bottom']![1] + _ca(e, v['bottom']![1], j + C + g + 1, 0);
  } else if (u == 0 && X > b / 2) {
    final t6 = _da(e, v['bottom']![1], y / 2, 0);
    final i2 = _ua(e, d, v['bottom']![1] + t6);
    if (_ua(e, v['bottom']![1], v['bottom']![0]) > i2) {
      v['bottom']![2] = v['bottom']![1] + t6;
    }
  }

  // ---- Phase 1: first segments, radiate X from center. ----
  final tt = i.sublist(0, v['left']![0]);
  final it = s.sublist(0, v['right']![0]);
  for (var F = 0; F < 2; F++) {
    final o = F == 1;
    String fromId;
    final chain = o ? it : tt;
    if (t[0] == t[1]) {
      fromId = t[0];
    } else {
      fromId = o ? t[1] : t[0];
      ha[0].angle = _angleVUp;
    }
    _ra(chain, fromId, Offset.zero, ha[0].angle, !o, l, ha);
    final last = ha[ha.length - 1];
    if (o) {
      f['right'] = last.angle;
      p['right'] = last.id;
      pos['right'] = Offset(
        _aa(f['right']!) ? last.x : last.x + l.height / 4,
        pos['right']!.dy,
      );
    } else {
      f['left'] = last.angle;
      p['left'] = last.id;
      pos['left'] = Offset(
        _aa(f['left']!) ? last.x : last.x - l.height / 4,
        pos['left']!.dy,
      );
    }
  }

  // ---- Phase 2: second segments, continue along Y. ----
  final st = i.sublist(v['left']![0], v['left']![1]);
  final et = s.sublist(v['right']![0], v['right']![1]);
  for (var F = 0; F < 2; F++) {
    final o = F == 1;
    final chain = o ? et : st;
    final fromId = o
        ? (f['right'] == _angleVDown ? p['right']![0] : p['right']![1])
        : (f['left'] == _angleVDown ? p['left']![1] : p['left']![0]);
    final start = o ? pos['right']! : pos['left']!;
    final ang = o ? f['right']! : f['left']!;
    _la(chain, fromId, start, ang, !o, l, r, ha);
    final last = ha[ha.length - 1];
    if (o) {
      f['right'] = last.angle;
      p['right'] = last.id;
      pos['right'] = Offset(
        pos['right']!.dx,
        _aa(f['right']!) ? last.y - l.height / 4 : last.y,
      );
    } else {
      f['left'] = last.angle;
      p['left'] = last.id;
      pos['left'] = Offset(
        pos['left']!.dx,
        _aa(f['left']!) ? last.y + l.height / 4 : last.y,
      );
    }
  }

  // ---- Phase 3: third segments, radiate X again. ----
  final ht = i.sublist(v['left']![1], v['left']![2]);
  final nt = s.sublist(v['right']![1], v['right']![2]);
  for (var F = 0; F < 2; F++) {
    final o = F == 1;
    final chain = o ? nt : ht;
    final fromId = o
        ? (f['right'] == _angleH ? p['right']![0] : p['right']![1])
        : (f['left'] == _angleH ? p['left']![1] : p['left']![0]);
    final start = o ? pos['right']! : pos['left']!;
    final ang = o ? f['right']! : f['left']!;
    _ra(chain, fromId, start, ang, o, l, ha);
    final last = ha[ha.length - 1];
    if (o) {
      f['right'] = last.angle;
      p['right'] = last.id;
      pos['right'] = Offset(
        _aa(f['right']!) ? last.x : last.x - l.height / 4,
        pos['right']!.dy,
      );
    } else {
      f['left'] = last.angle;
      p['left'] = last.id;
      pos['left'] = Offset(
        _aa(f['left']!) ? last.x : last.x + l.height / 4,
        pos['left']!.dy,
      );
    }
  }

  // ---- Phase 4: remaining left/right tiles, continue along Y. ----
  final rt = i.sublist(v['left']![2]);
  final ot = s.sublist(v['right']![2]);
  for (var F = 0; F < 2; F++) {
    final o = F == 1;
    final chain = o ? ot : rt;
    final fromId = o
        ? (f['right'] == _angleVDown ? p['right']![1] : p['right']![0])
        : (f['left'] == _angleVDown ? p['left']![0] : p['left']![1]);
    final start = o ? pos['right']! : pos['left']!;
    final ang = o ? f['right']! : f['left']!;
    _la(chain, fromId, start, ang, o, l, r, ha);
    final last = ha[ha.length - 1];
    if (o) {
      f['right'] = last.angle;
      p['right'] = last.id;
      pos['right'] = Offset(
        pos['right']!.dx,
        _aa(f['right']!) ? last.y + l.height / 4 : last.y,
      );
    } else {
      f['left'] = last.angle;
      p['left'] = last.id;
      pos['left'] = Offset(
        pos['left']!.dx,
        _aa(f['left']!) ? last.y - l.height / 4 : last.y,
      );
    }
  }

  // ---- Vertical chains: top (first), bottom (first). ----
  final at = h.sublist(0, v['top']![0]);
  final ut = e.sublist(0, v['bottom']![0]);
  for (var F = 0; F < 2; F++) {
    final lt = F == 1;
    final chain = lt ? at : ut;
    final fromId = lt ? t[0] : t[1];
    _la(chain, fromId, Offset.zero, ha[0].angle, !lt, l, r, ha);
    final last = ha[ha.length - 1];
    if (lt) {
      f['top'] = last.angle;
      p['top'] = last.id;
      pos['top'] = Offset(
        pos['top']!.dx,
        _aa(f['top']!) ? last.y - l.height / 4 : last.y,
      );
    } else {
      f['bottom'] = last.angle;
      p['bottom'] = last.id;
      pos['bottom'] = Offset(
        pos['bottom']!.dx,
        _aa(f['bottom']!) ? last.y + l.height / 4 : last.y,
      );
    }
  }

  // ---- Vertical chains: top/bottom second segments, radiate X. ----
  final ct = h.sublist(v['top']![0], v['top']![1]);
  final dt = e.sublist(v['bottom']![0], v['bottom']![1]);
  for (var F = 0; F < 2; F++) {
    final lt = F == 1;
    final chain = lt ? ct : dt;
    var ang = lt ? f['top']! : f['bottom']!;
    final sid = lt ? p['top']! : p['bottom']!;
    if (sid[0] == sid[1]) ang = _angleVUp;
    final fromId = (lt ? ang == _angleH : ang == _angleHRev) ? sid[0] : sid[1];
    final start = lt ? pos['top']! : pos['bottom']!;
    _ra(chain, fromId, start, ang, lt, l, ha);
    final last = ha[ha.length - 1];
    if (lt) {
      f['top'] = last.angle;
      p['top'] = last.id;
      pos['top'] = Offset(
        _aa(f['top']!) ? last.x : last.x - l.height / 4,
        last.y,
      );
    } else {
      f['bottom'] = last.angle;
      p['bottom'] = last.id;
      pos['bottom'] = Offset(
        _aa(f['bottom']!) ? last.x : last.x + l.height / 4,
        last.y,
      );
    }
  }

  // ---- Vertical chains: top/bottom third segments, continue Y. ----
  final top3 = h.sublist(v['top']![1], v['top']![2]);
  final ft = e.sublist(v['bottom']![1], v['bottom']![2]);
  for (var F = 0; F < 2; F++) {
    final lt = F == 1;
    final chain = lt ? top3 : ft;
    var ang = lt ? f['top']! : f['bottom']!;
    final sid = lt ? p['top']! : p['bottom']!;
    if (sid[0] == sid[1]) ang = _angleHRev;
    final fromId = (lt ? ang == _angleVDown : ang == _angleVUp)
        ? sid[1]
        : sid[0];
    final start = lt ? pos['top']! : pos['bottom']!;
    _la(chain, fromId, start, lt ? f['top']! : f['bottom']!, lt, l, r, ha);
    final last = ha[ha.length - 1];
    if (lt) {
      f['top'] = last.angle;
      p['top'] = last.id;
      pos['top'] = Offset(
        _aa(f['top']!) ? last.x : last.x - l.height / 4,
        last.y,
      );
    } else {
      f['bottom'] = last.angle;
      p['bottom'] = last.id;
      pos['bottom'] = Offset(
        _aa(f['bottom']!) ? last.x : last.x + l.height / 4,
        last.y,
      );
    }
  }

  return ha;
}

/// Result of building 4-direction chains from the board.
class ChainResult {
  final DominoTile center;
  final List<DominoTile> left;
  final List<DominoTile> right;
  final List<DominoTile> up;
  final List<DominoTile> down;

  ChainResult(this.center, this.left, this.right, this.up, this.down);
}

/// Rebuilds the board into 4-direction chains (left/right/up/down) from center.
/// Tiles are NOT pre-rotated: the layout algorithm computes orientation.
@visibleForTesting
ChainResult buildChain(List<PlacedTile> board) {
  final center = board.first.tile;
  final left = <DominoTile>[];
  final right = <DominoTile>[];
  final up = <DominoTile>[];
  final down = <DominoTile>[];

  for (int i = 1; i < board.length; i++) {
    final tile = board[i].tile;
    switch (board[i].side) {
      case 'left':
        left.add(tile);
        break;
      case 'right':
        right.add(tile);
        break;
      case 'top':
        up.add(tile);
        break;
      case 'bottom':
        down.add(tile);
        break;
    }
  }

  return ChainResult(center, left, right, up, down);
}

List<List<String>> _toIds(List<DominoTile> chain) {
  return [
    for (final t in chain) [t.minor.toString(), t.major.toString()],
  ];
}

DominoTile? _findTile(List<String> id, DominoTile center, ChainResult chain) {
  if (id[0] == center.minor.toString() && id[1] == center.major.toString()) {
    return center;
  }
  for (final tile in [
    ...chain.left,
    ...chain.right,
    ...chain.up,
    ...chain.down,
  ]) {
    if (id[0] == tile.minor.toString() && id[1] == tile.major.toString()) {
      return tile;
    }
  }
  return null;
}

class TilePlacement {
  final DominoTile tile;
  final Offset offset; // tile CENTER
  final bool horizontal;
  final bool isFlipped;
  final double angle;

  TilePlacement(
    this.tile,
    this.offset,
    this.horizontal,
    this.isFlipped,
    this.angle,
  );
}

class SnakeLayout {
  final List<TilePlacement> positions;
  final Rect bounds;
  final double scale;

  SnakeLayout(this.positions, this.bounds, this.scale);
}

Rect _layoutBounds(List<_Pos> positions, double w, double h) {
  if (positions.isEmpty) return Rect.zero;
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final p in positions) {
    final pw = _aa(p.angle) ? w : h;
    final ph = _aa(p.angle) ? h : w;
    minX = math.min(minX, p.x - pw / 2);
    maxX = math.max(maxX, p.x + pw / 2);
    minY = math.min(minY, p.y - ph / 2);
    maxY = math.max(maxY, p.y + ph / 2);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Lays the chain out from the centre: 4 tiles in the middle row, then the
/// left side turns up and the right side turns down. Tiles stay inside the
/// boundary; if the whole thing can't fit, it zooms out.
SnakeLayout computeLayout(
  List<PlacedTile> board, {
  required double maxWidth,
  required double maxHeight,
}) {
  if (board.isEmpty) return SnakeLayout(const [], Rect.zero, 1.0);

  const middleCount = 4;
  final middle = board.take(middleCount).toList();
  final leftMiddle = middle.where((p) => p.side == 'left').length;
  final rightMiddle = middle.where((p) => p.side == 'right').length;

  final left = board.where((p) => p.side == 'left').toList();
  final right = board.where((p) => p.side == 'right').toList();

  double s = 0.75;
  var placements = <TilePlacement>[];
  var bounds = Rect.zero;

  for (var iter = 0; iter < 80; iter++) {
    placements = [];
    final center = board.first.tile;
    final centerHorizontal = !center.isDouble;
    final centerW = (centerHorizontal ? _tileW : _tileH) * s;
    final centerHi = math.max(center.top, center.bottom);
    placements.add(
      TilePlacement(
        center,
        Offset.zero,
        centerHorizontal,
        centerHorizontal ? center.top != centerHi : false,
        centerHorizontal ? 0 : -90,
      ),
    );

    _addSide(placements, left, true, centerW, s, leftMiddle);
    _addSide(placements, right, false, centerW, s, rightMiddle);

    bounds = _placementsBounds(placements, s);
    if (bounds.width <= maxWidth * 0.9 && bounds.height <= maxHeight * 0.9) {
      break;
    }
    s -= 0.02;
    if (s < 0.2) break;
  }

  return SnakeLayout(placements, bounds, s);
}

void _addSide(
  List<TilePlacement> out,
  List<PlacedTile> tiles,
  bool isLeft,
  double centerW,
  double s,
  int middleN,
) {
  if (tiles.isEmpty) return;
  final tileW = _tileW * s;
  final tileH = _tileH * s;
  const gap = 2.0;
  const dirs = [Offset(-1, 0), Offset(0, -1), Offset(1, 0), Offset(0, 1)];

  var lastCenter = const Offset(0, 0);
  var prevDir = isLeft ? 0 : 2;
  var dir = prevDir;
  var segLeft = middleN;
  var prevAlong = centerW;
  var prevPerp = tileH;
  Offset? tileCenter;

  for (var i = 0; i < tiles.length; i++) {
    // Fixed 4 tiles per segment after the middle row, then turn clockwise.
    if (i > 0 && segLeft <= 0) {
      dir = (dir + 1) % 4;
      segLeft = 4;
    }

    final p = tiles[i];
    final tile = p.tile;
    final chainHorizontal = dir == 0 || dir == 2;
    // Doubles stand across the chain.
    final horizontal = tile.isDouble ? !chainHorizontal : chainHorizontal;
    final along = (horizontal == chainHorizontal) ? tileW : tileH;
    final perp = (horizontal == chainHorizontal) ? tileH : tileW;

    if (i == 0) {
      tileCenter = Offset(
        (isLeft ? -1 : 1) * (centerW / 2 + gap + along / 2),
        0,
      );
    } else if (dir == prevDir) {
      tileCenter = lastCenter + dirs[dir] * (prevAlong / 2 + gap + along / 2);
    } else {
      tileCenter =
          lastCenter +
          dirs[prevDir] * (prevAlong / 4) +
          dirs[dir] * (prevPerp / 2 + along / 2 + gap);
    }

    final hi = math.max(tile.top, tile.bottom);
    bool flipped;
    if (horizontal) {
      flipped = lastCenter.dx > tileCenter.dx
          ? p.connectedEnd == hi
          : p.connectedEnd != hi;
    } else {
      flipped = lastCenter.dy > tileCenter.dy
          ? p.connectedEnd != hi
          : p.connectedEnd == hi;
    }

    out.add(TilePlacement(tile, tileCenter, horizontal, flipped, 0));
    lastCenter = tileCenter;
    prevDir = dir;
    prevAlong = along;
    prevPerp = perp;
    // Doubles sit across the chain, so they shouldn't force the segment to end.
    if (!tile.isDouble) segLeft--;
  }
}

Rect _placementsBounds(List<TilePlacement> placements, double s) {
  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = -double.infinity;
  var maxY = -double.infinity;
  for (final p in placements) {
    final w = (p.horizontal ? _tileW : _tileH) * s;
    final h = (p.horizontal ? _tileH : _tileW) * s;
    minX = math.min(minX, p.offset.dx - w / 2);
    maxX = math.max(maxX, p.offset.dx + w / 2);
    minY = math.min(minY, p.offset.dy - h / 2);
    maxY = math.max(maxY, p.offset.dy + h / 2);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

bool _hasOverlap(List<_Pos> positions, double w, double h) {
  final rects = [
    for (final p in positions)
      Rect.fromCenter(
        center: Offset(p.x, p.y),
        width: _aa(p.angle) ? w : h,
        height: _aa(p.angle) ? h : w,
      ),
  ];
  for (var i = 0; i < rects.length; i++) {
    for (var j = i + 1; j < rects.length; j++) {
      final inter = rects[i].intersect(rects[j]);
      if (inter.isEmpty) continue;
      if (inter.width * inter.height > 0.5) return true;
    }
  }
  return false;
}

class GameBoard extends StatelessWidget {
  final List<PlacedTile> board;

  /// Builds the visual for a placed tile. When omitted the code-drawn
  /// [DominoTileWidget] is used.
  final Widget Function(
    DominoTile tile, {
    required bool horizontal,
    required bool isFlipped,
    required double scale,
  })?
  tileBuilder;

  const GameBoard({super.key, required this.board, this.tileBuilder});

  @override
  Widget build(BuildContext context) {
    if (board.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.casino_rounded,
              color: Colors.white.withValues(alpha: 0.15),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Place the first tile',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = computeLayout(
          board,
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
        );
        final bounds = layout.bounds;
        final scale = layout.scale;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // DEBUG: boundary guide — remove once the snake is approved.
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFF5252),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: bounds.width,
                height: bounds.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final pos in layout.positions)
                      Positioned(
                        key: ValueKey('${pos.tile.top}-${pos.tile.bottom}'),
                        left:
                            pos.offset.dx -
                            bounds.left -
                            (pos.horizontal ? _tileW : _tileH) * scale / 2,
                        top:
                            pos.offset.dy -
                            bounds.top -
                            (pos.horizontal ? _tileH : _tileW) * scale / 2,
                        child:
                            tileBuilder?.call(
                              pos.tile,
                              horizontal: pos.horizontal,
                              isFlipped: pos.isFlipped,
                              scale: scale,
                            ) ??
                            DominoTileWidget(
                              tile: pos.tile,
                              horizontal: pos.horizontal,
                              isFlipped: pos.isFlipped,
                              scale: scale,
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
