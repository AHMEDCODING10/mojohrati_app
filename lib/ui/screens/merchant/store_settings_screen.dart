import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import '../../widgets/custom/gold_gradient_button.dart';

class MerchantStoreSettingsScreen extends StatefulWidget {
  const MerchantStoreSettingsScreen({super.key});

  @override
  State<MerchantStoreSettingsScreen> createState() => _MerchantStoreSettingsScreenState();
}

class _MerchantStoreSettingsScreenState extends State<MerchantStoreSettingsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _picker = ImagePicker();

  XFile? _logoFile;
  XFile? _bannerFile;

  // ── Image Picking ──────────────────────────────────────────
  Future<void> _pickLogo() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery, imageQuality: 85, maxWidth: 512,
    );
    if (xFile != null) setState(() => _logoFile = xFile);
  }

  // Banner picking removed as per "Visual Identity removal" request
  // Future<void> _pickBanner() async ...

  // ── Save ──────────────────────────────────────────────────
  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final appState = context.read<AppState>();
    final formData = Map<String, dynamic>.from(_formKey.currentState!.value);

    if (_logoFile != null) formData['logo_file'] = _logoFile;
    if (_bannerFile != null) formData['banner_file'] = _bannerFile;

    final success = await appState.updateMerchantBranding(formData);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'store_identity_saved'.tr() : 'save_failed'.tr()),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success) Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('store_identity_title'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: FormBuilder(
              key: _formKey,
              initialValue: {
                'store_name':        user?.storeName ?? user?.name ?? '',
                'store_description': '',
                'whatsapp_number':   user?.whatsapp ?? '',
                'instagram_handle':  user?.instagram ?? '',
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Store Logo section ──────────────────────
                  _sectionTitle('store_logo'.tr()),
                  const SizedBox(height: 20),

                  // Logo Picker
                  _LogoPicker(
                    existingUrl: user?.storeLogo ?? user?.profileImage,
                    file: _logoFile,
                    onTap: _pickLogo,
                  ).animate().fadeIn().slideY(begin: 0.1),

                  const SizedBox(height: 40),

                  // ── Store Info section ───────────────────────
                  _sectionTitle('store_data'.tr()),
                  const SizedBox(height: 20),
                  _field('store_name', 'store_name_label'.tr(), Icons.storefront_outlined, isDark,
                    validator: FormBuilderValidators.required(errorText: 'field_required'.tr())),
                  const SizedBox(height: 16),
                  _field('store_description', 'store_description_label'.tr(), Icons.description_outlined, isDark,
                    maxLines: 3, validator: null),

                  const SizedBox(height: 40),

                  // ── Social Links section ─────────────────────
                  _sectionTitle('social_links'.tr()),
                  const SizedBox(height: 20),
                  _field('whatsapp_number', 'whatsapp_number_label'.tr(), Icons.message_outlined, isDark,
                    isPhone: true, validator: null),
                  const SizedBox(height: 16),
                  _field('instagram_handle', 'instagram_handle_label'.tr(), Icons.camera_alt_outlined, isDark,
                    validator: null),

                  const SizedBox(height: 48),

                  // ── Save Button ──────────────────────────────
                  appState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                    : GoldGradientButton(
                        text: 'save_store_identity'.tr(),
                        onPressed: _save,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _field(
    String name,
    String label,
    IconData icon,
    bool isDark, {
    bool isPhone = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return FormBuilderTextField(
      name: name,
      maxLines: maxLines,
      keyboardType: isPhone ? TextInputType.phone : (maxLines > 1 ? TextInputType.multiline : null),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
      ),
      style: GoogleFonts.cairo(),
      validator: validator,
    );
  }
}



// ── Logo Picker Widget ─────────────────────────────────────────
class _LogoPicker extends StatelessWidget {
  final String? existingUrl;
  final XFile? file;
  final VoidCallback onTap;

  const _LogoPicker({this.existingUrl, this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ImageProvider bg = file != null
        ? (kIsWeb ? NetworkImage(file!.path) : FileImage(File(file!.path))) as ImageProvider
        : NetworkImage(existingUrl ?? AppConstants.placeholderImage);

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundImage: bg,
                  backgroundColor: AppColors.primaryGold.withValues(alpha: 0.1),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded, size: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('store_logo'.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
