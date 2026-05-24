part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event internal — sesi Google dipulihkan dari stream.
final class _AuthGoogleSignedIn extends AuthEvent {
  const _AuthGoogleSignedIn(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
