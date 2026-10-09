import '../config/constants.dart';

class MerchantData {
  final String id;
  final String storeName;
  final String whatsapp;
  final String? contactNumber;
  final String address;
  final String? logo;

  MerchantData({
    required this.id,
    required this.storeName,
    required this.whatsapp,
    this.contactNumber,
    required this.address,
    this.logo,
  });

  factory MerchantData.fromMap(Map<String, dynamic> map) {
    return MerchantData(
      id: map['id'].toString(),
      storeName: map['store_name'] ?? '',
      whatsapp: map['whatsapp_number'] ?? '',
      contactNumber: map['contact_number'],
      address: map['address'] ?? '',
      logo: map['logo_url'] ?? map['logo'],
    );
  }

  static String sanitizeUrl(String url) {
    if (url.isEmpty) return url;
    
    // If it's already a full external URL (like ImgBB), keep it
    if (url.startsWith('http')) {
      // Resilience check: If the URL contains a local IP or localhost, Replace it with the production API Base URL
      if (url.contains('192.168.') || url.contains('10.0.2.2') || url.contains('localhost') || url.contains('127.0.0.1') || url.contains('172.')) {
        try {
          final uri = Uri.parse(url);
          final prodUri = Uri.parse(AppConstants.apiBaseUrl);
          // Only replace the host/port part (if local), keep the path and query
          return uri.replace(
            scheme: prodUri.scheme,
            host: prodUri.host,
            port: prodUri.port != 80 && prodUri.port != 443 ? prodUri.port : null,
          ).toString();
        } catch (e) {
          return url;
        }
      }
      return url;
    }
    
    // Handle relative paths
    final cleanPath = url.startsWith('/') ? url : '/$url';
    if (cleanPath.contains('/storage/')) {
      return "${AppConstants.apiBaseUrl}$cleanPath";
    }
    return "${AppConstants.storageUrl}$cleanPath";
  }

  String get logoUrl => sanitizeUrl(logo ?? '');
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double weight;
  final String materialName;
  final String categoryId;
  final MerchantData? merchant;
  final List<String> images;
  final bool isFeatured;
  final bool isPromoted;
  final String? purity;
  final double workmanship; // Workmanship per gram
  final int stockQuantity;
  final int availableStock;
  final bool manageStock;
  final String currency;
  final String materialType; // gold, silver, gemstone
  final String? stoneType;
  final String? clarity;
  final String? cut;
  final double? stoneWeight;
  final double averageRating;
  final int reviewsCount;
  final int viewsCount;
  
  String get mainImageUrl {
    if (images.isEmpty) return "";
    return MerchantData.sanitizeUrl(images.first);
  }

  String get category => categoryId;
  String get karat => purity ?? '21';
  String get currencySymbol {
    switch (currency) {
      case 'USD': return '\$';
      case 'SAR': return 'ر.س';
      case 'YER': return 'ر.ي';
      default: return 'ر.ي';
    }
  }

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.weight,
    required this.materialName,
    required this.categoryId,
    this.merchant,
    required this.images,
    this.isFeatured = false,
    this.isPromoted = false,
    this.purity,
    this.workmanship = 0.0,
    this.stockQuantity = 0,
    this.availableStock = 0,
    this.manageStock = false,
    this.currency = 'YER',
    this.materialType = 'gold',
    this.stoneType,
    this.clarity,
    this.cut,
    this.stoneWeight,
    this.averageRating = 5.0,
    this.reviewsCount = 0,
    this.viewsCount = 0,
  });

  factory Product.fromJson(Map<String, dynamic> map) {
    int stock = int.tryParse(map['stock_quantity']?.toString() ?? '0') ?? 0;
    return Product(
      id: map['id'].toString(),
      name: map['name'] ?? map['title'] ?? '',
      description: map['description'] ?? '',
      price: double.tryParse(map['price']?.toString() ?? map['final_price']?.toString() ?? '0') ?? 0.0,
      weight: double.tryParse(map['weight']?.toString() ?? '0') ?? 0.0,
      materialName: (map['material'] != null) ? map['material']['name'] : 'ذهب',
      categoryId: map['category_id']?.toString() ?? '',
      merchant: (map['merchant'] != null) ? MerchantData.fromMap(map['merchant']) : null,
      images: _parseImages(map),
      isFeatured: map['is_featured'] == 1 || map['is_featured'] == true,
      isPromoted: map['is_promoted'] == 1 || map['is_promoted'] == true,
      purity: map['purity'],
      workmanship: double.tryParse(map['workmanship']?.toString() ?? '0') ?? 0.0,
      stockQuantity: stock,
      availableStock: int.tryParse(map['available_stock']?.toString() ?? '') ?? stock,
      manageStock: map['manage_stock'] == 1 || map['manage_stock'] == true,
      currency: map['currency']?.toString() ?? 'YER',
      materialType: map['material_type']?.toString() ?? 'gold',
      stoneType: map['stone_type']?.toString(),
      clarity: map['clarity']?.toString(),
      cut: map['cut']?.toString(),
      stoneWeight: double.tryParse(map['stone_weight']?.toString() ?? ''),
      averageRating: double.tryParse(map['average_rating']?.toString() ?? '5.0') ?? 5.0,
      reviewsCount: int.tryParse(map['reviews_count']?.toString() ?? '0') ?? 0,
      viewsCount: int.tryParse(map['views_count']?.toString() ?? '0') ?? 0,
    );
  }

  static List<String> _parseImages(Map<String, dynamic> map) {
    List<String> rawImages = [];
    if (map['images'] != null && map['images'] is List) {
      final list = map['images'] as List;
      if (list.isNotEmpty) {
        if (list[0] is String) {
          rawImages = list.map((e) => e.toString()).toList();
        } else {
          rawImages = list.map((i) {
            if (i is Map) {
              return i['url']?.toString() 
                  ?? i['path']?.toString() 
                  ?? i['image_path']?.toString() 
                  ?? i['image_url']?.toString() 
                  ?? '';
            }
            return i.toString();
          }).where((s) => s.isNotEmpty).toList();
        }
      }
    }
    
    // Fallbacks if eager loaded images missing
    if (rawImages.isEmpty) {
      final fallback = map['main_image_url']?.toString() 
          ?? map['image_url']?.toString() 
          ?? map['image']?.toString() 
          ?? map['main_image']?.toString();
      if (fallback != null && fallback.isNotEmpty) {
        rawImages = [fallback];
      }
    }

    return rawImages.map((img) => MerchantData.sanitizeUrl(img)).where((s) => s.isNotEmpty).toList();
  }

  // Maintaining legacy fromMap for compatibility if needed
  factory Product.fromMap(Map<String, dynamic> map) => Product.fromJson(map);
}
