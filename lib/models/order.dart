import 'product.dart';

class Order {
  final String id;
  final String customerId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'confirmed', 'shipped', 'delivered', 'canceled'
  final String paymentMethod; // Always 'COD' for now
  final String shippingAddress;
  final String? addressNote;
  final String customerName;
  final String customerPhone;
  final DateTime createdAt;

  double get totalPrice => totalAmount;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    this.addressNote,
    required this.customerPhone,
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'].toString(),
      customerId: map['customer_id'].toString(),
      customerName: map['customer_name'] ?? 'جاري التحميل...',
      items: (map['items'] as List).map((i) => OrderItem.fromMap(i)).toList(),
      totalAmount: double.parse(map['total_amount'].toString()),
      status: map['status'] ?? 'pending',
      paymentMethod: map['payment_method'] ?? 'COD',
      shippingAddress: map['shipping_address'] ?? '',
      addressNote: map['address_note'],
      customerPhone: map['customer_phone'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class OrderItem {
  final String productId;
  final Product? product;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    this.product,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['product_id'].toString(),
      product: map['product'] != null ? Product.fromMap(map['product']) : null,
      quantity: int.parse(map['quantity'].toString()),
      price: double.parse(map['price'].toString()),
    );
  }
}
