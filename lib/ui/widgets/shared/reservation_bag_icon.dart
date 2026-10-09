import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../config/colors.dart';
import '../../../state/cart_state.dart';
import '../../screens/customer/cart_screen.dart';
import '../../../utils/localization_service.dart';

class ReservationBagIcon extends StatelessWidget {
  final bool isDark;
  final Color? iconColor;

  const ReservationBagIcon({
    super.key, 
    required this.isDark,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final itemCount = cart.items.length;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
      child: Tooltip(
        message: 'reservation_bag'.tr(),
        textStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined, 
                color: iconColor ?? AppColors.primaryGold, 
                size: 20
              ),
              if (itemCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
