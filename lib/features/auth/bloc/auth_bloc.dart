import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uangapp/services/google_auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authService) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<_AuthGoogleSignedIn>(_onGoogleSignedIn);

    _authSubscription = _authService.authenticationEvents.listen((event) {
      if (event case GoogleSignInAuthenticationEventSignIn(:final user)) {
        add(_AuthGoogleSignedIn(user.email));
      }
    });
  }

  final GoogleAuthService _authService;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final cachedEmail = await _authService.cachedEmail;

    if (cachedEmail != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        userEmail: cachedEmail,
        errorMessage: null,
      ));
      // Restore akun Google di background tanpa memblokir UI.
      unawaited(_authService.warmUp());
      return;
    }

    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  void _onGoogleSignedIn(_AuthGoogleSignedIn event, Emitter<AuthState> emit) {
    if (state.status != AuthStatus.authenticated ||
        state.userEmail != event.email) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        userEmail: event.email,
        errorMessage: null,
      ));
    }
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final user = await _authService.signIn();
      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          userEmail: user.email,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Sign-in dibatalkan',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
