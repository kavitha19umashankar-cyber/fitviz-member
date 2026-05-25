import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../constants/api_constants.dart';
import '../../storage/secure_storage.dart';
import '../../events/app_events.dart';

/// Injects Bearer token on every request.
/// On 401 → attempts one silent token refresh → retries original request.
/// On refresh failure → fires forceLogoutEvents (AuthNotifier reacts) and clears storage.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final gymId = await SecureStorage.getGymId();
    if (gymId != null && gymId.isNotEmpty) {
      options.headers['x-gym-id'] = gymId;
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final isRefreshEndpoint =
        err.requestOptions.path.contains(ApiConstants.refresh);

    if (is401 && !isRefreshEndpoint && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorage.getRefreshToken();

        // No refresh token stored → immediate force logout, resolve with empty to stop error propagation
        if (refreshToken == null || refreshToken.isEmpty) {
          await _forceLogout();
          return handler.reject(err); // reject so router redirect takes over
        }

        final response = await _dio.post(
          ApiConstants.refresh,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;

        // Backend rotates the refresh token — save the new one from Set-Cookie
        String newRefreshToken = refreshToken;
        final cookies = response.headers.map['set-cookie'];
        if (cookies != null) {
          for (final cookie in cookies) {
            if (cookie.startsWith('refreshToken=')) {
              newRefreshToken =
                  cookie.split('refreshToken=')[1].split(';')[0];
              break;
            }
          }
        }

        await SecureStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry the original request with the fresh token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
        return;
      } catch (e) {
        debugPrint('[AUTH] Token refresh failed: $e — forcing logout');
        await _forceLogout();
        _isRefreshing = false;
        return handler.reject(err); // auth failed — router redirect will take over
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }

  Future<void> _forceLogout() async {
    await SecureStorage.clearAll();
    forceLogoutEvents.add(null); // AuthNotifier listens and sets unauthenticated
  }
}
