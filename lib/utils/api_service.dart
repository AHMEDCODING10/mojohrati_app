import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:typed_data';
import '../config/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'auth_interceptor.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: '${AppConstants.apiBaseUrl}/api/v1',
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
    sendTimeout: const Duration(seconds: 90),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  void initialize({
    required Future<String?> Function() getToken,
    required void Function() onUnauthorized,
  }) {
    _dio.interceptors.add(AuthInterceptor(
      getToken: getToken,
      onUnauthorized: onUnauthorized,
    ));
  }

  // Products
  Future<Response> getProducts({Map<String, dynamic>? filters}) async {
    return await _dio.get('/products', queryParameters: filters);
  }

  Future<Response> getCategories() async {
    return await _dio.get('/categories');
  }

  Future<Response> getMerchants() async {
    return await _dio.get('/merchants');
  }

  Future<Response> addProduct(Map<String, dynamic> data) async {
    final Map<String, dynamic> fields = Map.from(data);
    final List<dynamic>? images = fields.remove('images');
    
    FormData formData = FormData.fromMap(fields);
    
    if (images != null) {
      for (var image in images) {
        if (image is XFile) {
          final bytes = await image.readAsBytes();
          formData.files.add(MapEntry(
            'images[]',
            MultipartFile.fromBytes(
              bytes, 
              filename: image.name,
              contentType: DioMediaType('image', image.name.split('.').last),
            ),
          ));
        } else if (image is String && !image.startsWith('http')) {
          formData.files.add(MapEntry(
            'images[]',
            await MultipartFile.fromFile(image),
          ));
        }
      }
    }

    return await _dio.post('/products', data: formData);
  }

  Future<Response> updateProduct(String id, Map<String, dynamic> data) async {
    final Map<String, dynamic> fields = Map.from(data);
    final List<dynamic>? images = fields.remove('images');
    
    FormData formData = FormData.fromMap(fields);

    if (images != null) {
      for (var image in images) {
        if (image is XFile) {
          final bytes = await image.readAsBytes();
          formData.files.add(MapEntry(
            'images[]',
            MultipartFile.fromBytes(
              bytes, 
              filename: image.name,
              contentType: DioMediaType('image', image.name.split('.').last),
            ),
          ));
        } else if (image is String && !image.startsWith('http')) {
          formData.files.add(MapEntry(
            'images[]',
            await MultipartFile.fromFile(image),
          ));
        }
      }
    }
    
    formData.fields.add(const MapEntry('_method', 'PUT'));

    return await _dio.post('/products/$id', data: formData);
  }

  Future<Response> deleteProduct(String id) async {
    return await _dio.delete('/products/$id');
  }

  Future<Response> getProductDetails(String slug) async {
    return await _dio.get('/products/$slug');
  }

  Future<Response> getProduct(String id) async {
    return await _dio.get('/products/$id');
  }

  // Auth
  Future<Response> login(String phone, String password) async {
    return await _dio.post('/login', data: {
      'phone': phone,
      'password': password,
    });
  }

  Future<Response> logout() async {
    return await _dio.post('/logout');
  }

  Future<Response> deleteAccount() async {
    return await _dio.delete('/user');
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return await _dio.post('/register', data: data);
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.post('/update-profile', data: data);
  }

  Future<Response> changePassword(String current, String newPass, String confirmPass) async {
    return await _dio.post('/change-password', data: {
      'current_password': current,
      'new_password': newPass,
      'new_password_confirmation': confirmPass,
    });
  }

  Future<Response> forceResetPassword(String newPass, String confirmPass) async {
    return await _dio.post('/force-reset-password', data: {
      'password': newPass,
      'password_confirmation': confirmPass,
    });
  }

  Future<Response> resetPassword(String email, String phone, String password, String confirmPass) async {
    return await _dio.post('/reset-password', data: {
      'email': email,
      'phone': phone,
      'password': password,
      'password_confirmation': confirmPass,
    });
  }

  Future<Response> sendResetCode(String email) async {
    return await _dio.post('/forgot-password/send-code', data: {
      'email': email,
    });
  }

  Future<Response> verifyResetCode(String email, String code) async {
    return await _dio.post('/forgot-password/verify-code', data: {
      'email': email,
      'code': code,
    });
  }

  Future<Response> resetPasswordWithCode(String email, String code, String password, String confirmPass) async {
    return await _dio.post('/forgot-password/reset', data: {
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': confirmPass,
    });
  }

  // Bookings
  Future<Response> createBooking(int productId, String? notes, {int quantity = 1}) async {
    return await _dio.post(
      '/bookings',
      data: {
        'product_id': productId,
        'quantity': quantity,
        'customer_notes': notes,
      },
    );
  }

  Future<Response> updateBookingStatus(String bookingId, String status, [String? reason]) async {
    final data = {'status': status};
    if (reason != null && reason.isNotEmpty) {
      data['reason'] = reason;
      data['rejection_reason'] = reason; // Added for compatibility with Laravel validation
    }
    return await _dio.patch('/bookings/$bookingId', data: data);
  }

  Future<Response> getBookings() async {
    return await _dio.get('/bookings');
  }

  // Notifications
  Future<Response> getNotifications() async {
    return await _dio.get('/notifications');
  }

  Future<Response> markNotificationRead(String id) async {
    return await _dio.post('/notifications/$id/read');
  }

  Future<Response> markAllNotificationsRead() async {
    return await _dio.post('/notifications/read-all');
  }

  // Banners
  Future<Response> getBanners({Map<String, dynamic>? params}) async {
    return await _dio.get('/banners', queryParameters: params);
  }

  // Reports
  Future<Response> reportContent(String type, String id, String reason) async {
    return await _dio.post(
      '/reports',
      data: {'type': type, 'id': id, 'reason': reason},
    );
  }

  // Analytics
  Future<Response> getMerchantAnalytics() async {
    return await _dio.get('/merchant/analytics');
  }

  Future<Response> createCategory(Map<String, dynamic> data) async {
    final Map<String, dynamic> fields = Map.from(data);
    final logo = fields.remove('image_file');

    FormData formData = FormData.fromMap(fields);

    if (logo != null) {
      if (logo is XFile) {
        final bytes = await logo.readAsBytes();
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(bytes, filename: logo.name),
        ));
      }
    }

    return await _dio.post('/categories', data: formData);
  }

  Future<Response> deleteCategory(String id) async {
    return await _dio.delete('/categories/$id');
  }

  Future<Response> deleteAllCategories() async {
    return await _dio.delete('/categories/all');
  }

  Future<Response> getMerchantCustomDesigns() async {
    return await _dio.get('/merchant/custom-designs');
  }

  Future<Response> updateCustomDesignStatus(String id, String status) async {
    return await _dio.patch(
      '/merchant/custom-designs/$id/status',
      data: {'status': status},
    );
  }

  // Verification
  Future<Response> getVerificationStatus() async {
    return await _dio.get('/merchant/verification/status');
  }

  Future<Response> uploadVerificationDocument(String filePath, String type) async {
    FormData formData = FormData.fromMap({
      'type': type,
      'document': await MultipartFile.fromFile(filePath),
    });

    return await _dio.post('/merchant/verification/upload', data: formData);
  }

  Future<Response> uploadVerificationDocumentBytes(Uint8List bytes, String filename, String type) async {
    FormData formData = FormData.fromMap({
      'type': type,
      'document': MultipartFile.fromBytes(bytes, filename: filename),
    });

    return await _dio.post('/merchant/verification/upload', data: formData);
  }

  Future<Response> getContactSettings() async {
    return await _dio.get('/settings/contact');
  }

  Future<Response> getGoldPrices() async {
    return await _dio.get('/gold-prices');
  }

  // Custom Designs
  Future<Response> getCustomDesigns() async {
    return await _dio.get('/custom-designs');
  }

  Future<Response> createCustomDesign(Map<String, dynamic> data) async {
    final Map<String, dynamic> map = Map.from(data);
    final XFile? image = map.remove('image') as XFile?;

    FormData formData = FormData.fromMap(map);
    if (image != null) {
      final bytes = await image.readAsBytes();
      formData.files.add(MapEntry(
        'reference_image', // ← يجب أن يطابق اسم الحقل في الـ Backend
        MultipartFile.fromBytes(bytes, filename: image.name),
      ));
    }
    return await _dio.post('/custom-designs', data: formData);
  }

  // Merchant Branding
  Future<Response> updateMerchantBranding(Map<String, dynamic> data) async {
    final Map<String, dynamic> map = Map.from(data);
    final logo = map.remove('logo_file');
    final banner = map.remove('banner_file');

    FormData formData = FormData.fromMap(map.map((k, v) => MapEntry(k, v?.toString() ?? '')));

    if (logo != null) {
      if (logo is XFile) {
        if (kIsWeb) {
          final bytes = await logo.readAsBytes();
          formData.files.add(MapEntry(
            'logo',
            MultipartFile.fromBytes(bytes, filename: logo.name),
          ));
        } else {
          formData.files.add(MapEntry(
            'logo',
            await MultipartFile.fromFile(logo.path, filename: logo.name),
          ));
        }
      } else if (logo is File) {
         formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(logo.path, filename: logo.path.split(RegExp(r'[/\\]')).last),
        ));
      }
    }

    if (banner != null) {
      if (banner is XFile) {
        if (kIsWeb) {
          final bytes = await banner.readAsBytes();
          formData.files.add(MapEntry(
            'banner',
            MultipartFile.fromBytes(bytes, filename: banner.name),
          ));
        } else {
          formData.files.add(MapEntry(
            'banner',
            await MultipartFile.fromFile(banner.path, filename: banner.name),
          ));
        }
      } else if (banner is File) {
         formData.files.add(MapEntry(
          'banner',
          await MultipartFile.fromFile(banner.path, filename: banner.path.split(RegExp(r'[/\\]')).last),
        ));
      }
    }

    return await _dio.post('/merchant/branding', data: formData);
  }

  // Favorites
  Future<Response> getFavorites() async {
    return await _dio.get('/favorites');
  }

  Future<Response> toggleFavorite(String productId) async {
    return await _dio.post('/favorites/toggle', data: {'product_id': productId});
  }

  // Reviews
  Future<Response> getProductReviews(String productId) async {
    return await _dio.get('/reviews', queryParameters: {'product_id': productId});
  }

  Future<Response> submitReview(String productId, double rating, String comment) async {
    return await _dio.post(
      '/reviews',
      data: {
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      },
    );
  }

  Future<Response> getExchangeRates() async {
    return await _dio.get('/settings/exchange-rates');
  }

  // Promotion Requests
  Future<Response> getMerchantPromotionRequests() async {
    return await _dio.get('/merchant/promotions/requests');
  }

  Future<Response> submitPromotionRequest({
    required String type,
    String? categoryId,
    List<int>? productIds,
    required int durationWeeks,
    required File receiptImage,
  }) async {
    final Map<String, dynamic> fields = {
      'type': type,
      'duration_weeks': durationWeeks,
    };
    if (categoryId != null) fields['category_id'] = categoryId;
    if (productIds != null && productIds.isNotEmpty) {
      for (int i = 0; i < productIds.length; i++) {
        fields['product_ids[$i]'] = productIds[i];
      }
    }

    final formData = FormData.fromMap(fields);
    formData.files.add(MapEntry(
      'receipt_image',
      await MultipartFile.fromFile(receiptImage.path),
    ));

    return await _dio.post('/merchant/promotions/request', data: formData);
  }

}
