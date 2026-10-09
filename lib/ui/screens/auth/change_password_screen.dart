import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../state/theme_state.dart';
import '../../../utils/localization_service.dart';
import '../../widgets/custom/gold_gradient_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  Map<String, String> _apiErrors = {};

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    final isDark = themeState.effectiveDarkMode(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('change_password'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    Icons.lock_reset_rounded,
                    size: 80,
                    color: AppColors.primaryGold.withOpacity(0.8),
                  ),
                  const SizedBox(height: 48),
                  _buildPasswordField(
                    name: 'current_password',
                    label: 'current_password'.tr(),
                    obscure: _obscureCurrent,
                    onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(
                    name: 'new_password',
                    label: 'new_password'.tr(),
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    isDark: isDark,
                    isNew: true,
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(
                    name: 'confirm_password',
                    label: 'confirm_new_password'.tr(),
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    isDark: isDark,
                    isConfirm: true,
                  ),
                  const SizedBox(height: 48),
                  GoldGradientButton(
                    text: 'save'.tr(),
                    isLoading: appState.isLoading,
                    onPressed: () async {
                      if (_formKey.currentState?.saveAndValidate() ?? false) {
                        final data = _formKey.currentState!.value;
                        final success = await appState.changePassword(
                          data['current_password'], 
                          data['new_password'],
                          data['confirm_password'],
                        );
                        
                        if (success) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('password_changed_success'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: AppColors.primaryGold,
                              ),
                            );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(appState.lastError ?? 'error_occurred'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String name,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
    bool isNew = false,
    bool isConfirm = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: FormBuilderTextField(
        name: name,
        obscureText: obscure,
        onChanged: (val) {
          if (_apiErrors.containsKey(name)) {
            setState(() => _apiErrors.remove(name));
          }
        },
        validator: FormBuilderValidators.compose([
          if (_apiErrors.containsKey(name)) (val) => _apiErrors[name],
          FormBuilderValidators.required(errorText: 'required_field'.tr()),
          if (isNew) (val) {
            if (val == null || val.length < 8) return 'password_min_length_error'.tr();
            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(val)) {
              return 'يجب أن تحتوي كلمة المرور على أحرف كبيرة وصغيرة وأرقام ورموز.';
            }
            return null;
          },
          if (isConfirm) (val) {
            if (val != _formKey.currentState?.fields['new_password']?.value) {
              return 'passwords_do_not_match'.tr();
            }
            return null;
          }
        ]),
        style: GoogleFonts.cairo(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primaryGold, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
