import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});

  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  final _goldWeightController = TextEditingController();
  final _silverWeightController = TextEditingController();

  double _goldZakatGrams = 0;
  double _goldZakatPrice = 0;
  double _goldZakatPriceYER = 0;
  bool _calculated = false;

  
  int _selectedGoldKarat = 24;
  final List<int> _karats = [24, 22, 21, 18];

  // نصاب الفضة: 595 غراماً

  double _getCurrentGoldNisab() {
    switch (_selectedGoldKarat) {
      case 24: return 85.0;
      case 22: return 92.73;
      case 21: return 97.13; // Specified by user
      case 18: return 113.33;
      default: return 85.0;
    }
  }

  void _calculateZakat() {
    final double goldWeight = double.tryParse(_goldWeightController.text) ?? 0;

    // فحص النصاب بناءً على العيار المختار
    final double currentNisab = _getCurrentGoldNisab();
    
    final goldReaches = goldWeight >= currentNisab;
    
    final appState = context.read<AppState>();
    final double goldZakatGrams = goldReaches ? goldWeight * 0.025 : 0.0;
    
    // Dynamic price based on app currency
    final double goldZakatPrice = goldZakatGrams * appState.getPriceForKarat(_selectedGoldKarat, appState.selectedCurrency);
    
    // Specific YER price as requested
    final double goldZakatPriceYER = goldZakatGrams * appState.getPriceForKarat(_selectedGoldKarat, 'YER');

    setState(() {

      _goldZakatGrams = goldZakatGrams;
      _goldZakatPrice = goldZakatPrice;
      _goldZakatPriceYER = goldZakatPriceYER;
      _calculated = true;
    });
  }

  @override
  void dispose() {
    _goldWeightController.dispose();
    _silverWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.matteBlack : AppColors.royalCream,
      appBar: AppBar(
        title: Text('zakat_calc_title'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(isDark),
            const SizedBox(height: 24),
            _buildNisabCard(isDark),
            const SizedBox(height: 32),
            _buildKaratSelector(isDark),
            const SizedBox(height: 20),
            _buildInputSection('gold_weight_owned'.tr(), _goldWeightController, Icons.auto_awesome, isDark),
            const SizedBox(height: 40),
            _buildCalculateButton(),
            if (_calculated) _buildResultSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryGold),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'بناءً على أسعار الذهب الحالية، تساعدك هذه الأداة في تقدير قيمة الزكاة الواجبة.',
              style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNisabCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            'حدود النصاب الشرعي',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryGold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: _buildNisabItem(
                  Icons.auto_awesome, 
                  'الذهب (${_selectedGoldKarat}K)', 
                  '${_getCurrentGoldNisab().toStringAsFixed(_selectedGoldKarat == 21 ? 2 : 2)} غرام', 
                  isDark
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '• الزكاة = 2.5% من الوزن الإجمالي إذا بلغ النصاب',
            style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNisabItem(IconData icon, String metal, String amount, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 22),
          const SizedBox(height: 8),
          Text(metal, style: GoogleFonts.cairo(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
          Text(amount, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildKaratSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            'اختر عيار الذهب المملوك:',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _karats.map((karat) {
            final isSelected = _selectedGoldKarat == karat;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGoldKarat = karat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryGold : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryGold : (isDark ? Colors.white10 : Colors.black12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${karat}K',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputSection(String label, TextEditingController controller, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.cairo(color: AppColors.primaryGold),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            prefixIcon: Icon(icon, color: AppColors.primaryGold),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primaryGold),
            ),
            hintText: '0.00',
            suffixText: 'غرام',
            suffixStyle: GoogleFonts.cairo(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: _calculateZakat,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: Text(
          'calculate_zakat'.tr(),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildResultSection(bool isDark) {
    final hasZakat = _goldZakatGrams > 0;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(28),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: hasZakat ? AppColors.primaryGold : Colors.orange,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(
            hasZakat ? Icons.check_circle_rounded : Icons.info_rounded,
            color: hasZakat ? AppColors.primaryGold : Colors.orange,
            size: 56,
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            hasZakat ? 'تجب عليك الزكاة' : 'لا تجب عليك الزكاة',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: hasZakat ? AppColors.primaryGold : Colors.orange,
            ),
          ),
          if (!hasZakat) ...[
            const SizedBox(height: 12),
            Text(
              'لم يبلغ مالك النصاب الشرعي المطلوب من الذهب.',
              style: GoogleFonts.cairo(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
          if (hasZakat) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),
            if (_goldZakatGrams > 0) ...[
              _buildZakatResultRow(
                Icons.auto_awesome,
                '${'zakat_gold'.tr()} (${_selectedGoldKarat}K)',
                '${_goldZakatGrams.toStringAsFixed(3)} ${'gram'.tr()}',
                isDark,
              ),
              const SizedBox(height: 16),
              _buildZakatResultRow(
                Icons.account_balance_wallet_outlined,
                'القيمة النقدية المقدرة',
                '${_goldZakatPrice.toStringAsFixed(0)} ${context.read<AppState>().selectedCurrency.tr()}',
                isDark,
                isPrice: true,
              ),
              if (context.read<AppState>().selectedCurrency != 'YER') ...[
                const SizedBox(height: 16),
                _buildZakatResultRow(
                  Icons.payments_outlined,
                  'مقدار الزكاة بالريال اليمني',
                  '${_goldZakatPriceYER.toStringAsFixed(0)} ريال يمني',
                  isDark,
                  color: const Color(0xFF10B981),
                ),
              ],
            ],
          ],
          const SizedBox(height: 32),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          Text(
            'zakat_hadith'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white30 : Colors.black38,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildZakatResultRow(IconData icon, String label, String value, bool isDark, {bool isPrice = false, Color? color}) {
    final effectiveColor = color ?? (isPrice ? Colors.blue : AppColors.primaryGold);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: effectiveColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}
