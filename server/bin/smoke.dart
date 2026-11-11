import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Connects four fake players, queues them, and plays random legal moves.
/// Usage: dart run bin/smoke.dart [ws://127.0.0.1:8080]
Future<void> main(List<String> args) async {
  final url = args.isNotEmpty ? args[0] : 'ws://127.0.0.1:8080';
  final clients = <_Fake>[];
  var finished = false;

  Future<void> done(String reason) async {
    if (finished) return;
    finished = true;
    stdout.writeln('DONE: $reason');
    for (final c in clients) {
      await c.socket.close();
    }
    exit(0);
  }

  for (var i = 0; i < 4; i++) {
    final socket = await WebSocket.connect(url);
    final fake = _Fake(socket, 'Bot$i', () => done('game over'));
    clients.add(fake);
    socket.listen(fake.onData, onDone: () {}, onError: (_) {});
    socket.add(jsonEncode({'type': 'join', 'name': 'Bot$i'}));
  }

  Timer(const Duration(seconds: 12), () {
    done('timeout — no game over within 12s');
  });
}

class _Fake {
  final WebSocket socket;
  final String name;
  final void Function() onGameOver;
  final Random random = Random();
  int? seat;
  int actions = 0;

  _Fake(this.socket, this.name, this.onGameOver);

  void onData(dynamic raw) {
    final message = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (message['type']) {
      case 'start':
        seat = message['seat'] as int;
        break;
      case 'state':
        _maybeAct(message);
        break;
      case 'gameover':
        onGameOver();
        break;
      case 'error':
        stderr.writeln('$name error: ${message['message']}');
        exit(1);
    }
  }

  void _maybeAct(Map<String, dynamic> state) {
    if (state['status'] != 'playing') return;
    if (state['turn'] != seat) return;
    if (seat == null) return;

    final hand = (state['hand'] as List)
        .map((t) => (t as List).cast<int>())
        .toList();
    final left = state['left'] as int;
    final right = state['right'] as int;
    final empty = state['board'] is List && (state['board'] as List).isEmpty;

    final moves = <List<int>>[];
    for (final tile in hand) {
      if (empty || tile[0] == left || tile[1] == left || tile[0] == right || tile[1] == right) {
        moves.add(tile);
      }
    }

    if (moves.isEmpty) {
      socket.add(jsonEncode({'type': 'pass'}));
      return;
    }

    final tile = moves[random.nextInt(moves.length)];
    String side = 'right';
    if (!empty) {
      final fitsLeft = tile[0] == left || tile[1] == left;
      final fitsRight = tile[0] == right || tile[1] == right;
      if (fitsLeft && !fitsRight) side = 'left';
      if (fitsLeft && fitsRight) side = random.nextBool() ? 'left' : 'right';
    }
    actions++;
    if (actions > 500) {
      stderr.writeln('$name: too many actions');
      exit(1);
    }
    socket.add(jsonEncode({
      'type': 'play',
      'tile': tile,
      'side': side,
    }));
  }
}
