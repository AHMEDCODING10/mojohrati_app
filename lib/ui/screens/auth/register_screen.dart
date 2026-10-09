import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../state/app_state.dart';
import '../customer/home_screen.dart';
import '../merchant/dashboard_screen.dart';
import '../../widgets/custom/gold_gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  final String userType;
  const RegisterScreen({super.key, required this.userType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // Using phone as identifier in backend? Wait, AuthController says email is required.
  final _emailController = TextEditingController(); // I should add email
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final data = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'password_confirmation': _passwordController.text,
        'role': widget.userType,
      };

      if (widget.userType == 'merchant') {
        data['store_name'] = _storeNameController.text;
      }

      final appState = context.read<AppState>();
      // I need to add a register method to AppState or use ApiService directly
      // For consistency, let's add it to AppState
      final success = await appState.register(data);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final user = appState.currentUser;
        if (user?.type == 'merchant') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MerchantDashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        final errorMsg = appState.lastError ?? 'عذراً، فشل إنشاء الحساب. تأكد من البيانات.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Official Logo
                  Center(
                    child: Hero(
                      tag: 'logo',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryGold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            AppConstants.logoPlaceholder,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_add_rounded, color: Colors.black, size: 30),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'عضوية جديدة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ابدأ رحلة الفخامة اليوم',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  _buildGlassInput(
                    controller: _nameController,
                    hintText: 'الاسم الكامل',
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildGlassInput(
                    controller: _emailController,
                    hintText: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildGlassInput(
                    controller: _phoneController,
                    hintText: 'رقم الهاتف',
                    icon: Icons.phone_android_rounded,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  if (widget.userType == 'merchant') ...[
                    _buildGlassInput(
                      controller: _storeNameController,
                      hintText: 'اسم المتجر',
                      icon: Icons.storefront_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildGlassInput(
                    controller: _passwordController,
                    hintText: 'كلمة المرور',
                    icon: Icons.lock_outline_rounded,
                    isDark: isDark,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                                  color: isDark ? Colors.white54 : Colors.black38),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GoldGradientButton(
                    text: 'تفعيل العضوية',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 20),
                  _buildSeparator(isDark),
                  const SizedBox(height: 20),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialGlassBtn(icon: Icons.g_mobiledata, isDark: isDark),
                      const SizedBox(width: 20),
                      _SocialGlassBtn(icon: Icons.facebook_rounded, isDark: isDark),
                      const SizedBox(width: 20),
                      _SocialGlassBtn(icon: Icons.apple_rounded, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'لديك حساب بالفعل؟ ',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        children: const [
                          TextSpan(
                            text: 'دخول متميز',
                            style: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInput({
    required String hintText,
    required IconData icon,
    required bool isDark,
    TextEditingController? controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white30 : Colors.black26, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          if (hintText.contains('البريد') && !value.contains('@')) {
            return 'بريد إلكتروني غير صالح';
          }
          return null;
        },
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(icon, color: AppColors.primaryGold),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }


  Widget _buildSeparator(bool isDark) {
    return Row(
      children: [
        Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('تسجيل سريع بـ', style: TextStyle(color: isDark ? Colors.white30 : Colors.black26, fontSize: 12)),
        ),
        Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
      ],
    );
  }
}

class _SocialGlassBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const _SocialGlassBtn({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Icon(icon, size: 28, color: isDark ? Colors.white70 : Colors.black87),
    );
  }
}
