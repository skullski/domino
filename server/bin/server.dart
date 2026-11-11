import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const int kTargetScore = 100;
const int kPlayersPerRoom = 4;
const int kHandSize = 7;

class Tile {
  final int a;
  final int b;
  const Tile(this.a, this.b);

  bool get isDouble => a == b;
  int get pips => a + b;
  bool matches(int v) => a == v || b == v;
  int other(int v) => a == v ? b : a;

  List<int> toJson() => [a, b];
}

class Placed {
  final Tile tile;
  final String side;
  final int connected;

  Placed(this.tile, this.side, this.connected);

  Map<String, dynamic> toJson() => {
        'a': tile.a,
        'b': tile.b,
        'side': side,
        'conn': connected,
      };
}

class Client {
  final WebSocket socket;
  String name;
  int? seat;
  Room? room;
  bool inQueue = false;

  Client(this.socket, this.name);

  bool get alive => socket.readyState == WebSocket.open;

  void send(Map<String, dynamic> message) {
    if (!alive) return;
    socket.add(jsonEncode(message));
  }

  void sendError(String message) {
    send({'type': 'error', 'message': message});
  }
}

class Room {
  final int id;
  final List<Client> seats;
  final List<List<Tile>> hands = List.generate(4, (_) => <Tile>[]);
  final List<Placed> board = [];
  final List<int> scores = [0, 0];
  int left = -1;
  int right = -1;
  int turn = 0;
  int passes = 0;
  String status = 'playing';
  String? lastMessage;

  Room(this.id, this.seats) {
    for (var i = 0; i < seats.length; i++) {
      seats[i].seat = i;
      seats[i].room = this;
    }
    _deal();
  }

  List<Tile> _set() {
    final tiles = <Tile>[];
    for (var i = 0; i <= 6; i++) {
      for (var j = i; j <= 6; j++) {
        tiles.add(Tile(i, j));
      }
    }
    tiles.shuffle(Random());
    return tiles;
  }

  void _deal() {
    final tiles = _set();
    for (var i = 0; i < 4; i++) {
      hands[i] = tiles.sublist(i * kHandSize, (i + 1) * kHandSize);
    }
    board.clear();
    left = -1;
    right = -1;
    passes = 0;

    // Highest double starts; otherwise seat 0.
    var best = -1;
    turn = 0;
    for (var i = 0; i < 4; i++) {
      for (final tile in hands[i]) {
        if (tile.isDouble && tile.a > best) {
          best = tile.a;
          turn = i;
        }
      }
    }
  }

  bool get boardEmpty => board.isEmpty;

  bool canPlay(Tile tile) {
    if (boardEmpty) return true;
    return tile.matches(left) || tile.matches(right);
  }

  bool handHasMove(int seat) => hands[seat].any(canPlay);

  void _advance() {
    turn = (turn + 1) % 4;
  }

  void play(int seat, Tile tile, String side) {
    if (status != 'playing') throw 'The game is over.';
    if (seat != turn) throw 'It is not your turn.';
    final hand = hands[seat];
    final index = hand.indexWhere((t) => t.a == tile.a && t.b == tile.b);
    if (index < 0) throw 'That tile is not in your hand.';
    if (!canPlay(tile)) throw 'That tile does not fit either end.';
    if (!boardEmpty && side != 'left' && side != 'right') {
      throw 'Choose a side.';
    }

    final connected = boardEmpty
        ? tile.a
        : (side == 'left'
            ? (tile.matches(left) ? left : -1)
            : (tile.matches(right) ? right : -1));
    if (!boardEmpty && connected < 0) {
      throw 'That tile does not fit the ${side} end.';
    }

    hand.removeAt(index);
    board.add(Placed(tile, boardEmpty ? 'right' : side, connected));
    if (boardEmpty) {
      left = tile.a;
      right = tile.b;
    } else if (side == 'left') {
      left = tile.other(connected);
    } else {
      right = tile.other(connected);
    }
    passes = 0;

    if (hand.isEmpty) {
      _endHand(seat);
      return;
    }
    _advance();
  }

  void pass(int seat) {
    if (status != 'playing') throw 'The game is over.';
    if (seat != turn) throw 'It is not your turn.';
    if (handHasMove(seat)) throw 'You still have a playable tile.';
    passes++;
    if (passes >= 4) {
      _blocked();
      return;
    }
    _advance();
  }

  void _endHand(int winnerSeat) {
    final team = winnerSeat % 2;
    var points = 0;
    for (var i = 0; i < 4; i++) {
      if (i % 2 != team) {
        points += hands[i].fold<int>(0, (sum, t) => sum + t.pips);
      }
    }
    _award(team, points, winnerSeat, 'Player ${winnerSeat + 1} finished');
  }

  void _blocked() {
    var bestSeat = 0;
    var bestScore = 1 << 30;
    for (var i = 0; i < 4; i++) {
      final score = hands[i].fold<int>(0, (sum, t) => sum + t.pips);
      if (score < bestScore) {
        bestScore = score;
        bestSeat = i;
      }
    }
    final team = bestSeat % 2;
    var points = 0;
    for (var i = 0; i < 4; i++) {
      if (i % 2 != team) {
        points += hands[i].fold<int>(0, (sum, t) => sum + t.pips);
      }
    }
    _award(team, points, bestSeat, 'Blocked');
  }

  void _award(int team, int points, int starter, String reason) {
    scores[team] += points;
    if (scores[team] >= kTargetScore) {
      status = 'gameover';
      broadcast('gameover', message: 'Team ${team + 1} wins');
      return;
    }
    _deal();
    turn = starter % 4;
    lastMessage = '$reason · +$points';
  }

  void broadcast(String type, {String? message}) {
    final note = message ?? lastMessage;
    lastMessage = null;
    for (final client in seats) {
      if (!client.alive) continue;
      client.send({
        'type': type,
        'room': id,
        'you': client.seat,
        'turn': turn,
        'status': status,
        'scores': scores,
        'left': left,
        'right': right,
        'board': board.map((p) => p.toJson()).toList(),
        'hand': hands[client.seat!].map((t) => t.toJson()).toList(),
        'counts': [for (final h in hands) h.length],
        'players': [
          for (var i = 0; i < seats.length; i++)
            {'name': seats[i].name, 'seat': i, 'team': i % 2},
        ],
        if (note != null) 'message': note,
      });
    }
  }
}

class Server {
  final List<Client> queue = [];
  final List<Room> rooms = [];
  int _nextRoom = 1;

  Future<void> start(int port) async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    stdout.writeln('Domino server listening on port $port');
    await for (final request in server) {
      if (request.uri.path == '/health') {
        request.response
          ..statusCode = 200
          ..write('ok');
        await request.response.close();
        continue;
      }
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _onSocket(socket);
      } else {
        request.response
          ..statusCode = 404
          ..write('Domino server. Connect with a WebSocket.');
        await request.response.close();
      }
    }
  }

  void _onSocket(WebSocket socket) {
    final client = Client(socket, 'Player');
    socket.listen(
      (raw) => _onMessage(client, raw),
      onDone: () => _onDisconnect(client),
      onError: (_) => _onDisconnect(client),
    );
  }

  void _onMessage(Client client, dynamic raw) {
    Map<String, dynamic> message;
    try {
      message = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      client.sendError('Bad message.');
      return;
    }

    try {
      switch (message['type']) {
        case 'join':
          _join(client, message);
          break;
        case 'cancel':
          _leaveQueue(client);
          break;
        case 'play':
          _play(client, message);
          break;
        case 'pass':
          _pass(client);
          break;
        case 'leave':
          _leaveRoom(client);
          break;
        default:
          client.sendError('Unknown message type.');
      }
    } catch (error) {
      client.sendError(error.toString());
    }
  }

  void _join(Client client, Map<String, dynamic> message) {
    if (client.inQueue || client.room != null) return;
    final raw = (message['name'] as String?)?.trim() ?? '';
    client.name = raw.isEmpty ? 'Player' : raw.substring(0, min(raw.length, 16));
    client.inQueue = true;
    queue.add(client);
    _notifyQueue();
    if (queue.length >= kPlayersPerRoom) {
      final group = queue.take(kPlayersPerRoom).toList();
      for (final c in group) {
        c.inQueue = false;
      }
      queue.removeRange(0, kPlayersPerRoom);
      final room = Room(_nextRoom++, group);
      rooms.add(room);
      for (final c in group) {
        c.send({
          'type': 'start',
          'room': room.id,
          'seat': c.seat,
          'players': [
            for (var i = 0; i < group.length; i++)
              {'name': group[i].name, 'seat': i, 'team': i % 2},
          ],
        });
      }
      room.broadcast('state');
      _notifyQueue();
    }
  }

  void _notifyQueue() {
    for (var i = 0; i < queue.length; i++) {
      queue[i].send({
        'type': 'queued',
        'waiting': queue.length,
        'needed': kPlayersPerRoom,
        'position': i + 1,
      });
    }
  }

  void _leaveQueue(Client client) {
    if (!client.inQueue) return;
    client.inQueue = false;
    queue.remove(client);
    _notifyQueue();
  }

  void _play(Client client, Map<String, dynamic> message) {
    final room = client.room;
    if (room == null) throw 'You are not in a game.';
    final rawTile = message['tile'];
    if (rawTile is! List || rawTile.length != 2) throw 'Bad tile.';
    final tile = Tile(rawTile[0] as int, rawTile[1] as int);
    room.play(client.seat!, tile, (message['side'] as String?) ?? 'right');
    room.broadcast('state');
  }

  void _pass(Client client) {
    final room = client.room;
    if (room == null) throw 'You are not in a game.';
    room.pass(client.seat!);
    room.broadcast('state');
  }

  void _leaveRoom(Client client) {
    final room = client.room;
    if (room == null) return;
    client.room = null;
    for (final other in room.seats) {
      if (other == client || !other.alive) continue;
      other.send({
        'type': 'gameover',
        'message': '${client.name} left the game.',
      });
      other.room = null;
    }
    rooms.remove(room);
  }

  void _onDisconnect(Client client) {
    _leaveQueue(client);
    _leaveRoom(client);
  }
}

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ??
      (args.isNotEmpty ? int.tryParse(args[0]) ?? 8080 : 8080);
  await Server().start(port);
}
