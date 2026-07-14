import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../flavors/flavor_config.dart';
import 'models/auth_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResponse> login(String phone, String password) async {
    final res = await _dio.post(
      ApiConstants.login,
      data: {
        'phone': phone.trim(),
        'password': password,
        'appFlavor': FlavorConfig.instance.flavor.name,
      },
    );
    // ResponseUnwrapInterceptor already strips the { success, message, data } envelope.
    // refreshToken is set as an HTTP-only cookie; extract it from Set-Cookie header.
    final data = res.data as Map<String, dynamic>;

    String refreshToken = '';
    final cookies = res.headers.map['set-cookie'];
    if (cookies != null) {
      for (final cookie in cookies) {
        if (cookie.startsWith('refreshToken=')) {
          refreshToken = cookie.split('refreshToken=')[1].split(';')[0];
          break;
        }
      }
    }

    return AuthResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: refreshToken,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String gymId,
  }) async {
    // Register doesn't return tokens — it creates the account, then we login
    await _dio.post(
      ApiConstants.register,
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'gymId': gymId,
      },
    );
    // Immediately login to get tokens
    return login(phone, password);
  }

  Future<void> logout() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post(
          ApiConstants.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Best-effort logout — always clear local storage
    } finally {
      await SecureStorage.clearAll();
    }
  }

  // Sends OTP via WhatsApp to the given phone number
  Future<void> forgotPasswordWhatsApp(String phone) async {
    await _dio.post(ApiConstants.forgotPassword, data: {
      'method': 'phone',
      'identifier': phone.trim(),
    });
  }

  // Verifies the OTP — no resetToken returned; phone+otp are used directly in resetPassword
  Future<void> verifyResetOtp(String phone, String otp) async {
    await _dio.post(ApiConstants.verifyResetOtp, data: {
      'identifier': phone.trim(),
      'otp': otp.trim(),
    });
  }

  Future<void> resetPassword(
      String phone, String otp, String newPassword) async {
    await _dio.post(ApiConstants.resetPassword, data: {
      'identifier': phone.trim(),
      'otp': otp.trim(),
      'newPassword': newPassword,
    });
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    await _dio.put(ApiConstants.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<List<GymModel>> getActiveGyms() async {
    final res = await _dio.get(ApiConstants.activeGyms);
    final list = (res.data as List<dynamic>?) ?? [];
    return list
        .map((e) => GymModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> getProfile() async {
    final res = await _dio.get(ApiConstants.profile);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateFcmToken(String token) async {
    await _dio.put(ApiConstants.updateFcm, data: {
      'fcmToken': token,
      'appFlavor': FlavorConfig.instance.flavor.name,
    });
  }
}
