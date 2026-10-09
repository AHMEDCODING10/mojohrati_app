import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../../../utils/localization_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  double _result = 0;
  String _targetCurrency = 'YER';

  // Mock rates (Base: USD)
  final Map<String, double> _rates = {
    'USD': 1.0,
    'SAR': 3.75,
    'YER': 530.0, // Example rate, should be dynamic
  };

  void _convert() {
    if (_formKey.currentState!.saveAndValidate()) {
      final values = _formKey.currentState!.value;
      final amount = double.parse(values['amount']);
      final from = values['from'];
      final to = values['to'];

      // Convert to USD first
      final double inUsd = amount / _rates[from]!;
      
      // Convert to target
      setState(() {
        _result = inUsd * _rates[to]!;
        _targetCurrency = to;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('currency_conv_title'.tr()), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'amount',
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'enter_amount'.tr(),
                  labelStyle: GoogleFonts.cairo(color: AppColors.primaryGold),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.attach_money, color: AppColors.primaryGold),
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => val == null || val.isEmpty ? 'required_field'.tr() : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FormBuilderDropdown<String>(
                      name: 'from',
                      initialValue: 'USD',
                      decoration: InputDecoration(
                        labelText: 'from_currency'.tr(),
                        labelStyle: GoogleFonts.cairo(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _rates.keys.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo()))).toList(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: AppColors.primaryGold, size: 20),
                  ),
                  Expanded(
                    child: FormBuilderDropdown<String>(
                      name: 'to',
                      initialValue: 'YER',
                      decoration: InputDecoration(
                        labelText: 'to_currency'.tr(),
                        labelStyle: GoogleFonts.cairo(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: _rates.keys.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo()))).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.liquidGold,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGold.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _convert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black87,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'convert_now'.tr(), 
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              if (_result > 0)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGold),
                  ),
                  child: Column(
                    children: [
                       Text('conv_result_desc'.tr(), style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '${_result.toStringAsFixed(2)} $_targetCurrency',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
