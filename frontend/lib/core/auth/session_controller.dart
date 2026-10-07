import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import 'auth_models.dart';

/// The signed-in user, or null when signed out. Loading while the stored session is being restored at start-up.
final sessionControllerProvider = AsyncNotifierProvider<SessionController, AuthUser?>(SessionController.new);

class SessionController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    try {
      return await ref.read(authRepositoryProvider).restore();
    } catch (_) {
      // Offline at start-up: show the login screen rather than an error.
      return null;
    }
  }

  /// Throws [ApiException] on failure so the login form can show the message; the state stays signed out.
  Future<void> signIn(String email, String password) async {
    final user = await ref.read(authRepositoryProvider).signIn(email, password);
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  /// Called after a password change so `mustChangePassword` is cleared.
  Future<void> reload() async {
    final user = await ref.read(authRepositoryProvider).fetchMe();
    state = AsyncData(user);
  }

  void sessionExpired() {
    if (state.value != null) {
      state = const AsyncData(null);
    }
  }
}
