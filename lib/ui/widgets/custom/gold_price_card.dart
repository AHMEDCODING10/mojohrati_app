import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../state/app_state.dart';
import '../../../../config/colors.dart';
import '../../../../config/constants.dart';
import '../../../../utils/localization_service.dart';

class GoldPriceCard extends StatefulWidget {
  const GoldPriceCard({super.key});

  @override
  State<GoldPriceCard> createState() => _GoldPriceCardState();
}

class _GoldPriceCardState extends State<GoldPriceCard> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentPrice = appState.goldPrice;
    final selectedKarat = appState.selectedKarat;


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.liquidGold,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'gold_price_today'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    'live_update'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.show_chart, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${currentPrice.toStringAsFixed(2)} ${AppConstants.currency} / ${appState.selectedUnit == 'أوقية' ? 'ounce'.tr() : 'gram'.tr()}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [24, 22, 21, 18].map((karat) {
              final isSelected = selectedKarat == karat;
              return GestureDetector(
                onTap: () => appState.setSelectedKarat(karat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: isSelected ? 0.5 : 0.1)),
                  ),
                  child: Text(
                    '${'karat'.tr()} $karat',
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryGold : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
