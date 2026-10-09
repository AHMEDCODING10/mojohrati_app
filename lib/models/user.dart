class User {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String type; // 'customer' or 'merchant'
  final String profileImage;
  final bool isVerified;
  final String verificationStatus;
  final String? rejectionReason;
  final String? merchantId;
  final String? storeName;
  final String? storeLogo;
  final String? storeBanner;
  final String? whatsapp;
  final String? instagram;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.type,
    required this.profileImage,
    this.isVerified = false,
    this.verificationStatus = 'not_submitted',
    this.rejectionReason,
    this.merchantId,
    this.storeName,
    this.storeLogo,
    this.storeBanner,
    this.whatsapp,
    this.instagram,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      type: json['role'] ?? 'customer',
      profileImage: (json['image'] != null && json['image'].toString().isNotEmpty) 
          ? json['image'] 
          : 'https://ui-avatars.com/api/?name=${json['name'] ?? 'User'}&background=random',
      isVerified: json['is_verified'] ?? false,
      verificationStatus: json['verification_status'] ?? json['status'] ?? 'not_submitted',
      rejectionReason: json['rejection_reason'] ?? json['approval_notes'],
      merchantId: json['merchant'] != null ? json['merchant']['id'].toString() : json['merchant_id']?.toString(),
      storeName: json['merchant'] != null ? json['merchant']['store_name'] : json['store_name'],
      storeLogo: json['merchant'] != null ? json['merchant']['logo'] : json['store_logo'],
      storeBanner: json['merchant'] != null ? json['merchant']['banner'] : json['store_banner'],
      whatsapp: json['merchant'] != null ? json['merchant']['whatsapp'] : json['whatsapp'],
      instagram: json['merchant'] != null ? json['merchant']['instagram'] : json['instagram'],
    );
  }
}
