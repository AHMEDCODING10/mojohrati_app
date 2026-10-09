import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../widgets/custom/gold_gradient_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  Map<String, String> _apiErrors = {};

  void _handleReset() async {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );

      final success = await appState.resetPassword(
        '', // Email placeholder
        '', // Phone placeholder
        _passwordController.text,
        _confirmPasswordController.text,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (success) {
        _showSuccessSheet();
      } else {
        if (appState.lastValidationErrors != null) {
          setState(() {
            _apiErrors = appState.lastValidationErrors!.map((key, value) {
              return MapEntry(key, (value is List) ? value.first.toString() : value.toString());
            });
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appState.lastError ?? 'فشل تحديث كلمة المرور'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: isDark ? AppColors.premiumBlack : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.liquidGold,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.black, size: 40),
            ),
            const SizedBox(height: 32),
            const Text(
              'تم تغيير كلمة المرور!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'أصبح حسابك محمياً بكلمة المرور الجديدة الآن',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
            const Spacer(),
            GoldGradientButton(
              text: 'العودة للرئيسية',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'كلمة مرور جديدة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'يرجى إنشاء كلمة مرور قوية وفريدة لضمان أمان حسابك',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 60),
                  _buildGlassInput(
                    controller: _passwordController,
                    hintText: 'كلمة المرور الجديدة',
                    fieldNameKey: 'password',
                    icon: Icons.lock_outline_rounded,
                    isDark: isDark,
                    obscureText: _obscure1,
                    validator: (v) {
                      if (v == null || v.length < 8) return 'كلمة المرور يجب أن لا تقل عن 8 رموز';
                      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(v)) {
                         return 'يجب أن تحتوي كلمة المرور على أحرف كبيرة وصغيرة وأرقام ورموز.';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                                  color: isDark ? Colors.white54 : Colors.black38),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGlassInput(
                    controller: _confirmPasswordController,
                    hintText: 'تأكيد كلمة المرور',
                    fieldNameKey: 'password_confirmation',
                    icon: Icons.lock_reset_rounded,
                    isDark: isDark,
                    obscureText: _obscure2,
                    validator: (v) {
                      if (v != _passwordController.text) return 'كلمات المرور غير متطابقة';
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                                  color: isDark ? Colors.white54 : Colors.black38),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  const SizedBox(height: 48),
                  GoldGradientButton(
                    text: 'تحديث كلمة المرور',
                    onPressed: _handleReset,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    String? fieldNameKey,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white30 : Colors.black26, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        onChanged: (val) {
          if (fieldNameKey != null && _apiErrors.containsKey(fieldNameKey)) {
            setState(() => _apiErrors.remove(fieldNameKey));
          }
        },
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(icon, color: AppColors.primaryGold),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        validator: (v) {
          if (fieldNameKey != null && _apiErrors.containsKey(fieldNameKey)) {
            return _apiErrors[fieldNameKey];
          }
          if (validator != null) return validator(v);
          return v!.isEmpty ? 'يرجى ملء الحقل' : null;
        },
      ),
    );
  }
}
