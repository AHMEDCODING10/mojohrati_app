import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../utils/api_service.dart';
import '../utils/localization_service.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/booking.dart';
import '../models/order.dart';
import '../utils/notification_socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/review.dart';
import 'package:app_links/app_links.dart';

import '../main.dart';
import '../ui/screens/customer/product_details_screen.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  Locale _locale = const Locale('ar');
  List<Product> _products = [];
  List<Booking> _bookings = [];
  List<Order> _orders = [];
  List<dynamic> _categories = [];
  List<dynamic> _merchants = [];
  bool _isLoading = false;
  bool _showOnlyOutOfStock = false;
  String? lastResetCode;
  Map<String, dynamic>? _merchantAnalytics;
  int _currentPage = 1;
  bool _hasMore = true;
  final bool _isSlowConnection = false;
  bool _isFetchingMore = false;
  String? _error;
  List<dynamic> _verificationDocuments = [];
  String? _lastError;
  Map<String, dynamic>? _lastValidationErrors;
  bool _useBiometrics = false;
  List<dynamic> _contactList = [];
  bool _isLoadingSettings = false;
  double? _basePriceOunceUSD;
  bool _isServerConnected = false;
  final Map<String, double> _currencyRates = {
    'YER': 530.0,
    'SAR': 140.0,
    'USD': 1.0,
  };
  
  String _selectedCurrency = 'USD';
  String _selectedUnit = 'K24';
  int _selectedKarat = 24;
  bool _showGramPrice = false;
  final Map<int, double> _caratPricesUSD = {};
  List<dynamic> _notifications = [];
  final Map<String, List<dynamic>> _bannersByPlacement = {};
  // For backwards compatibility, return all banners flat
  List<dynamic> get banners => _bannersByPlacement.values.expand((element) => element).toList();
  List<Map<String, dynamic>> _merchantCustomDesigns = [];
  List<Map<String, dynamic>> _customerCustomDesigns = [];
  NotificationSocketService? _socketService;
  bool _isDisposed = false;
  bool _hasNewBookings = false; // Flag for bookings screen alert
  bool _hasNewNotifications = false; // Flag for general notification alert (snackbar)
  Map<String, dynamic>? _latestNotificationPayload; // Store dynamic payload for UI alerts
  int _unreadNotificationsCount = 0; // Real count for badges
  
  // Reviews state
  final Map<String, List<Review>> _productReviews = {};
  bool _isLoadingReviews = false;
  final AppLinks _appLinks = AppLinks();

  bool get hasNewBookings => _hasNewBookings;
  bool get hasNewNotifications => _hasNewNotifications;
  Map<String, dynamic>? get latestNotificationPayload => _latestNotificationPayload;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  void clearBookingAlert() {
    _hasNewBookings = false;
    _safeNotifyListeners();
  }

  void clearNotificationAlert() {
    _hasNewNotifications = false;
    _latestNotificationPayload = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeSocket();
    super.dispose();
  }

  User? get currentUser => _currentUser;
  String? get token => _token;
  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  Map<String, dynamic>? get lastValidationErrors => _lastValidationErrors;
  Map<String, dynamic>? get merchantAnalytics => _merchantAnalytics;
  bool get isInitialLoading => _isLoading && _products.isEmpty;
  List<Product> get products => _products;
  bool get showOnlyOutOfStock => _showOnlyOutOfStock;
  int get outOfStockProductsCount => _products.where((p) => p.stockQuantity <= 0).length;

  void setShowOnlyOutOfStock(bool value) {
    if (_showOnlyOutOfStock != value) {
      _showOnlyOutOfStock = value;
      notifyListeners();
    }
  }

  List<Product> get featuredProducts => _products.where((p) => p.isFeatured).toList();
  List<Booking> get bookings => _bookings;
  int get bookingsCount => _bookings.where((b) => b.status == 'pending').length; // For Merchants
  int get unreadBookingUpdatesCount => _notifications.where((n) => 
    n['read_at'] == null && 
    n['data'] != null && 
    (n['data']['type'] == 'booking_status' || n['data']['type'] == 'custom_design_status')
  ).length; // For Customers
  List<Order> get orders => _orders;
  List<dynamic> get categories => _categories;
  List<dynamic> get merchants => _merchants;
  List<dynamic> get verificationDocuments => _verificationDocuments;
  bool get isLoggedIn => _currentUser != null;
  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get isSlowConnection => _isSlowConnection;
  bool get useBiometrics => _useBiometrics;
  List<dynamic> get contactList => _contactList;
  bool get isServerConnected => _isServerConnected;
  bool get isGoldPriceLoaded => _isServerConnected && _basePriceOunceUSD != null && _basePriceOunceUSD! > 0;

  double get goldPrice {
    if (!isGoldPriceLoaded) return 0.0;
    double baseOunce = _basePriceOunceUSD ?? 0.0;
    double rate = _currencyRates[_selectedCurrency] ?? 1.0;
    if (_selectedUnit == 'أوقية') {
      return baseOunce * rate;
    }
    
    // Gram calculation - prioritize direct backend prices if available
    double karatPriceUSD;
    if (_caratPricesUSD.containsKey(_selectedKarat)) {
      karatPriceUSD = _caratPricesUSD[_selectedKarat]!;
    } else {
      // Fallback calculation based on purity
      double pricePerGram24kUSD = baseOunce / 31.1034768;
      karatPriceUSD = pricePerGram24kUSD * (_selectedKarat / 24);
    }
    
    return karatPriceUSD * rate;
  }
  
  double get globalOuncePriceUSD => _basePriceOunceUSD ?? 0.0;

  String get formattedGoldPriceDisplay {
    if (!isGoldPriceLoaded) {
      return '--------';
    }
    if (showGramPrice) {
      return '${goldPrice.toStringAsFixed(2)} ${selectedCurrency.tr()}';
    } else {
      return '${(globalOuncePriceUSD * currencyRate).toStringAsFixed(1)} ${selectedCurrency.tr()}';
    }
  }

  String get selectedCurrency => _selectedCurrency;

  double getPriceForKarat(int karat, String currency) {
    if (!isGoldPriceLoaded) return 0.0;
    double rate = _currencyRates[currency] ?? 1.0;
    double karatPriceUSD;
    if (_caratPricesUSD.containsKey(karat)) {
      karatPriceUSD = _caratPricesUSD[karat]!;
    } else {
      double pricePerGram24kUSD = (_basePriceOunceUSD ?? 0.0) / 31.1034768;
      karatPriceUSD = pricePerGram24kUSD * (karat / 24);
    }
    return karatPriceUSD * rate;
  }

  String get selectedUnit => _selectedUnit;
  int get selectedKarat => _selectedKarat;
  bool get showGramPrice => _showGramPrice;
  List<dynamic> get notifications => _notifications;
  // Removed direct getter to use map-based logic
  List<Map<String, dynamic>> get merchantCustomDesigns => _merchantCustomDesigns;
  List<Map<String, dynamic>> get customerCustomDesigns => _customerCustomDesigns;
  bool get isLoadingSettings => _isLoadingSettings;
  double get currencyRate => _currencyRates[_selectedCurrency] ?? 1.0;
  double getCurrencyRate(String currency) => _currencyRates[currency] ?? 1.0;

  // Reviews Getters
  List<Review> getProductReviews(String productId) => _productReviews[productId] ?? [];
  bool get isLoadingReviews => _isLoadingReviews;

  final ApiService _apiService = ApiService();

  Future<bool> deleteProduct(String id) async {
    if (_token == null) return false;
    try {
      await _apiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete product error: $e');
      return false;
    }
  }


  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    if (_token == null) return false;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _apiService.updateProduct(id, data);
      await fetchMerchantProducts(); // Refresh list
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update product error: $e');
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData != null && responseData['message'] != null) {
          _lastError = responseData['message'];
        } else {
          _lastError = 'فشل تعديل المنتج: ${e.message}';
        }
      } else {
        _lastError = 'حدث خطأ غير متوقع';
      }
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<void> fetchProducts({
    String? search,
    String? categoryId,
    String? merchantId,
    String? materialType,
    double? minPrice,
    double? maxPrice,
    double? minWeight,
    double? maxWeight,
    String? purity,
    bool isRefresh = false,
    bool loadMore = false,
    bool silently = false,
  }) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    
    if (loadMore) {
      if (!_hasMore || _isFetchingMore) return;
      _isFetchingMore = true;
    } else {
      if (!silently) _isLoading = true;
      if (!isRefresh) {
        _products = [];
        _currentPage = 1;
        _hasMore = true;
      }
      
      // Load from cache for page 1
      if (_currentPage == 1 && search == null && categoryId == null && merchantId == null) {
        final cacheBox = Hive.box('cache');
        final cachedData = cacheBox.get('featured_products');
        if (cachedData != null && cachedData is List) {
          _products = cachedData.map((p) => Product.fromJson(p)).toList();
          _safeNotifyListeners();
        }
      }
    }
    
    _safeNotifyListeners();

    try {
      final filters = <String, dynamic>{
        'page': _currentPage,
      };
      if (search != null && search.isNotEmpty) filters['search'] = search;
      if (categoryId != null) filters['category_id'] = categoryId;
      if (merchantId != null) filters['merchant_id'] = merchantId;
      if (materialType != null && materialType != 'all') filters['material_type'] = materialType;
      if (minPrice != null) filters['min_price'] = minPrice;
      if (maxPrice != null) filters['max_price'] = maxPrice;
      if (minWeight != null) filters['min_weight'] = minWeight;
      if (maxWeight != null) filters['max_weight'] = maxWeight;
      if (purity != null) filters['purity'] = purity;
      
      final response = await _apiService.getProducts(filters: filters);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data['data'] is Map ? response.data['data'] : response.data;
        final List<dynamic> productsData = responseData['data'] ?? [];
        final List<Product> newProducts = productsData.map((p) => Product.fromJson(p)).toList();
        
        if (_currentPage == 1) {
          _products = newProducts;
          // Cache featured products for faster homepage load
          final cacheBox = Hive.box('cache');
          cacheBox.put('featured_products', productsData.where((p) => p['is_featured'] == 1 || p['is_featured'] == true).toList());
        } else {
          _products.addAll(newProducts);
        }
        
        _hasMore = responseData['next_page_url'] != null;
        if (_hasMore) _currentPage++;
      }
    } finally {
      if (!silently) _isLoading = false;
      _isFetchingMore = false;
      _safeNotifyListeners();
    }
  }

  /// New Scoped Product Fetching: Returns a direct list without modifying global _products
  Future<List<Product>> fetchProductsByMerchant(String merchantId) async {
    try {
      final filters = <String, dynamic>{
        'merchant_id': merchantId,
        'status': 'published',
      };
      
      final response = await _apiService.getProducts(filters: filters);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data['data'] is Map ? response.data['data'] : response.data;
        final List<dynamic> productsData = responseData['data'] ?? [];
        return productsData.map((p) => Product.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching products by merchant: $e');
      return [];
    }
  }

  Future<Product?> fetchProductById(String id) async {
    try {
      final response = await _apiService.getProduct(id);
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return Product.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching product by ID: $e');
    }
    return null;
  }

  Future<void> fetchMerchantProducts({bool silently = false}) async {
    if (!silently) _isLoading = true;
    _products = [];
    _safeNotifyListeners();
    try {
      final response = await _apiService.getProducts(filters: {
        'merchant_id': _currentUser?.merchantId ?? _currentUser?.id, 
      });
      final rawData = response.data['data'];
      List<dynamic> productsData;
      if (rawData is List) {
        productsData = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        productsData = rawData['data'] is List ? rawData['data'] : [];
      } else {
        productsData = [];
      }
      _products = productsData.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching merchant products: $e');
    } finally {
      if (!silently) _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _lastError = null;
    _lastValidationErrors = null;
    _safeNotifyListeners();
    try {
      final response = await _apiService.login(phone, password);
      final userData = response.data['data']['user'];
      _token = response.data['data']['token'];
      
      _currentUser = User.fromJson(userData);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user_data', _encodeUser(_currentUser!));
      await prefs.setString('bio_phone', phone);
      await prefs.setString('bio_password', password);
      
      _isLoading = false;
      _initSocket();
      fetchNotifications(silently: true);
      _safeNotifyListeners();
      return true;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Login error: ${e.response?.data}');
        final responseData = e.response?.data;
        if (responseData != null) {
           _lastError = responseData['message'] ?? responseData['error'];
           final dynamic errors = responseData['errors'];
           if (errors != null && errors is Map) {
             _lastValidationErrors = Map<String, dynamic>.from(errors);
             if (_lastError == null && errors.isNotEmpty) {
                 final firstVal = errors.values.first;
                 _lastError = (firstVal is List && firstVal.isNotEmpty) ? firstVal.first.toString() : firstVal.toString();
             }
           } else if (_lastError == null && errors != null) {
             _lastError = errors.toString();
           }
        }
        
        // Final fallback for specific status codes if no message found
        if (_lastError == null) {
          if (e.response?.statusCode == 401) {
             _lastError = 'login_invalid_credentials'.tr();
          } else if (e.response?.statusCode == 403) {
             _lastError = 'account_blocked'.tr();
          } else {
             _lastError = 'error_occurred'.tr();
          }
        }
      } else {
        debugPrint('Login error: $e');
        _lastError = 'error_occurred'.tr();
      }
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _products = [];
    _bookings = [];
    _orders = [];
    _notifications = [];
    _merchantAnalytics = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
    await prefs.remove('bio_phone');
    await prefs.remove('bio_password');
    _disposeSocket();
    _hasNewBookings = false;
    _hasNewNotifications = false;
    _safeNotifyListeners();
  }

  Future<void> toggleBiometrics(bool value) async {
    _useBiometrics = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_biometrics', value);
    _safeNotifyListeners();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _useBiometrics = prefs.getBool('use_biometrics') ?? false;

    // ── Restore session from local storage ────────────────────
    final savedToken = prefs.getString('token');
    final savedUserData = prefs.getString('user_data');
    if (savedToken != null && savedUserData != null && savedUserData.isNotEmpty) {
      try {
        _token = savedToken;
        _currentUser = _decodeUser(savedUserData);
      } catch (e) {
        debugPrint('Session restore failed: $e');
        _token = null;
        _currentUser = null;
      }
    }
    // ──────────────────────────────────────────────────────────

    // Perform initial loads without individual notifications to prevent UI churn on Web
    await Future.wait([
      fetchContactSettings(silently: true),
      fetchCategories(),
      fetchGoldPrices(silently: true),
      fetchExchangeRates(silently: true),
      fetchBanners(),
    ]);

    if (isLoggedIn) {
      try {
        await fetchBookings(silently: true);
        await fetchNotifications(silently: true);
        _initSocket();
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
    
    _initDeepLinks();
    
    _safeNotifyListeners();
  }

  /// Encode user to a simple pipe-delimited string for SharedPreferences
  String _encodeUser(User u) {
    return [
      u.id, u.name, u.phone, u.email, u.type,
      u.profileImage, u.isVerified.toString(),
      u.verificationStatus, u.merchantId ?? '',
      u.storeName ?? '', u.storeLogo ?? '', u.storeBanner ?? '',
      u.whatsapp ?? '', u.instagram ?? '',
    ].map((e) => Uri.encodeComponent(e)).join('|');
  }

  /// Decode user from the pipe-delimited string
  User _decodeUser(String encoded) {
    final parts = encoded.split('|').map(Uri.decodeComponent).toList();
    return User(
      id: parts[0],
      name: parts[1],
      phone: parts[2],
      email: parts[3],
      type: parts[4],
      profileImage: parts[5],
      isVerified: parts[6] == 'true',
      verificationStatus: parts[7].isEmpty ? 'not_submitted' : parts[7],
      merchantId: parts[8].isEmpty ? null : parts[8],
      storeName: parts[9].isEmpty ? null : parts[9],
      storeLogo: parts[10].isEmpty ? null : parts[10],
      storeBanner: parts[11].isEmpty ? null : parts[11],
      whatsapp: parts[12].isEmpty ? null : parts[12],
      instagram: parts[13].isEmpty ? null : parts[13],
    );
  }

  Future<void> fetchContactSettings({bool silently = false}) async {
    if (!silently) {
      _isLoadingSettings = true;
      _safeNotifyListeners();
    }
    try {
      final response = await _apiService.getContactSettings();
      // The backend returns a list of models in the 'data' field
      if (response.data['status'] == 'success' || response.statusCode == 200) {
        final rawData = response.data['data'];
        if (rawData is List) {
           _contactList = rawData;
        } else if (rawData is Map) {
          // Fallback/Legacy Map handling
          _contactList = [
            if (rawData.containsKey('phone')) {'type': 'phone', 'label': 'phone_number'.tr(), 'value': rawData['phone'], 'icon': 'phone'},
            if (rawData.containsKey('whatsapp')) {'type': 'whatsapp', 'label': 'whatsapp'.tr(), 'value': rawData['whatsapp'], 'icon': 'whatsapp'},
            if (rawData.containsKey('email')) {'type': 'email', 'label': 'contact_email'.tr(), 'value': rawData['email'], 'icon': 'email'},
          ];
        } else {
          _contactList = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching contact settings: $e');
    } finally {
      _isLoadingSettings = false;
      if (!silently) _safeNotifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _lastError = null;
    _lastValidationErrors = null;
    _safeNotifyListeners();
    try {
      final response = await _apiService.register(data);
      if (response.data['data'] != null) {
          final userData = response.data['data']['user'];
          _token = response.data['data']['token'];
          _currentUser = User.fromJson(userData);
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', _token!);
          await prefs.setString('user_data', _encodeUser(_currentUser!));
          _initSocket();
      }
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Registration error: ${e.response?.data}');
        final responseData = e.response?.data;
        if (responseData != null) {
           _lastError = responseData['message'] ?? responseData['error'];
           final dynamic errors = responseData['errors'] ?? responseData['data'];
           
           if (errors != null && errors is Map) {
             _lastValidationErrors = Map<String, dynamic>.from(errors);
           }

           if (_lastError == null && errors != null) {
             if (errors is Map && errors.isNotEmpty) {
                final firstError = errors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  _lastError = firstError.first.toString();
                } else if (firstError is Map && firstError.isNotEmpty) {
                  _lastError = firstError.values.first.toString();
                } else {
                  _lastError = firstError.toString();
                }
             } else if (errors is String) {
                _lastError = errors;
             }
           }
        }

        _lastError ??= 'فشل التسجيل: ${e.message}';
      } else {
        debugPrint('Registration error: $e');
        _lastError = 'حدث خطأ غير متوقع أثناء التسجيل';
      }
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_token == null) return false;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final response = await _apiService.updateProfile(data);
      if (response.data['data'] != null) {
          final userData = response.data['data']['user'];
          _currentUser = User.fromJson(userData);
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', _encodeUser(_currentUser!));
      }
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    if (_token == null) return false;
    _isLoading = true;
    _lastError = null;
    _lastValidationErrors = null;
    _safeNotifyListeners();
    try {
      await _apiService.changePassword(currentPassword, newPassword, confirmPassword);
      
      // Update saved biometrics password if using it
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('bio_password') != null) {
        await prefs.setString('bio_password', newPassword);
      }
      
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      if (e is DioException) {
         final responseData = e.response?.data;
         if (responseData != null) {
            _lastError = responseData['message'] ?? responseData['error'];
            final dynamic errors = responseData['errors'];
            if (errors != null && errors is Map) {
              _lastValidationErrors = Map<String, dynamic>.from(errors);
            }
            if (_lastError == null && errors != null) {
               if (errors is Map && errors.isNotEmpty) {
                  final firstVal = errors.values.first;
                  _lastError = (firstVal is List && firstVal.isNotEmpty) ? firstVal.first.toString() : firstVal.toString();
               } else {
                  _lastError = errors.toString();
               }
            }
         }
      }
      _lastError ??= 'error_occurred'.tr();
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> updateMerchantBranding(Map<String, dynamic> data) async {
    if (_token == null || _currentUser?.type != 'merchant') return false;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final response = await _apiService.updateMerchantBranding(data);
      final responseData = response.data['data'];

      // Update cached user with returned values
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        email: _currentUser!.email,
        type: _currentUser!.type,
        profileImage: responseData?['logo_url'] ?? _currentUser!.profileImage,
        isVerified: _currentUser!.isVerified,
        verificationStatus: _currentUser!.verificationStatus,
        merchantId: _currentUser!.merchantId,
        storeName: responseData?['store_name'] ?? _currentUser!.storeName,
        storeLogo: responseData?['logo_url'] ?? _currentUser!.storeLogo,
        storeBanner: responseData?['banner_url'] ?? _currentUser!.storeBanner,
        whatsapp: responseData?['whatsapp_number'] ?? _currentUser!.whatsapp,
        instagram: responseData?['instagram_handle'] ?? _currentUser!.instagram,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', _encodeUser(_currentUser!));

      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update merchant branding error: $e');
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email, String phone, String password, String confirmPassword) async {
    _isLoading = true;
    _lastError = null;
    _lastValidationErrors = null;
    _safeNotifyListeners();
    try {
      await _apiService.resetPassword(email, phone, password, confirmPassword);
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      if (e is DioException) {
         final responseData = e.response?.data;
         if (responseData != null) {
            _lastError = responseData['message'] ?? responseData['error'];
            final dynamic errors = responseData['errors'];
            if (errors != null && errors is Map) {
              _lastValidationErrors = Map<String, dynamic>.from(errors);
            }
         }
      }
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<String?> sendResetCode(String email) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final response = await _apiService.sendResetCode(email);
      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        if (data is Map && data.containsKey('code')) {
           lastResetCode = data['code'].toString();
           debugPrint('====================================');
           debugPrint('OTP CODE FOR TESTING: ${data['code']}');
           debugPrint('====================================');
        }
      }
      _isLoading = false;
      _safeNotifyListeners();
      return null;
    } catch (e) {
      debugPrint('Send code error: $e');
      _isLoading = false;
      _safeNotifyListeners();
      if (e is DioException) {
         if (e.response != null && e.response!.data != null) {
           final data = e.response!.data;
           if (data is Map && data.containsKey('message')) {
             return data['message'].toString();
           }
         }
      }
      return 'فشل الإرسال. يرجى المحاولة لاحقاً.';
    }
  }

  Future<bool> verifyResetCode(String email, String code) async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _apiService.verifyResetCode(email, code);
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Verify code error: $e');
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordWithCode(String email, String code, String password, String confirmPassword) async {
    _isLoading = true;
    _lastError = null;
    _lastValidationErrors = null;
    _safeNotifyListeners();
    try {
      await _apiService.resetPasswordWithCode(email, code, password, confirmPassword);
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Reset password with code error: $e');
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData != null) {
          _lastError = responseData['message'] ?? responseData['error'];
          final dynamic errors = responseData['errors'];
          if (errors != null && errors is Map) {
            _lastValidationErrors = Map<String, dynamic>.from(errors);
          }
        }
      }
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<String?> requestBooking(int productId, {String? notes, int quantity = 1}) async {
    if (_token == null) return 'please_login'.tr();
    _lastError = null;
    try {
      await _apiService.createBooking(productId, notes, quantity: quantity);
      await fetchBookings();
      return null; // Null means success
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String message = 'booking_failed'.tr();
      
      if (responseData != null) {
        if (responseData['errors'] != null) {
          final Map<String, dynamic> errors = responseData['errors'];
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            message = (firstError is List && firstError.isNotEmpty) 
                ? firstError.first.toString() 
                : firstError.toString();
          }
        } else if (responseData['message'] != null) {
          message = responseData['message'];
        } else if (responseData['error'] != null) {
          message = responseData['error'];
        }
      } else {
        message = e.message ?? 'فشل الاتصال بالخادم';
      }
      
      debugPrint('Booking error details: $message');
      _error = message;
      _lastError = message;
      _safeNotifyListeners();
      return message;
    } catch (e) {
      debugPrint('Booking error (unexpected): $e');
      _error = 'حدث خطأ غير متوقع';
      _lastError = _error;
      return _error;
    }
}

  Future<void> fetchBookings({bool silently = false}) async {
    if (_token == null) return;
    if (!silently) {
      _isLoading = true;
      _safeNotifyListeners();
    }
    try {
      final response = await _apiService.getBookings();
      final List rawData = response.data['data'] ?? [];
      _bookings = rawData.map((b) => Booking.fromMap(b)).toList();
      
      // Sync Orders for existing UI
      _orders = _bookings.map((booking) => Order(
        id: booking.id,
        customerId: booking.customerId,
        customerName: booking.customerName ?? 'Guest',
        customerPhone: booking.customerPhone ?? '',
        items: [
          OrderItem(
            productId: booking.productId,
            product: booking.product,
            quantity: booking.quantity,
            price: booking.product?.price ?? 0.0,
          )
        ],
        totalAmount: (booking.product?.price ?? 0.0) * booking.quantity,
        status: booking.status,
        paymentMethod: 'COD',
        shippingAddress: 'استلام من المتجر',
        createdAt: booking.createdAt,
      )).toList();
      
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
    } finally {
      if (!silently) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> fetchOrders() async {
    await fetchBookings();
  }

  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    if (_token == null) return false;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      // Map Order request to Booking request as agreed
      final productId = orderData['product_id'];
      if (productId == null) return false;
      
      final response = await _apiService.createBooking(
        int.parse(productId.toString()), 
        orderData['notes'] ?? 'طلب عبر نظام الشراء المباشر'
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchBookings();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Create order (via Booking) error: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }


  // void logout() merged into async version above

  Future<void> performLogout() async {
    if (_token != null) {
      try {
        await _apiService.logout();
      } catch (e) {
        debugPrint('Logout error (ignoring): $e');
      }
    }
    logout(); // Clear local state regardless of API success
  }

  Future<bool> deleteAccount() async {
    if (_token == null) return false;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _apiService.deleteAccount();
      logout(); // Clear local state on success
      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      if (e is DioException && e.response != null) {
         _lastError = e.response?.data['message'] ?? 'فشل حذف الحساب';
      }
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchGoldPrices({bool silently = false}) async {
    try {
      final response = await _apiService.getGoldPrices();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List prices = data['prices'] ?? [];
        
        final rawOunce = data['meta']?['global_ounce_price_usd'];
        if (rawOunce != null && (double.tryParse(rawOunce.toString()) ?? 0) > 0) {
          _basePriceOunceUSD = double.tryParse(rawOunce.toString());
          _isServerConnected = true;
        } else {
          _isServerConnected = false;
        }
        
        // Update exchange rates from server
        final rates = data['meta']?['exchange_rates'] ?? {};
        rates.forEach((key, value) {
          _currencyRates[key] = double.tryParse(value.toString()) ?? _currencyRates[key] ?? 1.0;
        });

        // Update carat-specific prices from backend
        for (var p in prices) {
           final purity = int.tryParse(p['purity'].toString()) ?? 0;
           final price = double.tryParse(p['price_per_gram_usd'].toString()) ?? 0.0;
           if (purity > 0 && price > 0) {
             _caratPricesUSD[purity] = price;
           }
        }

        if (!silently) _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching gold prices: $e');
      _isServerConnected = false;
      if (!silently) _safeNotifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      // Load from cache first
      final cacheBox = Hive.box('cache');
      final cachedData = cacheBox.get('categories');
      if (cachedData != null && cachedData is List) {
        _categories = cachedData;
        _safeNotifyListeners();
      }

      final response = await _apiService.getCategories();
      if (response.statusCode == 200) {
        _categories = response.data['data'] ?? response.data;
        // Save to cache
        cacheBox.put('categories', _categories);
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchMerchants() async {
    try {
      final response = await _apiService.getMerchants();
      _merchants = response.data['data'] ?? [];
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error fetching merchants: $e');
    }
  }

  Future<bool> updateBookingStatus(String bookingId, String status, {String? reason}) async {
    if (_token == null) return false;
    _lastError = null;
    try {
      await _apiService.updateBookingStatus(bookingId, status, reason);
      await fetchBookings(); // Refresh list after update
      return true;
    } on DioException catch (e) {
      debugPrint('Update booking status DioError: ${e.response?.statusCode} | ${e.response?.data}');
      final responseData = e.response?.data;
      if (responseData != null) {
        if (responseData['message'] != null) {
          _lastError = responseData['message'].toString();
        } else if (responseData['errors'] != null) {
          final errors = responseData['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstVal = errors.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              _lastError = firstVal.first.toString();
            } else {
              _lastError = firstVal.toString();
            }
          }
        }
      }
      _lastError ??= 'error_occurred'.tr();
      _safeNotifyListeners();
      return false;
    } catch (e) {
      debugPrint('Update booking status error: $e');
      _lastError = 'error_occurred'.tr();
      _safeNotifyListeners();
      return false;
    }
  }
  
  // notifications and banners moved to top

  Future<void> fetchBanners({String? placement, String? target, bool silently = false}) async {
    try {
      final String placementKey = placement ?? 'all';
      
      // Load from cache first
      final cacheBox = Hive.box('cache');
      final Map<String, dynamic> cachedMap = Map<String, dynamic>.from(cacheBox.get('banners_map') ?? {});
      if (cachedMap.containsKey(placementKey)) {
        _bannersByPlacement[placementKey] = List<dynamic>.from(cachedMap[placementKey]);
        if (!silently) _safeNotifyListeners();
      }

      final Map<String, dynamic> params = {};
      if (placement != null) params['placement'] = placement;
      if (target != null) {
        params['target'] = target;
      } else if (_currentUser != null) params['target'] = _currentUser!.type;

      final response = await _apiService.getBanners(params: params);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedBanners = response.data['data'] ?? [];
        _bannersByPlacement[placementKey] = fetchedBanners;
        
        // Update cache
        cachedMap[placementKey] = fetchedBanners;
        cacheBox.put('banners_map', cachedMap);
        
        if (!silently) _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching banners: $e');
    }
  }

  List<dynamic> getBannersByPlacement(String placement) {
    return _bannersByPlacement[placement] ?? [];
  }


  Future<bool> addProduct(Map<String, dynamic> data) async {
    if (_token == null) return false;
    _isLoading = true;
    _lastError = null;
    _safeNotifyListeners();
    try {
      await _apiService.addProduct(data);
      await fetchMerchantProducts(); // Refresh merchant product list specifically
      return true;
    } catch (e) {
      if (e is DioException) {
        debugPrint('Add product error: ${e.response?.data}');
        final responseData = e.response?.data;
        
        // Handle Laravel validation errors (errors object)
        if (e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
           _lastError = 'استغرق رفع الصور وقتاً أطول من المعتاد. يرجى التحقق من جودة الاتصال بالإنترنت.';
        } else if (responseData != null && responseData['errors'] != null) {
          final Map<String, dynamic> errors = responseData['errors'];
          if (errors.isNotEmpty) {
             final firstError = errors.values.first;
             if (firstError is List && firstError.isNotEmpty) {
               _lastError = firstError.first.toString();
             } else {
               _lastError = firstError.toString();
             }
          }
        } 
        // Handle direct status message or error key
        else if (responseData != null && responseData['message'] != null) {
           _lastError = responseData['message'];
        } else if (responseData != null && responseData['data'] is Map && responseData['data'].containsKey('errors')) {
           // Alternative structure sometimes used in our ApiResponse trait
           final Map<String, dynamic> errors = responseData['data']['errors'];
           if (errors.isNotEmpty) {
             final firstError = errors.values.first;
             _lastError = (firstError is List && firstError.isNotEmpty) ? firstError.first.toString() : firstError.toString();
           }
        } else {
           _lastError = 'فشل إضافة المنتج: ${e.message}';
        }
      } else {
        debugPrint('Add product error: $e');
        _lastError = 'حدث خطأ غير متوقع';
      }
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> reportContent(String type, String id, String reason) async {
    if (_token == null) return false;
    try {
      await _apiService.reportContent(type, id, reason);
      return true;
    } catch (e) {
      debugPrint('Report error: $e');
      return false;
    }
  }

  Future<void> fetchNotifications({bool silently = false}) async {
    if (_token == null) return;
    if (!silently) {
      _isLoading = true;
      _safeNotifyListeners();
    }
    try {
      final response = await _apiService.getNotifications();
      if (response.statusCode == 200) {
        _notifications = List<dynamic>.from(response.data['data']);
        
        // Update unread count based on read_at being null
        _unreadNotificationsCount = _notifications.where((n) => n['read_at'] == null).length;
        
        if (!silently) _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch notifications error: $e');
    } finally {
      if (!silently) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<bool> markNotificationRead(String id) async {
    if (_token == null) return false;
    try {
      // Optmistically update local state
      final index = _notifications.indexWhere((n) => n['id'].toString() == id);
      if (index != -1 && _notifications[index]['read_at'] == null) {
        _notifications[index]['read_at'] = DateTime.now().toIso8601String();
        if (_unreadNotificationsCount > 0) _unreadNotificationsCount--;
        _safeNotifyListeners();
      }

      await _apiService.markNotificationRead(id);
      return true;
    } catch (e) {
      debugPrint('Mark read error: $e');
      // On error, we could revert but usually a refresh fixes it
      fetchNotifications(silently: true);
    }
    return false;
  }

  Future<bool> markAllNotificationsRead() async {
    if (_token == null) return false;
    try {
      await _apiService.markAllNotificationsRead();
      for (var n in _notifications) {
        n['read_at'] = DateTime.now().toIso8601String();
      }
      _unreadNotificationsCount = 0;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Mark all read error: $e');
    }
    return false;
  }
  
  Future<void> markBookingNotificationsRead() async {
    if (_token == null) return;
    
    // 1. Identify booking-related unread notifications
    final bookingNotifyIds = _notifications.where((n) => 
      n['read_at'] == null && 
      n['data'] != null && 
      (n['data']['type'] == 'booking_status' || n['data']['type'] == 'custom_design_status')
    ).map((n) => n['id'].toString()).toList();
    
    if (bookingNotifyIds.isEmpty) return;
    
    try {
      // For speed and matching "disappear" behavior, we loop through and mark
      for (var id in bookingNotifyIds) {
        await _apiService.markNotificationRead(id);
        
        final index = _notifications.indexWhere((n) => n['id'].toString() == id);
        if (index != -1) {
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
        }
      }
      
      // Update the main unread count
      _unreadNotificationsCount = _notifications.where((n) => n['read_at'] == null).length;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Mark booking updates read error: $e');
    }
  }

  Future<void> fetchMerchantAnalytics() async {
    if (_token == null) return;
    try {
      final response = await _apiService.getMerchantAnalytics();
      if (response.statusCode == 200) {
        _merchantAnalytics = response.data['data'];
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch analytics error: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await LocalizationService.load(locale.languageCode);
    _safeNotifyListeners();
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    if (_token == null) return false;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _apiService.createCategory(data);
      await fetchCategories();
      _isLoading = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('Create category error: $e');
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    if (_token == null) return false;
    try {
      await _apiService.deleteCategory(id);
      await fetchCategories();
      return true;
    } catch (e) {
      debugPrint('Delete category error: $e');
      return false;
    }
  }

  Future<bool> deleteAllCategories() async {
    if (_token == null) return false;
    try {
      await _apiService.deleteAllCategories();
      await fetchCategories();
      return true;
    } catch (e) {
      debugPrint('Delete all categories error: $e');
      return false;
    }
  }

  Future<void> checkVerificationStatus() async {
    if (_token == null || _currentUser?.type != 'merchant') return;
    try {
      final response = await _apiService.getVerificationStatus();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        _currentUser = User(
          id: _currentUser!.id,
          name: _currentUser!.name,
          phone: _currentUser!.phone,
          email: _currentUser!.email,
          type: _currentUser!.type,
          profileImage: _currentUser!.profileImage,
          isVerified: data['is_verified'],
          verificationStatus: data['status'],
          rejectionReason: data['rejection_reason'],
          merchantId: data['merchant_id']?.toString() ?? _currentUser!.merchantId,
        );
        _verificationDocuments = data['documents'] ?? [];
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Check verification error: $e');
    }
  }

  Future<bool> uploadVerificationDocument(String filePath, String type) async {
    if (_token == null) return false;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _apiService.uploadVerificationDocument(filePath, type);
      await checkVerificationStatus();
      return true;
    } catch (e) {
      debugPrint('Upload verification error: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> uploadVerificationDocumentBytes(Uint8List bytes, String filename, String type) async {
    if (_token == null) return false;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      await _apiService.uploadVerificationDocumentBytes(bytes, filename, type);
      await checkVerificationStatus();
      return true;
    } catch (e) {
      debugPrint('Upload verification error: $e');
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void updateGoldPrice(double price) {
    _basePriceOunceUSD = price;
    _safeNotifyListeners();
  }

  void setSelectedKarat(int karat) {
    _selectedKarat = karat;
    _selectedUnit = 'عيار $karat';
    _safeNotifyListeners();
  }

  void setSelectedCurrency(String currency) {
    _selectedCurrency = currency;
    _safeNotifyListeners();
  }

  void setSelectedUnit(String unit) {
    _selectedUnit = unit;
    if (unit.startsWith('K') || unit.contains('عيار')) {
      _selectedKarat = int.tryParse(unit.replaceAll(RegExp(r'[^0-9]'), '')) ?? 21;
    }
    _safeNotifyListeners();
  }

  Future<bool> submitCustomDesign(Map<String, dynamic> data) async {
    if (_token == null) return false;
    try {
      await _apiService.createCustomDesign(data);
      fetchCustomerCustomDesigns(); // Refresh list after submission
      return true;
    } catch (e) {
      debugPrint('Submit custom design error: $e');
      return false;
    }
  }

  Future<void> fetchCustomerCustomDesigns({bool silently = false}) async {
    if (_token == null) return;
    if (!silently) _isLoading = true;
    _safeNotifyListeners();
    try {
      final response = await _apiService.getCustomDesigns();
      final rawData = response.data['data'];
      List rawList;
      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        rawList = rawData['data'] as List? ?? [];
      } else {
        rawList = [];
      }
      _customerCustomDesigns = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
      debugPrint('Fetched ${_customerCustomDesigns.length} custom designs for customer');
    } catch (e) {
      debugPrint('Error fetching customer custom designs: $e');
    } finally {
      if (!silently) _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchMerchantCustomDesigns({bool silently = false}) async {
    if (_token == null) return;
    if (!silently) _isLoading = true;
    _safeNotifyListeners();
    try {
      final response = await _apiService.getMerchantCustomDesigns();
      final rawData = response.data['data'];
      List rawList;
      if (rawData is List) {
        // Flat list response
        rawList = rawData;
      } else if (rawData is Map && rawData.containsKey('data')) {
        // Paginated response
        rawList = rawData['data'] as List? ?? [];
      } else {
        rawList = [];
      }
      _merchantCustomDesigns = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
      debugPrint('Fetched ${_merchantCustomDesigns.length} custom designs for merchant');
    } catch (e) {
      debugPrint('Error fetching merchant custom designs: $e');
    } finally {
      if (!silently) _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> updateCustomDesignStatus(String id, String status) async {
    if (_token == null) return false;
    try {
      await _apiService.updateCustomDesignStatus(id, status);
      await fetchMerchantCustomDesigns();
      return true;
    } catch (e) {
      debugPrint('Update custom design status error: $e');
      return false;
    }
  }

  void setShowGramPrice(bool value) {
    _showGramPrice = value;
    _safeNotifyListeners();
  }

  // ── WebSocket Connectivity ──────────────────────────────────
  void _initSocket() {
    if (_token == null || _currentUser == null) return;
    
    // Dispose existing if any
    _disposeSocket();

    _socketService = NotificationSocketService(
      userId: _currentUser!.id,
      authToken: _token!,
      onNotification: (data) {
        debugPrint('Real-time notification received: $data');
        _notifications.insert(0, data);
        
        // Refresh bookings/orders if it's a booking update
        final type = data['type']?.toString();
        if (type == 'booking_new' || type == 'booking_status') {
          _hasNewBookings = true;
          fetchBookings(silently: true);
        } else if (type == 'custom_design_new') {
          fetchMerchantCustomDesigns();
        }

        // Trigger visual feedback (Snackbar) with dynamic payload
        _unreadNotificationsCount++;
        
        // ذكاء اصطناعي لاستخراج النص: نبحث في الرسالة، العنوان، أو داخل الـ payload بصورة شاملة
        final payload = data['payload'] is Map ? data['payload'] : data;
        String notificationText = payload['message']?.toString() ?? 
                                 payload['body']?.toString() ?? 
                                 payload['text']?.toString() ?? 
                                 payload['title']?.toString() ?? 
                                 data['message']?.toString() ??
                                 'notification_new'.tr();

        debugPrint('[SUCCESS] Real-time Notification Event Captured: $notificationText');
        
        // إظهار إشعار علوي مخصص (Top Overlay) بدلاً من الأسفل
        _showTopNotification(notificationText);

        _safeNotifyListeners();
      },
      onGoldPriceUpdate: (data) {
        debugPrint('Real-time gold price update: $data');
        if (data.containsKey('prices')) {
          final prices = data['prices'] as Map<String, dynamic>;
          prices.forEach((karat, price) {
             _caratPricesUSD[int.tryParse(karat) ?? 0] = (price as num).toDouble();
          });
        }
        
        if (data.containsKey('ounce_price')) {
          _basePriceOunceUSD = (data['ounce_price'] as num).toDouble();
        }
        
        _safeNotifyListeners();
      },
      onSyncData: (data) {
        debugPrint('[WS] Background Sync trigger received: $data');
        final model = data['model']?.toString();
        // Since we want this completely invisible, we fetch silently
        if (model == 'product') {
          if (_currentUser?.type == 'merchant') {
            fetchMerchantProducts(silently: true);
            fetchMerchantAnalytics();
          } else {
            fetchProducts(isRefresh: true, silently: true);
          }
        } else if (model == 'booking') {
          fetchBookings(silently: true);
          if (_currentUser?.type == 'merchant') {
            fetchMerchantAnalytics();
          }
        } else if (model == 'custom_design') {
          if (_currentUser?.type == 'customer') {
            fetchCustomerCustomDesigns();
          } else {
            fetchMerchantCustomDesigns();
          }
        }
      },
      onConnected: () {
        debugPrint('WebSocket connected');
        // Subscribe to user-specific private channel
        _socketService?.subscribe('private-user.${_currentUser!.id}');
        // Subscribe to global gold price channel
        _socketService?.subscribe('gold-prices');
        // Subscribe to global sync events
        _socketService?.subscribe('public.sync');
        // Subscribe to global broadcasts (for testing and general alerts)
        _socketService?.subscribe('public.broadcasts');
      },
      onDisconnected: () {
        debugPrint('WebSocket disconnected');
      },
    );
    
    _socketService!.connect();
  }

  void _disposeSocket() {
    _socketService?.disconnect();
    _socketService = null;
  }

  // --- REVIEWS LOGIC ---

  Future<void> fetchProductReviews(String productId) async {
    _isLoadingReviews = true;
    _safeNotifyListeners();

    try {
      final response = await _apiService.getProductReviews(productId);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        _productReviews[productId] = data.map((json) => Review.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
    } finally {
      _isLoadingReviews = false;
      _safeNotifyListeners();
    }
  }

  Future<void> fetchExchangeRates({bool silently = false}) async {
    if (!silently) {
      _isLoadingSettings = true;
      _safeNotifyListeners();
    }
    try {
      final response = await _apiService.getExchangeRates();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        // The backend returns:
        // 'USD' => usd_to_yer (e.g. 530)
        // 'SAR' => sar_to_yer (e.g. 141)
        _currencyRates['YER'] = (data['USD'] as num).toDouble(); 
        _currencyRates['SAR'] = (data['SAR'] as num).toDouble() / (data['USD'] as num).toDouble(); 
        // Wait, the app uses _currencyRates where 1.0 is USD (base).
        // If _selectedCurrency is YER, it returns _currencyRates['YER'] which is 530.
        // If _selectedCurrency is SAR, it returns _currencyRates['SAR'] which should be ?
        
        // Let's check goldPrice calculation logic in AppState:
        // double rate = _currencyRates[_selectedCurrency] ?? 1.0;
        // return karatPriceUSD * rate;
        
        // So:
        // YER rate should be: USD_TO_YER (e.g. 530)
        // SAR rate should be: USD_TO_SAR (e.g. 3.75)
        
        _currencyRates['YER'] = (data['USD'] as num).toDouble();
        _currencyRates['SAR'] = (data['USD_TO_SAR'] as num).toDouble();
        
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');
    } finally {
      if (!silently) {
        _isLoadingSettings = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<bool> addProductReview(String productId, double rating, String comment) async {
    if (_token == null) return false;

    try {
      final response = await _apiService.submitReview(productId, rating, comment);
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh reviews locally
        await fetchProductReviews(productId);
        return true;
      }
    } catch (e) {
      debugPrint('Error adding review: $e');
    }
    return false;
  }

  // --- DEEP LINKING ---
  void _initDeepLinks() {
    // Handle initial link if app was closed
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // Handle incoming links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep Link Error: $err');
    });
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('Handling deep link: $uri');
    
    // Patterns: 
    // mojowharati://product/123
    // https://mojowharati-app.web.app/product/123
    
    String? productId;
    
    if (uri.scheme == 'mojowharati' && uri.host == 'product') {
       productId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.scheme == 'https' && uri.host == 'mojowharati-app.web.app') {
       if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'product') {
          productId = uri.pathSegments[1];
       }
    }

    if (productId != null) {
      debugPrint('Deep link productId: $productId');
      
      // Check if product is already in our list
      Product? product;
      try {
        product = _products.firstWhere((p) => p.id == productId);
      } catch (_) {
        // Not in list, fetch from API
        try {
          final response = await _apiService.getProduct(productId);
          if (response.data != null && response.data['data'] != null) {
            product = Product.fromJson(response.data['data']);
          }
        } catch (e) {
          debugPrint('Error fetching product from deep link: $e');
        }
      }

      if (product != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product!),
          ),
        );
      }
    }
  }

  void _showTopNotification(String text) {
    debugPrint('[UI] Attempting to show Top Overlay Notification');
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('[ERROR] Overlay is null, cannot show notification');
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        text: text,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
    
    // إزالة الإشعار تلقائياً بعد 4 ثوانٍ
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String text;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({required this.text, required this.onDismiss});

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFC5A028)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 28),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Almarai',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: widget.onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

