part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.userEmail,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? userEmail;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    String? userEmail,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, userEmail, errorMessage];
}
