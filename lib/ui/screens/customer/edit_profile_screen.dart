import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_profile'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FormBuilder(
          key: _formKey,
          initialValue: {
            'name': user?.name,
            'phone': user?.phone,
            'email': user?.email,
          },
          child: Column(
            children: [
              _buildField('name', 'full_name'.tr(), Icons.person_outline, isDark, maxLength: 60),
              const SizedBox(height: 16),
              _buildField('phone', 'phone_number'.tr(), Icons.phone_android, isDark, isPhone: true),
              const SizedBox(height: 16),
              _buildField('password', 'new_password_optional'.tr(), Icons.lock_outline, isDark, 
                  isPassword: true, 
                  obscure: _obscurePassword,
                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
              const SizedBox(height: 16),
              _buildField('password_confirmation', 'confirm_password'.tr(), Icons.lock_outline, isDark, 
                  isPassword: true,
                  obscure: _obscurePasswordConfirm,
                  onToggle: () => setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.saveAndValidate()) {
                      final data = Map<String, dynamic>.from(_formKey.currentState!.value);
                      
                      // Remove empty password if not changed
                      if (data['password'] == null || data['password'].toString().isEmpty) {
                        data.remove('password');
                        data.remove('password_confirmation');
                      }

                      final success = await appState.updateProfile(data);
                      if (success) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_update_success'.tr())));
                        Navigator.pop(context);
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_update_fail'.tr())));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('save_changes'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String name, String label, IconData icon, bool isDark, {
    bool isPassword = false, 
    bool isPhone = false,
    int? maxLength,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return FormBuilderTextField(
      name: name,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: isPhone ? TextInputType.phone : null,
      validator: FormBuilderValidators.compose([
        if (!isPassword) FormBuilderValidators.required(errorText: 'required_field'.tr()),
        if (isPassword) FormBuilderValidators.minLength(8, errorText: 'password_min_length_error'.tr()),
        if (isPhone) ...[
          FormBuilderValidators.numeric(errorText: 'numeric_only_error'.tr()),
          (value) {
            if (value == null || value.isEmpty) return 'required_field'.tr();
            if (value.length != 9) return 'phone_length_error'.tr();
            if (!value.startsWith('7')) return 'phone_prefix_error'.tr();
            
            final regex = RegExp(r"^7[0137][0-9]{7}$");
            if (!regex.hasMatch(value)) return 'phone_prefix_error'.tr();
            
            return null;
          }
        ],
      ]),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: onToggle,
            )
          : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
