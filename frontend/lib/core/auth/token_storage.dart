import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the session tokens. The access token lives in memory only; the refresh token is persisted in the platform's
/// secure storage (Keychain on iOS, encrypted storage on Android) so the user stays signed in.
class TokenStorage {
  TokenStorage(this._secure);

  static const _refreshKey = 'maktab.refreshToken';

  final FlutterSecureStorage _secure;
  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<String?> readRefreshToken() => _secure.read(key: _refreshKey);

  Future<void> save({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    await _secure.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    await _secure.delete(key: _refreshKey);
  }
}
