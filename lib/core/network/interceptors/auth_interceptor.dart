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

  // Shared by all concurrent 401s so only one refresh call is ever in
  // flight — the backend rotates the refresh token on every use, so two
  // simultaneous refresh attempts would race and the loser's now-stale
  // token would be rejected, force-logging-out a session that was still
  // valid.
  Future<String>? _refreshFuture;

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

    if (is401 && !isRefreshEndpoint) {
      try {
        final newAccessToken = await _refreshAccessToken();

        // Retry the original request with the fresh token
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);
        handler.resolve(retryResponse);
        return;
      } catch (e) {
        debugPrint('[AUTH] Token refresh failed: $e — forcing logout');
        await _forceLogout();
        return handler.reject(err); // auth failed — router redirect will take over
      }
    }

    return handler.next(err);
  }

  // Ensures only one /auth/refresh call is ever in flight at a time.
  // Concurrent 401s all await the same Future and share its result instead
  // of each racing their own refresh call against the backend's rotation.
  Future<String> _refreshAccessToken() {
    return _refreshFuture ??=
        _doRefresh().whenComplete(() => _refreshFuture = null);
  }

  Future<String> _doRefresh() async {
    final refreshToken = await SecureStorage.getRefreshToken();

    // No refresh token stored → nothing to refresh with.
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No refresh token stored');
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
          newRefreshToken = cookie.split('refreshToken=')[1].split(';')[0];
          break;
        }
      }
    }

    await SecureStorage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );

    return newAccessToken;
  }

  Future<void> _forceLogout() async {
    await SecureStorage.clearAll();
    forceLogoutEvents.add(null); // AuthNotifier listens and sets unauthenticated
  }
}
