import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/token_storage.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
  });

  final int id;
  final int? schoolId;
  final String name;
  final String email;
  final String role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      schoolId: json['school_id'] as int?,
      name: json['name'].toString(),
      email: json['email'].toString(),
      role: json['role'].toString(),
    );
  }
}

class AuthState {
  const AuthState({this.user, this.loading = false});

  final AppUser? user;
  final bool loading;

  bool get authenticated => user != null;

  AuthState copyWith({AppUser? user, bool? loading, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      loading: loading ?? this.loading,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  final _api = ApiClient();
  final _storage = const TokenStorage();

  @override
  AuthState build() {
    return const AuthState();
  }

  Future<bool> restore() async {
    final token = await _storage.readAccessToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    state = state.copyWith(loading: true);

    try {
      final result = await _api.get('/api/v1/auth/me');

      state = AuthState(
        user: AppUser.fromJson(Map<String, dynamic>.from(result)),
      );

      return true;
    } catch (_) {
      await _storage.clear();

      state = const AuthState();

      return false;
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(loading: true);

    try {
      final result = await _api.post(
        '/api/v1/auth/login',
        authenticated: false,
        body: {'email': email, 'password': password},
      );

      final map = Map<String, dynamic>.from(result);

      await _storage.save(
        accessToken: map['access_token'].toString(),
        refreshToken: map['refresh_token'].toString(),
      );

      final user = AppUser.fromJson(Map<String, dynamic>.from(map['user']));

      state = AuthState(user: user);

      return user;
    } catch (_) {
      state = state.copyWith(loading: false);

      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();

    try {
      if (refreshToken != null) {
        await _api.post(
          '/api/v1/auth/logout',
          body: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {}

    await _storage.clear();

    state = const AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
