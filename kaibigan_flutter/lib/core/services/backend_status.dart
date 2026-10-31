import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/env_config.dart';
import '../utils/language_helper.dart';

/// Why a request to the backend did not succeed.
///
/// The distinction that matters is between "we reached the server and it said
/// no" and "we never reached the server at all". Collapsing the two into one
/// message sends people to check their wifi when the backend is down.
enum BackendFailureKind {
  /// The request completed and the answer was a real answer.
  none,

  /// The host could not be resolved or the socket could not be opened.
  /// A paused Supabase project looks exactly like this: its DNS record is
  /// withdrawn, so the name stops resolving entirely.
  unreachable,

  /// Reached, but nothing came back in time.
  timedOut,

  /// Reached, and it answered with a fault of its own.
  serverError,

  /// The app never had usable credentials to try with.
  notConfigured,
}

/// Names the backend honestly when something goes wrong with it.
abstract final class BackendStatus {
  /// How long to wait before calling the backend unreachable. Long enough
  /// for a slow phone network, short enough that a dead host is not a
  /// twenty-second wait on a login button.
  static const Duration probeTimeout = Duration(seconds: 8);

  /// The host the app is actually configured to talk to, for error messages
  /// that can be acted on rather than guessed at.
  static String get host {
    final parsed = Uri.tryParse(EnvConfig.supabaseUrl);
    final value = parsed?.host ?? '';
    return value.isEmpty ? EnvConfig.supabaseUrl : value;
  }

  /// Sorts an exception into something that can be explained.
  ///
  /// Matching is by type where possible and by message otherwise: the
  /// Supabase and http packages wrap transport errors in their own types,
  /// and those names change between versions.
  static BackendFailureKind classify(Object error) {
    if (error is SocketException) return BackendFailureKind.unreachable;
    if (error is TimeoutException) return BackendFailureKind.timedOut;
    if (error is http.ClientException) return BackendFailureKind.unreachable;

    final name = error.runtimeType.toString().toLowerCase();
    if (name.contains('retryablefetch') || name.contains('clientexception')) {
      return BackendFailureKind.unreachable;
    }

    final text = error.toString().toLowerCase();
    const unreachableSignals = [
      'failed host lookup',
      'no address associated with hostname',
      'nodename nor servname',
      'network is unreachable',
      'connection refused',
      'connection reset',
      'connection closed',
      'connection terminated',
      'software caused connection abort',
      'socketexception',
      'handshakeexception',
    ];
    for (final signal in unreachableSignals) {
      if (text.contains(signal)) return BackendFailureKind.unreachable;
    }
    if (text.contains('timeout') || text.contains('timed out')) {
      return BackendFailureKind.timedOut;
    }
    return BackendFailureKind.serverError;
  }

  /// A message that says what is wrong and who can fix it.
  static String describe(
    BackendFailureKind kind, {
    required String language,
    String? action,
  }) {
    String pick(String english, String filipino) =>
        LanguageHelper.pick(language, english: english, filipino: filipino);
    final what = action ?? pick('do that', 'gawin iyon');

    return switch (kind) {
      BackendFailureKind.none => '',
      BackendFailureKind.unreachable => pick(
          'Could not reach the Kaibigan server ($host). Your entries are '
              'safe and nothing was lost. This is the server being offline or '
              'paused, not your password — check your internet, and if it is '
              'working, the project needs to be resumed.',
          'Hindi maabot ang Kaibigan server ($host). Ligtas ang mga tala mo '
              'at walang nawala. Offline o naka-pause ang server, hindi ito '
              'tungkol sa password mo — suriin ang internet, at kung maayos '
              'iyon, kailangang i-resume ang project.',
        ),
      BackendFailureKind.timedOut => pick(
          'The Kaibigan server ($host) did not answer in time. Nothing was '
              'lost. Try again in a moment.',
          'Hindi sumagot sa oras ang Kaibigan server ($host). Walang nawala. '
              'Subukan muli maya-maya.',
        ),
      BackendFailureKind.serverError => pick(
          'The Kaibigan server had a problem and could not $what. Nothing '
              'was lost. Please try again shortly.',
          'May naganap na problema sa Kaibigan server kaya hindi nito '
              'nagawang $what. Walang nawala. Subukan muli maya-maya.',
        ),
      BackendFailureKind.notConfigured => pick(
          'This build has no server configured, so signing in is not '
              'possible. Check that SUPABASE_URL and SUPABASE_ANON_KEY are '
              'set in .env.',
          'Walang naka-configure na server ang build na ito kaya hindi '
              'posible ang pag-sign in. Tiyaking nakatakda ang SUPABASE_URL '
              'at SUPABASE_ANON_KEY sa .env.',
        ),
    };
  }

  /// Asks the backend whether it is there, without signing anyone in.
  ///
  /// Supabase's client is constructed locally and reports success without
  /// touching the network, so "initialised" says nothing about whether the
  /// project is actually up. This is the cheapest question that does.
  static Future<BackendFailureKind> probe({
    Duration timeout = probeTimeout,
    http.Client? client,
  }) async {
    final url = EnvConfig.supabaseUrl.trim();
    final key = EnvConfig.supabaseAnonKey.trim();
    if (url.isEmpty || key.isEmpty) return BackendFailureKind.notConfigured;

    final endpoint = Uri.tryParse('${url.replaceAll(RegExp(r'/+$'), '')}'
        '/auth/v1/health');
    if (endpoint == null) return BackendFailureKind.notConfigured;

    final owned = client == null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(endpoint, headers: {'apikey': key})
          .timeout(timeout);
      // Any HTTP answer at all proves the host is up. A 401 here means the
      // key is wrong, which is a different screen's problem, not an outage.
      return response.statusCode >= 500
          ? BackendFailureKind.serverError
          : BackendFailureKind.none;
    } catch (error) {
      return classify(error);
    } finally {
      if (owned) httpClient.close();
    }
  }
}
