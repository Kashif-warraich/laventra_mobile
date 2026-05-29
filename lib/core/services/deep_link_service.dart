import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';

/// Listens for incoming deep links from the welcome email and turns them
/// into an automatic login. Wired once from main.dart — handles both
/// cold-start (initialLink) and warm (uriLinkStream) activations.
///
/// Supported URL:
///   laventra://activate?c=<base64url(JSON({e: email, p: password}))>
///
/// The payload carries one-time credentials. After login the server
/// returns `must_change_password: true`, which the router uses to force
/// the user onto /change-password before anything else.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;

  Future<void> init(AuthBloc auth) async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(auth, initial);
    } catch (_) {
      // Plugin may throw on unsupported platforms — ignore.
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(auth, uri),
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _initialized = false;
  }

  void _handle(AuthBloc auth, Uri uri) {
    if (uri.scheme != 'laventra' || uri.host != 'activate') return;

    final creds = _decode(uri.queryParameters['c']);
    if (creds == null) return;

    // Fire login with the one-time credentials. The router redirect picks
    // up must_change_password from the resulting AuthAuthenticated state
    // and pushes /change-password — no extra routing needed here.
    auth.add(AuthLoginRequested(email: creds.email, password: creds.password));
  }

  _Creds? _decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final padded = payload.padRight((payload.length + 3) & ~3, '=');
      final json = utf8.decode(base64Url.decode(padded));
      final map = jsonDecode(json) as Map<String, dynamic>;
      final email = map['e']?.toString();
      final password = map['p']?.toString();
      if (email == null || password == null) return null;
      return _Creds(email, password);
    } catch (_) {
      return null;
    }
  }
}

class _Creds {
  final String email;
  final String password;
  _Creds(this.email, this.password);
}
