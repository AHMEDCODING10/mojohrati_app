import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import '../../widgets/custom/gold_gradient_button.dart';
import 'bookings_screen.dart';

class CustomDesignOrderScreen extends StatefulWidget {
  const CustomDesignOrderScreen({super.key});

  @override
  State<CustomDesignOrderScreen> createState() => _CustomDesignOrderScreenState();
}

class _CustomDesignOrderScreenState extends State<CustomDesignOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _weightController = TextEditingController();

  XFile? _selectedImageFile; // use XFile to be compatible with API
  Uint8List? _selectedImageBytes; // cached bytes for web-safe image display
  bool _isSubmitting = false;
  bool _isFetchingMerchants = false;
  int _currentStep = 0;

  String _selectedPurity = '21';
  String? _selectedMerchantId;

  final List<String> _purities = ['18', '21', '22', '24'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null && mounted) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageFile = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _advanceToStep(int nextStep) async {
    // If advancing to merchant selection step, fetch merchants
    if (nextStep == 2) {
      setState(() => _isFetchingMerchants = true);
      await context.read<AppState>().fetchMerchants();
      setState(() => _isFetchingMerchants = false);
    }
    setState(() => _currentStep = nextStep);
  }

  Future<void> _submitOrder() async {
    if (_selectedMerchantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_merchant'.tr()), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final appState = context.read<AppState>();
    final success = await appState.submitCustomDesign({
      'description': _descriptionController.text,
      'budget': _budgetController.text,
      'purity': _selectedPurity,
      'weight': _weightController.text,
      'merchant_id': _selectedMerchantId,
      'image': _selectedImageFile, // pass XFile directly — ApiService handles platform differences
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('booking_failed'.tr()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.matteBlack.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('success'.tr(), style: GoogleFonts.playfairDisplay(color: AppColors.primaryGold)),
        content: Text('تم إرسال طلبك بنجاح!\nسيتواصل معك التاجر قريباً.',
            style: GoogleFonts.cairo(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back home
            },
            child: Text('ok'.tr(), style: const TextStyle(color: Colors.white70)),
          ),
          GoldGradientButton(
            width: 150,
            height: 45,
            text: 'track_order'.tr().isNotEmpty ? 'track_order'.tr() : 'تتبع طلبي',
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BookingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(context, isDark),
                _buildProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentStepView(isDark, appState),
                      ),
                    ),
                  ),
                ),
                _buildNavigationButtons(isDark),
              ],
            ),
          ),
          if (_isSubmitting || _isFetchingMerchants)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primaryGold),
                    const SizedBox(height: 16),
                    Text(
                      _isFetchingMerchants ? 'جاري تحميل المتاجر...' : 'جاري إرسال الطلب...',
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'custom_design'.tr(),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.primaryGold : Colors.grey.withOpacity(0.3),
                    border: Border.all(
                        color: isActive ? Colors.white24 : Colors.transparent),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep
                          ? AppColors.primaryGold
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepView(bool isDark, AppState appState) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(isDark);
      case 1:
        return _buildStep2(isDark);
      case 2:
        return _buildStep3(isDark, appState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(bool isDark) {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('design_step_1'.tr(),
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildImagePicker(isDark),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _descriptionController,
          label: 'description'.tr(),
          hint: 'description_hint'.tr(),
          maxLines: 5,
          validator: (v) => v == null || v.isEmpty ? 'description_error'.tr() : null,
          isDark: isDark,
        ),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildStep2(bool isDark) {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('design_step_2'.tr(),
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Text('gold_purity_select'.tr(),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: _purities
              .map((p) => ChoiceChip(
                    label: Text('$p K'),
                    selected: _selectedPurity == p,
                    onSelected: (val) => setState(() => _selectedPurity = p),
                    selectedColor: AppColors.primaryGold,
                    labelStyle: TextStyle(
                        color: _selectedPurity == p
                            ? Colors.black
                            : (isDark ? Colors.white : Colors.black)),
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _weightController,
          label: 'estimated_weight'.tr(),
          hint: '0.0',
          isNumber: true,
          isDark: isDark,
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _budgetController,
          label: 'budget_range'.tr(),
          hint: '5000 - 10000',
          isDark: isDark,
        ),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildStep3(bool isDark, AppState appState) {
    final rawMerchants = appState.merchants;

    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('design_step_3'.tr(),
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('select_merchant_hint'.tr(),
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 24),
        if (rawMerchants.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.store_mall_directory_outlined,
                      size: 64, color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('لا توجد متاجر متاحة حالياً',
                      style: GoogleFonts.cairo(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ...rawMerchants.map((m) {
            final id = m['id']?.toString() ?? '';
            final storeName = m['store_name'] ?? m['name'] ?? 'متجر';
            final storeLogo = m['store_logo'] ?? m['profile_image'];
            final address = m['address'] ?? m['store_description'] ?? '';
            final isSelected = _selectedMerchantId == id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedMerchantId = id),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGold.withOpacity(0.15)
                        : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryGold : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                        backgroundImage:
                            storeLogo != null ? NetworkImage(storeLogo) : null,
                        child: storeLogo == null
                            ? const Icon(Icons.store_rounded,
                                color: AppColors.primaryGold)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(storeName,
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            if (address.isNotEmpty)
                              Text(address,
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primaryGold, key: ValueKey('checked'))
                            : Icon(Icons.radio_button_unchecked_rounded,
                                color: Colors.grey.withOpacity(0.4),
                                key: const ValueKey('unchecked')),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    ).animate().fadeIn().slideX();
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primaryGold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('back'.tr(),
                    style: const TextStyle(color: AppColors.primaryGold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: GoldGradientButton(
              text: _currentStep < 2 ? 'next'.tr() : 'submit_order'.tr(),
              onPressed: () {
                if (_currentStep == 0) {
                  // Step 1: validate description
                  if (_formKey.currentState!.validate()) {
                    _advanceToStep(1);
                  }
                } else if (_currentStep == 1) {
                  // Step 2: validate specs then fetch merchants
                  _advanceToStep(2);
                } else {
                  _submitOrder();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('upload_image'.tr(),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _selectedImageFile != null
                    ? AppColors.primaryGold
                    : AppColors.primaryGold.withOpacity(0.3),
                width: _selectedImageFile != null ? 2 : 1,
              ),
            ),
            child: _selectedImageFile != null && _selectedImageBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImageFile = null;
                            _selectedImageBytes = null;
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Text('تغيير',
                              style: GoogleFonts.cairo(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined,
                          color: AppColors.primaryGold, size: 44),
                      const SizedBox(height: 12),
                      Text('اضغط لرفع صورة التصميم',
                          style: GoogleFonts.cairo(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('اختياري - يمكنك التخطي',
                          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isNumber = false,
    bool isDark = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: validator,
          style: GoogleFonts.cairo(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
