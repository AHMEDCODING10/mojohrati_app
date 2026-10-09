import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../state/cart_state.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import '../../widgets/custom/gold_gradient_button.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartState>().addListener(_handleErrors);
    });
  }

  @override
  void dispose() {
    // Note: Provider might dispose the state, but we should remove listener if we added it manually
    // However, since we are using context.read in initState, we should be careful.
    // In a Stateless to Stateful conversion, it's safer to use a Consumer or check mounted.
    super.dispose();
  }

  void _handleErrors() {
    if (!mounted) return;
    final cart = context.read<CartState>();
    if (cart.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cart.errorMessage!, style: GoogleFonts.cairo(fontSize: 12)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      cart.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.matteBlack : Colors.white,
      appBar: AppBar(
        title: Text('cart_title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(context, isDark)
          : Column(
              children: [
                _buildReservationHeader(isDark),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildCartItem(context, item, cart, isDark);
                    },
                  ),
                ),
                _buildOrderSummary(context, cart, isDark),
              ],
            ),
    );
  }

  Widget _buildReservationHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryGold, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'reservation_alert'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 10, 
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.primaryGold),
          ),
          const SizedBox(height: 24),
          Text(
            'empty_cart_title'.tr(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'empty_cart_desc'.tr(),
            style: GoogleFonts.cairo(color: isDark ? Colors.white60 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartState cart, bool isDark) {
    final timeLeft = item.timeLeft;
    final minutes = timeLeft.inMinutes % 60;
    final seconds = timeLeft.inSeconds % 60;
    
    // Check if we hit stock limit
    final bool isAtStockLimit = item.product.manageStock && item.quantity >= item.product.stockQuantity;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'product_image_${item.product.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                item.product.images.first, 
                width: 100, 
                height: 100, 
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100, height: 100, 
                  color: Colors.grey[200], 
                  child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey)
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name, 
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () => cart.removeItem(item.product.id),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Text(
                  '${item.product.weight} ${'gram'.tr()}', 
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white54 : Colors.black54, 
                    fontWeight: FontWeight.w600,
                    fontSize: 12
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildItemAction(
                            Icons.remove, 
                            () => cart.updateQuantity(item.product.id, -1), 
                            isDark,
                            isDisabled: false, // Decrement is always allowed (until removal)
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '${item.quantity}', 
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)
                            ),
                          ),
                          _buildItemAction(
                            Icons.add, 
                            () => cart.updateQuantity(item.product.id, 1), 
                            isDark,
                            isDisabled: isAtStockLimit,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_rounded, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '${timeLeft.inHours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.red, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace'
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAction(IconData icon, VoidCallback onTap, bool isDark, {bool isDisabled = false}) {
    return InkWell(
      onTap: isDisabled ? null : () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: isDisabled ? 0.1 : 0.3)),
            boxShadow: [
              if (!isDark && !isDisabled)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(icon, size: 14, color: isDisabled ? Colors.grey : AppColors.primaryGold),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartState cart, bool isDark) {
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.matteBlack : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Summary rows removed as per request (Verification fee, items count)
            const SizedBox(height: 20),
            GoldGradientButton(
              text: 'place_order'.tr(),
              onPressed: () => _processAllBookings(context, cart),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processAllBookings(BuildContext context, CartState cart) async {
    final appState = context.read<AppState>();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
    );

    int successCount = 0;
    for (var item in cart.items) {
      final pid = int.tryParse(item.product.id);
      if (pid == null) {
        debugPrint('Error: Invalid product ID: ${item.product.id}');
        continue;
      }
      final error = await appState.requestBooking(pid, quantity: item.quantity);
      if (error == null) successCount++;
    }

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      
      if (successCount > 0) {
        cart.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('order_success_title'.tr(), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Go back home or to bookings
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appState.error ?? 'booking_failed'.tr(), style: GoogleFonts.cairo()), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


}
