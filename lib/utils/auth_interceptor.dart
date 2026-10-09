import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../ui/screens/auth/auth_screen.dart';

class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getToken;
  final VoidCallback onUnauthorized;

  AuthInterceptor({
    required this.getToken,
    required this.onUnauthorized,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    
    // 401: Unauthorized / Session Expired
    if (response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthRequest = path.contains('/login') || path.contains('/register');
      
      if (!isAuthRequest) {
        onUnauthorized();
        _showErrorSnackBar('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');
        
        // Redirect to login if possible
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (route) => false,
          );
        }
      }
    } 
    
    // 429: Too Many Requests (Throttling)
    else if (response?.statusCode == 429) {
      String message = 'لقد تجاوزت عدد المحاولات المسموح بها. يرجى المحاولة لاحقاً.';
      if (response?.data is Map && response?.data['message'] != null) {
        message = response!.data['message'];
      }
      _showErrorSnackBar(message);
    }
    
    // 500: Server Error
    else if (response?.statusCode != null && response!.statusCode! >= 500) {
      _showErrorSnackBar('حدث خطأ في الخادم. يرجى المحاولة لاحقاً.');
    }

    return handler.next(err);
  }

  void _showErrorSnackBar(String message) {
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
