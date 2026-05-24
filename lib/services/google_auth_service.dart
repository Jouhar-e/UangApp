import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:uangapp/core/constants/app_constants.dart';
import 'package:uangapp/services/auth_session_store.dart';

/// OAuth untuk Google Sheets & Drive saja — **bukan** untuk Groq AI.
class GoogleAuthService {
  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    AuthSessionStore? sessionStore,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _sessionStore = sessionStore ?? AuthSessionStore() {
    _initialization = _init();
  }

  final GoogleSignIn _googleSignIn;
  final AuthSessionStore _sessionStore;
  late final Future<void> _initialization;

  GoogleSignInAccount? _currentAccount;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authEventsSub;
  auth.AuthClient? _cachedAuthClient;
  String? _cachedAuthClientEmail;
  Future<void>? _warmUpFuture;

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<String?> get cachedEmail => _sessionStore.loadEmail();

  static String? _env(String key) {
    final value = dotenv.env[key]?.trim();
    return (value != null && value.isNotEmpty) ? value : null;
  }

  /// Inisialisasi plugin + restore akun Google di background (tanpa dialog jika memungkinkan).
  Future<void> warmUp() {
    _warmUpFuture ??= _warmUp();
    return _warmUpFuture!;
  }

  Future<void> _warmUp() async {
    await _ensureInitialized();
    if (_currentAccount != null) return;

    await _restoreAccountFromPlatform();
    if (_currentAccount != null) return;

    await signInSilently();
  }

  /// Menunggu event sign-in dari OS jika user pernah login — **tanpa** memicu dialog.
  Future<void> _restoreAccountFromPlatform() async {
    if (_currentAccount != null) return;
    await _waitForAuthEvent(const Duration(milliseconds: 1200));
  }

  Future<void> _init() async {
    await _googleSignIn.initialize(
      clientId: _env('GOOGLE_IOS_CLIENT_ID'),
      serverClientId: _env('GOOGLE_SERVER_CLIENT_ID'),
    );

    await _authEventsSub?.cancel();
    _authEventsSub = _googleSignIn.authenticationEvents.listen(
      (event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            _rememberAccount(event.user);
          case GoogleSignInAuthenticationEventSignOut():
            _currentAccount = null;
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _rememberAccount(GoogleSignInAccount user) async {
    _currentAccount = user;
    await _sessionStore.saveEmail(user.email);
  }

  void _invalidateCachedClient() {
    _cachedAuthClient = null;
    _cachedAuthClientEmail = null;
  }

  Future<void> _ensureInitialized() => _initialization;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _googleSignIn.authenticationEvents;

  /// Akun Google yang sudah terhubung — tanpa dialog.
  Future<GoogleSignInAccount?> connectForGoogleApi() async {
    await warmUp();
    return _currentAccount;
  }

  /// Untuk sinkron: pakai sesi yang sudah dipulihkan — tanpa dialog interaktif.
  Future<GoogleSignInAccount?> prepareForGoogleSync() async {
    await warmUp();
    return _currentAccount;
  }

  Future<GoogleSignInAccount?> _waitForAuthEvent(Duration timeout) async {
    if (_currentAccount != null) return _currentAccount;

    final completer = Completer<GoogleSignInAccount?>();
    late final StreamSubscription<GoogleSignInAuthenticationEvent> sub;
    sub = _googleSignIn.authenticationEvents.listen((event) {
      if (event case GoogleSignInAuthenticationEventSignIn(:final user)) {
        if (!completer.isCompleted) {
          completer.complete(user);
        }
      }
    });

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => _currentAccount,
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    await _ensureInitialized();
    if (_currentAccount != null) {
      return _currentAccount;
    }

    final attempt = _googleSignIn.attemptLightweightAuthentication();
    if (attempt == null) {
      return _currentAccount;
    }
    try {
      final user = await attempt;
      if (user != null) {
        await _rememberAccount(user);
      }
      return user;
    } on GoogleSignInException catch (e) {
      if (_isBenignSignInError(e)) return null;
      throw _mapSignInException(e);
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();
    try {
      final user = await _googleSignIn.authenticate(
        scopeHint: AppConstants.googleScopes,
      );
      await _rememberAccount(user);
      // Grant scope sekali saat login — client di-cache untuk sinkron berikutnya.
      await _clientForAccount(user, allowInteractive: true);
      return user;
    } on GoogleSignInException catch (e) {
      if (_isBenignSignInError(e)) return null;
      throw _mapSignInException(e);
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    _currentAccount = null;
    _warmUpFuture = null;
    _invalidateCachedClient();
    await _sessionStore.clear();
    await _googleSignIn.signOut();
  }

  Future<GoogleSignInAccount?> get currentUser async {
    await _ensureInitialized();
    return _currentAccount;
  }

  Future<http.Client> getAuthenticatedClient({bool forSync = false}) async {
    final user = forSync
        ? await prepareForGoogleSync()
        : await connectForGoogleApi();
    if (user == null) {
      throw Exception(
        forSync
            ? 'Sinkron gagal — sesi Google tidak tersedia. Keluar akun lalu masuk kembali.'
            : 'Hubungkan Google lewat menu ⋮ → Sinkronkan data.',
      );
    }
    return _clientForAccount(user, allowInteractive: false);
  }

  Future<http.Client> reauthenticate() async {
    _invalidateCachedClient();

    var account = _currentAccount ?? await signInSilently();
    if (account != null) {
      try {
        return await _clientForAccount(account, allowInteractive: false);
      } catch (_) {}
    }

    account = await signIn();
    if (account == null) {
      throw Exception('Re-autentikasi dibatalkan');
    }
    return _clientForAccount(account, allowInteractive: true);
  }

  Future<auth.AuthClient> _clientForAccount(
    GoogleSignInAccount user, {
    required bool allowInteractive,
  }) async {
    if (_cachedAuthClient != null && _cachedAuthClientEmail == user.email) {
      return _cachedAuthClient!;
    }

    final authorization = user.authorizationClient;
    var tokens = await authorization.authorizationForScopes(
      AppConstants.googleScopes,
    );
    if (tokens == null && allowInteractive) {
      tokens = await authorization.authorizeScopes(AppConstants.googleScopes);
    }
    if (tokens == null) {
      throw Exception(
        'Sesi Google perlu diperbarui — keluar lalu masuk kembali.',
      );
    }

    final client = tokens.authClient(scopes: AppConstants.googleScopes);
    _cachedAuthClient = client;
    _cachedAuthClientEmail = user.email;
    return client;
  }

  void dispose() {
    _authEventsSub?.cancel();
  }

  static bool _isBenignSignInError(GoogleSignInException e) =>
      e.code == GoogleSignInExceptionCode.canceled ||
      e.code == GoogleSignInExceptionCode.interrupted ||
      e.code == GoogleSignInExceptionCode.uiUnavailable;

  static Exception _mapSignInException(GoogleSignInException e) {
    if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
      return Exception(
        'Login Google belum dikonfigurasi. Buat OAuth Client ID tipe '
        '"Web application" di Google Cloud Console, lalu tambahkan ke .env:\n'
        'GOOGLE_SERVER_CLIENT_ID=<client_id_web>.apps.googleusercontent.com',
      );
    }
    final description = e.description ?? '';
    if (e.code == GoogleSignInExceptionCode.unknownError &&
        (description.contains('28444') ||
            description.toLowerCase().contains('developer console'))) {
      return Exception(
        'Google Cloud belum cocok dengan perangkat ini (SHA-1).\n\n'
        'Tambahkan SHA-1 debug ke OAuth Android di Console '
        '(cd android && gradlew signingReport), package com.uangapp.uangapp.',
      );
    }
    return Exception(
      'Google Sign-In gagal: ${description.isNotEmpty ? description : e.code.name}',
    );
  }

  bool isAuthError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized') ||
        message.contains('invalid_grant') ||
        message.contains('token') ||
        message.contains('sesi google');
  }
}

/// Wrapper that retries API calls once after re-auth on 401/403.
class AuthenticatedApiRunner {
  AuthenticatedApiRunner(this._authService);

  final GoogleAuthService _authService;

  Future<T> run<T>(
    Future<T> Function(http.Client client) action, {
    bool forSync = false,
  }) async {
    var client = await _authService.getAuthenticatedClient(forSync: forSync);
    try {
      return await action(client);
    } catch (e) {
      if (_authService.isAuthError(e)) {
        client = await _authService.reauthenticate();
        return await action(client);
      }
      rethrow;
    }
  }
}
