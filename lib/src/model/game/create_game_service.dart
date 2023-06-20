import 'dart:async';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:deep_pick/deep_pick.dart';

import 'package:lichess_mobile/src/http_client.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/common/socket.dart';
import 'package:lichess_mobile/src/model/lobby/lobby_repository.dart';
import 'package:lichess_mobile/src/model/lobby/game_seek.dart';
import 'package:lichess_mobile/src/model/auth/auth_socket.dart';
import 'package:lichess_mobile/src/model/settings/play_preferences.dart';

part 'create_game_service.g.dart';

@Riverpod(keepAlive: true)
CreateGameService createGameService(CreateGameServiceRef ref) {
  return CreateGameService(Logger('CreateGameService'), ref: ref);
}

class CreateGameService {
  CreateGameService(this._log, {required this.ref});

  final CreateGameServiceRef ref;
  final Logger _log;

  StreamSubscription<dynamic>? _socketSubscription;

  Future<GameFullId> newOnlineGame() async {
    if (_socketSubscription != null) {
      throw Exception('Already creating a game');
    }

    final socket = ref.read(authSocketProvider);
    final playPref = ref.read(playPreferencesProvider);
    final lobbyRepo = ref.read(lobbyRepositoryProvider);

    final completer = Completer<GameFullId>();

    final stream = socket.connect();

    _socketSubscription = stream.listen((event) {
      if (event.type == SocketEventType.redirect) {
        final data = event.data as Map<String, dynamic>;
        final gameId = pick(data['id']).asGameFullIdOrThrow();
        completer.complete(gameId);
      }
    });

    socket.switchRoute(Uri(path: '/lobby/socket/v5'));

    _log.info('Creating new online game');

    await Result.release(
      lobbyRepo.createSeek(
        GameSeek(
          time: Duration(seconds: playPref.timeIncrement.time),
          increment: Duration(seconds: playPref.timeIncrement.increment),
          // TODO add rated choice
          rated: true,
        ),
        sri: socket.sri!,
      ),
    );

    return completer.future;
  }

  void dispose() {
    // close client connection to cancel seek
    // cf: https://lichess.org/api#tag/Board/operation/apiBoardSeek
    ref.invalidate(httpClientProvider);
    _socketSubscription?.cancel();
    _socketSubscription = null;
  }
}
