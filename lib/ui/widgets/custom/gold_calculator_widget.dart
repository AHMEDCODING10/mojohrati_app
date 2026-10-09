import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';

class GoldCalculatorWidget extends StatefulWidget {
  final bool isMerchant;
  const GoldCalculatorWidget({super.key, this.isMerchant = false});

  @override
  State<GoldCalculatorWidget> createState() => _GoldCalculatorWidgetState();
}

class _GoldCalculatorWidgetState extends State<GoldCalculatorWidget> {
  final _weightController = TextEditingController();
  final _workmanshipController = TextEditingController();
  double _totalPrice = 0.0;

  @override
  void dispose() {
    _weightController.dispose();
    _workmanshipController.dispose();
    super.dispose();
  }

  void _calculate(AppState appState) {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final workmanship = double.tryParse(_workmanshipController.text) ?? 0.0;
    
    setState(() {
      _totalPrice = (appState.goldPrice * weight) + (workmanship * weight);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger calculation when appState changes (e.g., currency/karat)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _calculate(appState);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calculate_outlined, color: AppColors.primaryGold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'حاسبة الذهب',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              _buildGramToggle(appState, isDark),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSmallSelector(
                context: context,
                currentValue: appState.selectedCurrency,
                options: ['YER', 'SAR', 'USD'],
                onChanged: (v) => appState.setSelectedCurrency(v!),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildSmallSelector(
                context: context,
                currentValue: appState.selectedUnit,
                options: ['K24', 'K22', 'K21', 'K18'],
                onChanged: (v) => appState.setSelectedUnit(v!),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  controller: _weightController,
                  label: 'الوزن (جرام)',
                  icon: Icons.scale_rounded,
                  onChanged: (_) => _calculate(appState),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  controller: _workmanshipController,
                  label: 'المصنعية / جرام',
                  icon: Icons.architecture_rounded,
                  onChanged: (_) => _calculate(appState),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.liquidGold,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي السعر:',
                  style: GoogleFonts.cairo(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  appState.isGoldPriceLoaded 
                    ? '${_totalPrice.toStringAsFixed(2)} ${appState.selectedCurrency.tr()}'
                    : '--------',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '* السعر يعتمد على سعر ${appState.selectedUnit.tr()} الحالي',
            style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGramToggle(AppState appState, bool isDark) {
    return GestureDetector(
      onTap: () => appState.setShowGramPrice(!appState.showGramPrice),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: appState.showGramPrice,
              onChanged: (v) => appState.setShowGramPrice(v ?? false),
              activeColor: AppColors.primaryGold,
              checkColor: Colors.black,
              side: BorderSide(color: isDark ? Colors.white38 : Colors.black38, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Text(
            'سعر الجرام'.tr(),
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSelector({
    required BuildContext context,
    required String currentValue,
    required List<String> options,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryGold),
          selectedItemBuilder: (BuildContext context) {
            return options.map<Widget>((String item) {
              return Center(
                child: Text(
                  item.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 11, 
                    color: isDark ? Colors.white : Colors.black87, 
                    fontWeight: FontWeight.w900
                  ),
                ),
              );
            }).toList();
          },
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value.tr(), 
                style: GoogleFonts.cairo(
                  fontSize: 13, 
                  color: isDark ? Colors.white : Colors.black, 
                  fontWeight: FontWeight.bold
                )
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
          floatingLabelStyle: GoogleFonts.cairo(fontSize: 12, color: AppColors.primaryGold),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primaryGold),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}
