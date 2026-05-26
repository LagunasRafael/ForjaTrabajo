import '../../domain/models/user_model.dart';

class AuthState {
  final String status;
  final String errorMessage;
  final User? user;

  AuthState({this.status = 'initial', this.errorMessage = '', this.user});

  AuthState copyWith({String? status, String? errorMessage, User? user}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}
