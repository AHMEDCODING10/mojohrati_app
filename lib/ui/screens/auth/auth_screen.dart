import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../config/colors.dart';
import '../../../config/constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../state/app_state.dart';
import '../customer/main_navigation_wrapper.dart';
import 'package:mojowharati/ui/screens/shared/contact_us_screen.dart';
import '../merchant/merchant_navigation_wrapper.dart';
import 'forgot_password_screen.dart';
import '../../widgets/custom/gold_gradient_button.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _modeController;
  String _selectedRole = 'customer'; // 'customer' or 'merchant'
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storeNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  Map<String, String> _apiErrors = {};


  @override
  void initState() {
    super.initState();
    _modeController = TabController(length: 2, vsync: this);
    _modeController.addListener(() {
      setState(() {}); // To update UI based on tab change (Login vs Register)
    });

  }



  @override
  void dispose() {
    _modeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  bool get _isLoginMode => _modeController.index == 0;

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final appState = context.read<AppState>();
      bool success = false;

      if (_isLoginMode) {
        success = await appState.login(
          _phoneController.text.trim(),
          _passwordController.text,
        );
      } else {
        final data = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
          'role': _selectedRole,
        };
        if (_selectedRole == 'merchant') {
          data['store_name'] = _storeNameController.text.trim();
        }
        success = await appState.register(data);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final userRole = appState.currentUser?.type ?? 'customer';
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => userRole == 'merchant'
                ? const MerchantNavigationWrapper()
                : const MainNavigationWrapper(),
          ),
          (route) => false,
        );
      } else {
        if (appState.lastValidationErrors != null) {
          appState.lastValidationErrors!.forEach((key, value) {
            String errorMsg = '';
            if (value is List && value.isNotEmpty) {
              errorMsg = value.first.toString();
            } else {
              errorMsg = value.toString();
            }
            _apiErrors[key] = errorMsg;
          });
        }

        // Check if the error is an account block
        final String errorMessage = appState.lastError ?? appState.error ?? '';
        
        if (errorMessage.contains('account_blocked') || errorMessage.contains('حظر') || errorMessage.contains('محظور')) {
          _showBlockedAccountDialog();
        } else {
          final displayMessage = errorMessage.isNotEmpty
              ? errorMessage
              : 'رقم الهاتف أو كلمة المرور غير صحيحة';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showBlockedAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.primaryGold.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.08),
                  border: Border.all(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.redAccent,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'تم تعطيل الحساب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Body
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.1)),
                ),
                child: Text(
                  'حسابك محظور مؤقتاً من الوصول إلى التطبيق.للاستفسار أو الطعن في هذا القراريرجى التواصل مع خدمة العملاء.',

                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Buttons
              Row(
                children: [
                  // Contact Us button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContactUsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.liquidGold,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Text(
                          'تواصل معنا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Close button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Text(
                          'إغلاق',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          child: Stack(
            children: [
              if (!_isLoginMode)
                Positioned(
                  top: 10,
                  right: 20,
                  child: IconButton(
                    icon: Icon(LucideIcons.chevron_right, color: isDark ? AppColors.primaryGold : Colors.black87, size: 24),
                    onPressed: () => _modeController.animateTo(0),
                  ),
                ),
              Column(
                children: [
                  SizedBox(height: _isLoginMode ? 50 : 20),
                  _buildLogo().animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0),
                  if (!_isLoginMode) ...[
                    const SizedBox(height: 12),
                    _buildRoleSelection(isDark).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildForm(isDark),
                          const SizedBox(height: 40),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoleIcon(
            label: 'عميل',
            icon: LucideIcons.user,
            isSelected: _selectedRole == 'customer',
            onTap: () => setState(() => _selectedRole = 'customer'),
            isDark: isDark,
          ),
          const SizedBox(width: 40),
          _RoleIcon(
            label: 'تاجر',
            icon: LucideIcons.store,
            isSelected: _selectedRole == 'merchant',
            onTap: () => setState(() => _selectedRole = 'merchant'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Hero(
          tag: 'logo',
          child: Container(
            width: _isLoginMode ? 70 : 55,
            height: _isLoginMode ? 70 : 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppConstants.logoPlaceholder,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.diamond_rounded, color: AppColors.primaryGold, size: 30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.appNameAr,
          style: TextStyle(
            fontSize: _isLoginMode ? 24 : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.primaryGold
          ),
        ),
      ],
    );
  }


  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLoginMode) ...[
            _buildTextField(
              controller: _nameController,
              label: 'الاسم الكامل',
              fieldNameKey: 'name',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال الاسم';
                if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v)) {
                  return 'يرجى كتابة الاسم باستخدام الحروف فقط دون أرقام أو رموز.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              fieldNameKey: 'email',
              icon: Icons.email_outlined,
              isDark: isDark,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                final regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
                if (!regex.hasMatch(v)) return 'صيغة البريد الإلكتروني غير صحيحة';
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (_selectedRole == 'merchant') ...[
              _buildTextField(
                controller: _storeNameController,
                label: 'اسم المتجر',
                fieldNameKey: 'store_name',
                icon: Icons.store_outlined,
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'يرجى إدخال اسم المتجر';
                  if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v)) return 'يرجى كتابة اسم المتجر باستخدام الحروف فقط';
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            _buildTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              fieldNameKey: 'phone',
              icon: Icons.phone_android_outlined,
              isDark: isDark,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              validator: _validatePhone,
            ),
            const SizedBox(height: 12),
          ],
          if (_isLoginMode) ...[
            _buildTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              fieldNameKey: 'phone',
              icon: Icons.phone_android_outlined,
              isDark: isDark,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              validator: _validatePhone,
            ),
            const SizedBox(height: 20),
          ],
          _buildTextField(
            controller: _passwordController,
            label: 'كلمة المرور',
            fieldNameKey: 'password',
            icon: Icons.lock_outline_rounded,
            isDark: isDark,
            obscureText: _obscurePassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
              if (v.length < 8 && !_isLoginMode) return 'كلمة المرور يجب أن لا تقل عن 8 رموز';
              return null;
            },
          ),
          SizedBox(height: _isLoginMode ? 20 : 12),
          if (!_isLoginMode) ...[
             _buildTextField(
              controller: _confirmPasswordController,
              label: 'تأكيد كلمة المرور',
              fieldNameKey: 'password_confirmation',
              icon: Icons.lock_clock_outlined,
              isDark: isDark,
              obscureText: _obscurePassword,
              validator: (v) => v != _passwordController.text ? 'كلمات المرور غير متطابقة' : null,
            ),
          ],
          if (_isLoginMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: GoogleFonts.cairo(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => _modeController.animateTo(1),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(
                    'حساب جديد',
                    style: GoogleFonts.cairo(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          else 
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _modeController.animateTo(0),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text(
                  'لديك حساب بالفعل؟ دخول',
                   style: GoogleFonts.cairo(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          SizedBox(height: _isLoginMode ? 30 : 20),
          _buildSubmitButton(),
          if (_isLoginMode) ...[
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGlassAction(
                  icon: LucideIcons.user_plus,
                  label: 'دخول كزائر',
                  isDark: isDark,
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(width: 30),
                _buildGlassAction(
                  icon: Icons.support_agent_rounded,
                  label: 'تواصل معنا',
                  isDark: isDark,
                  onTap: () => _showContactOptions(context, isDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassAction({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: AppColors.primaryGold.withOpacity(0.3),
          highlightColor: AppColors.primaryGold.withOpacity(0.1),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.liquidGold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.black, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            shadows: [
              Shadow(
                color: isDark ? Colors.black54 : Colors.white54,
                blurRadius: 2,
              )
            ]
          ),
        ),
      ],
    );
  }

  void _showContactOptions(BuildContext context, bool isDark) {
    final appState = context.read<AppState>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.premiumBlack : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('تواصل معنا الدعم الفني', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
            const SizedBox(height: 24),
            if (appState.contactList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('لا توجد معلومات تواصل حالياً', style: GoogleFonts.cairo(color: Colors.grey)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: appState.contactList.map((info) {
                    Color iconColor = AppColors.primaryGold;
                    switch (info['type']) {
                      case 'whatsapp': iconColor = const Color(0xFF25D366); break;
                      case 'facebook': iconColor = const Color(0xFF1877F2); break;
                      case 'instagram': iconColor = const Color(0xFFE4405F); break;
                      case 'email': iconColor = Colors.redAccent; break;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildContactOptionTile(
                        icon: _getIconData(info['icon'], info['type']),
                        label: info['label'] ?? '',
                        color: iconColor,
                        onTap: () => _handleContactLaunch(info['type'] ?? 'url', info['value'] ?? ''),
                        isDark: isDark,
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(dynamic iconValue, String? type) {
    switch (iconValue) {
      case 'phone': return Icons.phone_rounded;
      case 'whatsapp': return Icons.chat_bubble_rounded;
      case 'email': return Icons.email_rounded;
      case 'facebook': return Icons.facebook_rounded;
      case 'instagram': return Icons.camera_alt_rounded;
      case 'tiktok': return LucideIcons.music;
      default: 
        if (type == 'phone') return Icons.phone_rounded;
        return Icons.link_rounded;
    }
  }

  Future<void> _handleContactLaunch(String type, String value) async {
    Uri uri;
    switch (type) {
      case 'phone': uri = Uri.parse('tel:$value'); break;
      case 'email': uri = Uri.parse('mailto:$value'); break;
      case 'whatsapp': 
        String phone = value.replaceAll(RegExp(r'[^\d]'), '');
        uri = Uri.parse('https://wa.me/$phone');
        break;
      default: uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
    }
    
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
         debugPrint('Could not launch $uri');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildContactOptionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال رقم الهاتف';
    
    // Yemen mobile numbers are 9 digits starting with 77, 78, 73, 70, 71
    final regex = RegExp(r"^(70|71|73|77|78)\d{7}$");
    if (!regex.hasMatch(value)) {
      return 'يرجى إدخال رقم يمني صحيح (77, 78, 73, 70, 71)';
    }
    return null;
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? fieldNameKey,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    Widget? activeSuffix;

    if (label == 'كلمة المرور') {
      activeSuffix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ],
      );
    }

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (val) {
        if (fieldNameKey != null && _apiErrors.containsKey(fieldNameKey)) {
          setState(() => _apiErrors.remove(fieldNameKey));
        }
      },
      validator: (v) {
        if (fieldNameKey != null && _apiErrors.containsKey(fieldNameKey)) {
          return _apiErrors[fieldNameKey];
        }
        if (validator != null) return validator(v);
        return null;
      },
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? AppColors.primaryGold.withOpacity(0.8) : Colors.black54),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(icon, color: AppColors.primaryGold, size: 22),
        suffixIcon: activeSuffix,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
        errorMaxLines: 2,
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GoldGradientButton(
      text: _isLoginMode ? 'دخول' : 'إنشاء الحساب',
      onPressed: _handleSubmit,
      isLoading: _isLoading,
    );
  }
}


class _RoleIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleIcon({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primaryGold : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
              border: Border.all(
                color: isSelected ? AppColors.primaryGold : (isDark ? Colors.white24 : Colors.black12),
                width: 2,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2
                )
              ] : null,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black45),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primaryGold : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
