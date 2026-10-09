import 'product.dart';

class Booking {
  final String id;
  final String customerId;
  final String productId;
  final Product? product;
  final String status; // 'pending', 'confirmed', 'rejected', 'completed'
  final int quantity;
  final String? customerNotes;
  final String? rejectionReason;
  final DateTime createdAt;

  final String? customerName;
  final String? customerPhone;

  Booking({
    required this.id,
    required this.customerId,
    required this.productId,
    this.product,
    required this.status,
    this.quantity = 1,
    this.customerNotes,
    this.rejectionReason,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'].toString(),
      customerId: map['customer_id'].toString(),
      productId: map['product_id'].toString(),
      product: map['product'] != null ? Product.fromMap(map['product']) : null,
      status: map['status'] ?? 'pending',
      quantity: int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      customerNotes: map['customer_notes'],
      rejectionReason: map['rejection_reason'],
      createdAt: DateTime.parse(map['created_at']),
      customerName: map['customer']?['name'],
      customerPhone: map['customer']?['phone'],
    );
  }
}
