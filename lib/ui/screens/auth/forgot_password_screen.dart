import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../../../state/app_state.dart';
import '../../../config/colors.dart';
import '../../../ui/widgets/custom/gold_gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _currentStep = 1; // 1: Email, 2: Code, 3: Password
  String _email = '';
  String _code = '';
  Map<String, String> _apiErrors = {};
  
  // Controller for Pinput
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.primaryGold : Colors.black87),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  if (_currentStep == 1) _buildEmailStep(isDark, appState),
                  if (_currentStep == 2) _buildCodeStep(isDark, appState),
                  if (_currentStep == 3) _buildPasswordStep(isDark, appState),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(bool isDark, AppState appState) {
    return Column(
      children: [
        const Text(
          'أدخل بريدك الإلكتروني لاستلام رمز التحقق.',
          style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        _buildField('email', 'البريد الإلكتروني', Icons.email_outlined, isDark),
        const SizedBox(height: 60),
        _buildActionButton('ارسال كود التحقق', appState.isLoading, () async {
          if (_formKey.currentState!.saveAndValidate()) {
            final email = _formKey.currentState!.value['email'];
            final error = await appState.sendResetCode(email);
            if (error == null) {
              setState(() {
                _email = email;
                _currentStep = 2;
                _pinController.clear();
              });
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني'),
                  backgroundColor: Colors.green,
                ));
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ));
              }
            }
          }
        }),
      ],
    );
  }

  Widget _buildCodeStep(bool isDark, AppState appState) {
    // Pinput Theme
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(fontSize: 22, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white30 : Colors.black26, width: 1),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryGold, width: 2),
      borderRadius: BorderRadius.circular(16),
      color: isDark ? Colors.black : Colors.white,
    );
    
    return Column(
      children: [
        Text(
          'تم إرسال رمز التحقق إلى $_email',
          style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        
        Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            length: 6,
            controller: _pinController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            onCompleted: (pin) {
               // Optional: Auto-submit when code is filled
            },
          ),
        ),

        const SizedBox(height: 60),
        _buildActionButton('تحقق من الكود', appState.isLoading, () async {
            final code = _pinController.text;
            if (code.length != 6) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('يرجى إدخال الرمز كاملاً'),
                  backgroundColor: Colors.red,
                ));
               return;
            }

            final success = await appState.verifyResetCode(_email, code);
            if (success) {
               setState(() {
                _code = code;
                _currentStep = 3;
              });
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('رمز التحقق غير صحيح'),
                  backgroundColor: Colors.red,
                ));
              }
            }
        }),
        TextButton(
          onPressed: () => setState(() => _currentStep = 1), 
          child: const Text('تغيير البريد الإلكتروني', style: TextStyle(color: AppColors.primaryGold))
        )
      ],
    );
  }

  Widget _buildPasswordStep(bool isDark, AppState appState) {
    return Column(
      children: [
        const Text(
          'قم بتعيين كلمة المرور الجديدة.',
          style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildField('password', 'كلمة المرور الجديدة', Icons.lock_outline, isDark, isPassword: true),
        const SizedBox(height: 16),
        _buildField('password_confirmation', 'تأكيد كلمة المرور', Icons.lock_outline, isDark, isPassword: true),
        const SizedBox(height: 48),
        _buildActionButton('حفظ', appState.isLoading, () async {
          if (_formKey.currentState!.saveAndValidate()) {
            final values = _formKey.currentState!.value;
            if (values['password'] != values['password_confirmation']) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمات المرور غير متطابقة')));
              return;
            }
            
            final success = await appState.resetPasswordWithCode(_email, _code, values['password'], values['password_confirmation']);
            if (success) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تم تغيير كلمة المرور بنجاح. يرجى تسجيل الدخول.'),
                  backgroundColor: Colors.green,
                ));
                Navigator.pop(context);
              }
            } else {
              if (appState.lastValidationErrors != null) {
                setState(() {
                  _apiErrors = appState.lastValidationErrors!.map((key, value) {
                    return MapEntry(key, (value is List) ? value.first.toString() : value.toString());
                  });
                });
              }
               if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(appState.lastError ?? 'حدث خطأ أثناء تغيير كلمة المرور'),
                  backgroundColor: Colors.red,
                ));
              }
            }
          }
        }),
      ],
    );
  }

  Widget _buildActionButton(String text, bool isLoading, VoidCallback onPressed) {
    return GoldGradientButton(
      text: text,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  Widget _buildField(String name, String label, IconData icon, bool isDark, {bool isPassword = false}) {
    return FormBuilderTextField(
      name: name,
      obscureText: isPassword,
      keyboardType: name == 'email' ? TextInputType.emailAddress : TextInputType.text,
      onChanged: (val) {
        if (_apiErrors.containsKey(name)) {
          setState(() => _apiErrors.remove(name));
        }
      },
      validator: FormBuilderValidators.compose([
        if (_apiErrors.containsKey(name)) (val) => _apiErrors[name],
        FormBuilderValidators.required(errorText: 'هذا الحقل مطلوب'),
        if (!isPassword && name == 'email')
           FormBuilderValidators.email(errorText: 'صيغة بريد إلكتروني غير صالحة'),
        if (isPassword) (val) {
          if (val == null || val.length < 8) return 'كلمة المرور يجب أن تكون 8 رموز';
          if (name == 'password' && !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(val)) {
            return 'يجب أن تحتوي كلمة المرور على أحرف كبيرة وصغيرة وأرقام ورموز.';
          }
          return null;
        },
      ]),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelStyle: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
      ),
    );
  }
}
