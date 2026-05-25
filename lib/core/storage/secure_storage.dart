import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// All JWT tokens live here — backed by Android Keystore / iOS Keychain.
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId = 'user_id';
  static const _kUserRole = 'user_role';
  static const _kGymId = 'gym_id';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';

  // ── Write ──────────────────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
    ]);
  }

  static Future<void> saveUserInfo({
    required String userId,
    required String role,
    required String gymId,
    required String name,
    required String email,
  }) async {
    await Future.wait([
      _storage.write(key: _kUserId, value: userId),
      _storage.write(key: _kUserRole, value: role),
      _storage.write(key: _kGymId, value: gymId),
      _storage.write(key: _kUserName, value: name),
      _storage.write(key: _kUserEmail, value: email),
    ]);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  static Future<String?> getAccessToken() =>
      _storage.read(key: _kAccessToken);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _kRefreshToken);

  static Future<String?> getUserId() => _storage.read(key: _kUserId);
  static Future<String?> getUserRole() => _storage.read(key: _kUserRole);
  static Future<String?> getGymId() => _storage.read(key: _kGymId);
  static Future<String?> getUserName() => _storage.read(key: _kUserName);
  static Future<String?> getUserEmail() => _storage.read(key: _kUserEmail);

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Clear ──────────────────────────────────────────────────────────────────

  static Future<void> clearAll() => _storage.deleteAll();
}
