class Review {
  final String id;
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      userName: json['user_name'] ?? json['user']?['name'] ?? 'User',
      userImage: json['user_image'] ?? json['user']?['avatar_url'],
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
