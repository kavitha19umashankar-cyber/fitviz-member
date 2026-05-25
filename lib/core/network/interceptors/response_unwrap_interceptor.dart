import 'package:dio/dio.dart';

/// Transparently unwraps the backend's standard envelope:
///   { success: true, message: "...", data: <actual payload> }
/// After this interceptor runs, `response.data` is just the payload.
class ResponseUnwrapInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final raw = response.data;
    if (raw is Map && raw.containsKey('success') && raw.containsKey('data')) {
      response.data = raw['data'];
    }
    handler.next(response);
  }
}
