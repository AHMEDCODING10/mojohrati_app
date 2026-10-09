import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  final DateTime expiresAt;

  CartItem({
    required this.product, 
    this.quantity = 1,
    required this.expiresAt,
  });

  Duration get timeLeft => expiresAt.difference(DateTime.now());
  bool get isExpired => timeLeft.isNegative;
}

class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];
  Timer? _timer;
  String? _errorMessage;

  CartState() {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool changed = false;
      _items.removeWhere((item) {
        if (item.isExpired) {
          changed = true;
          return true;
        }
        return false;
      });
      if (changed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<CartItem> get items => _items;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  double get subtotal => _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get total => subtotal; // Removing fixed delivery fee for reservations

  void addItem(Product product) {
    if (product.manageStock && product.stockQuantity <= 0) {
      _errorMessage = 'عذراً، هذا المنتج غير متوفر حالياً';
      notifyListeners();
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      if (product.manageStock && _items[index].quantity >= product.stockQuantity) {
        _errorMessage = 'لقد وصلت للحد الأقصى للكمية المتوفرة لهذا المنتج';
      } else {
        _items[index].quantity++;
      }
    } else {
      _items.add(CartItem(
        product: product, 
        expiresAt: DateTime.now().add(const Duration(hours: 24)), // 24 hour reservation
      ));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int delta) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      final item = _items[index];
      final newQuantity = item.quantity + delta;

      if (delta > 0) {
        // Checking for stock increase
        if (item.product.manageStock && item.quantity >= item.product.stockQuantity) {
          _errorMessage = 'لا يمكن إضافة المزيد، الكمية المتوفرة هي ${item.product.stockQuantity} فقط';
          notifyListeners();
          return;
        }
      }

      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        item.quantity = newQuantity;
      }
      
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
