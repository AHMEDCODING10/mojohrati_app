import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../models/product.dart';
import '../../../utils/localization_service.dart';
import '../../widgets/custom/gold_gradient_button.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  List<String> _originalExistingImages = []; // Track the original list to detect deletions
  String _selectedMaterialType = 'gold';

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 50);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AppState>().fetchCategories());
    
    if (widget.product != null) {
      _existingImages = List.from(widget.product!.images);
      _originalExistingImages = List.from(widget.product!.images); // Save original for comparison
      _selectedMaterialType = widget.product!.materialType;
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  void _removeExistingImage(int index) {
     setState(() {
       _existingImages.removeAt(index);
     });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildLuxuryAppBar(context, isDark),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: appState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: FormBuilder(
                    key: _formKey,
                    initialValue: widget.product != null ? {
                      'title': widget.product!.name,
                      'description': widget.product!.description,
                      'weight': widget.product!.weight.toString(),
                      'category_id': widget.product!.categoryId.toString(),
                      'purity': widget.product!.purity ?? '21',
                      'material_type': widget.product!.materialType,
                      'stone_type': widget.product!.stoneType,
                      'clarity': widget.product!.clarity,
                      'cut': widget.product!.cut,
                      'stock_quantity': widget.product!.stockQuantity.toString(),
                      'stone_weight': widget.product!.stoneWeight?.toString() ?? '',
                    } : {'purity': '21', 'material_type': 'gold', 'stock_quantity': '1', 'stone_weight': ''},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader('visual_media'.tr(), Icons.photo_library_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildImagePicker(isDark),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('basic_info'.tr(), Icons.info_outline_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildGlassField('title', 'product_investment_name'.tr(), Icons.label_important_outline_rounded, isDark),
                        const SizedBox(height: 20),
                        _buildMaterialSelector(isDark),
                        const SizedBox(height: 20),
                        _buildGlassCategorySelector(isDark, appState),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('values_and_weight'.tr(), Icons.analytics_outlined, isDark),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            _buildGlassField('stock_quantity', 'available_quantity'.tr(), Icons.inventory_2_outlined, isDark, isNumber: true),
                            const SizedBox(height: 20),
                            
                            // Weight Logic: Optional for gemstone, required otherwise
                            _buildGlassField(
                              'weight', 
                              _selectedMaterialType == 'gemstone' ? 'gold_weight_optional'.tr() : 'weight_gram'.tr(), 
                              Icons.scale_rounded, 
                              isDark, 
                              isNumber: true, 
                              isRequired: _selectedMaterialType != 'gemstone'
                            ),
                            
                            if (_selectedMaterialType == 'gemstone') ...[
                              const SizedBox(height: 20),
                              _buildGlassField(
                                'stone_weight', 
                                'stone_weight'.tr(), 
                                Icons.diamond_outlined, 
                                isDark, 
                                isNumber: true, 
                                isRequired: false
                              ),
                            ],
                            
                            const SizedBox(height: 20),
                            
                            // Purity Logic: Dropdown for Gold, Input for Silver, Hidden for Gemstone
                            if (_selectedMaterialType == 'gold') ...[
                              _buildGlassPurityDropdown('purity', 'gold_purity'.tr(), Icons.verified_outlined, isDark),
                            ] else if (_selectedMaterialType == 'silver') ...[
                              _buildGlassField('purity', 'silver_purity'.tr(), Icons.verified_outlined, isDark, isRequired: true),
                            ] else if (_selectedMaterialType == 'gemstone') ...[
                              _buildGlassField('stone_type', 'stone_type'.tr(), Icons.diamond_outlined, isDark, isRequired: false),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(child: _buildGlassField('clarity', 'clarity'.tr(), Icons.visibility_outlined, isDark, isRequired: false)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildGlassField('cut', 'cut'.tr(), Icons.architecture_rounded, isDark, isRequired: false)),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('technical_desc'.tr(), Icons.edit_note_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildGlassField('description', 'masterpiece_desc'.tr(), Icons.description_rounded, isDark, maxLines: 4),
                        const SizedBox(height: 48),
                        
                        _buildSubmitButton(context, appState),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildLuxuryAppBar(BuildContext context, bool isDark) {
    return AppBar(
      title: Text(
        widget.product != null ? 'edit_masterpiece'.tr() : 'add_new_masterpiece'.tr(),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGold),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
      ],
    );
  }

  Widget _buildImagePicker(bool isDark) {
    final allImagesCount = _existingImages.length + _selectedImages.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: allImagesCount + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              // The "Add Image" button is always at the end
              if (index == allImagesCount) {
                return _buildAddImageButton(isDark);
              }

              // Handle existing images first
              if (index < _existingImages.length) {
                return _buildImageThumbnail(
                  image: NetworkImage(_existingImages[index]),
                  onDelete: () => _removeExistingImage(index),
                  isDark: isDark,
                );
              }
              
              // Handle newly selected images
              final adjIndex = index - _existingImages.length;
              return _buildImageThumbnail(
                image: kIsWeb 
                    ? NetworkImage(_selectedImages[adjIndex].path) as ImageProvider
                    : FileImage(File(_selectedImages[adjIndex].path)),
                onDelete: () => _removeImage(adjIndex),
                isDark: isDark,
              );
            },
          ),
        ),
        if (allImagesCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 4),
            child: Text(
              '${'total_images'.tr()}: $allImagesCount',
              style: GoogleFonts.cairo(fontSize: 10, color: AppColors.primaryGold, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildAddImageButton(bool isDark) {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : AppColors.primaryGold.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(isDark ? 0.4 : 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryGold, size: 32),
            const SizedBox(height: 8),
            Text('add_photo'.tr(), style: GoogleFonts.cairo(fontSize: 10, color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail({required ImageProvider image, required VoidCallback onDelete, required bool isDark}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(image: image, fit: BoxFit.cover),
            border: Border.all(color: AppColors.primaryGold.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassField(String name, String label, IconData icon, bool isDark, {bool isNumber = false, bool isRequired = true, int maxLines = 1, void Function(String?)? onChanged}) {
    return FormBuilderTextField(
      name: name,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: FormBuilderValidators.compose([
        if (isRequired) FormBuilderValidators.required(errorText: 'required'.tr()),
        if (isNumber) FormBuilderValidators.numeric(errorText: 'must_be_number'.tr()),
      ]),
      style: GoogleFonts.cairo(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.cairo(
          color: isDark ? Colors.white60 : Colors.black54, 
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryGold, size: 22),
      ),
    );
  }


  Widget _buildGlassPurityDropdown(String name, String label, IconData icon, bool isDark, {void Function(String?)? onChanged}) {
    return FormBuilderDropdown<String>(
      name: name,
      onChanged: onChanged,
      initialValue: '21',
      validator: FormBuilderValidators.required(errorText: 'required'.tr()),
      style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.cairo(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primaryGold, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      ),
      items: ['18', '21', '22', '24']
          .map((purity) => DropdownMenuItem(
                value: purity,
                child: Text('${'purity_label'.tr()} $purity', style: GoogleFonts.cairo(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
              ))
          .toList(),
    );
  }

  Widget _buildMaterialSelector(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(isDark ? 0.6 : 0.3),
            width: isDark ? 1.5 : 1.2,
          ),
        ),
        child: FormBuilderDropdown<String>(
          name: 'material_type',
          initialValue: _selectedMaterialType,
          onChanged: (val) {
            setState(() {
              _selectedMaterialType = val ?? 'gold';
            });
          },
          validator: FormBuilderValidators.required(errorText: 'required'.tr()),
          style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'material_type'.tr(),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            labelStyle: GoogleFonts.cairo(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
            prefixIcon: const Icon(Icons.tune_rounded, color: AppColors.primaryGold, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          items: [
            DropdownMenuItem(value: 'gold', child: Text('gold'.tr(), style: GoogleFonts.cairo())),
            DropdownMenuItem(value: 'silver', child: Text('silver'.tr(), style: GoogleFonts.cairo())),
            DropdownMenuItem(value: 'gemstone', child: Text('gemstone'.tr(), style: GoogleFonts.cairo())),
          ],
        ),
      ),
    );
  }



  Widget _buildGlassCategorySelector(bool isDark, AppState appState) {
    return FormBuilderField<String>(
      name: 'category_id',
      validator: FormBuilderValidators.required(errorText: 'required'.tr()),
      builder: (FormFieldState<String?> field) {
        final selectedCategoryName = appState.categories.firstWhere(
          (cat) => cat['id'].toString() == field.value,
          orElse: () => {'name': 'pick_section'.tr()},
        )['name'];

        return InkWell(
          onTap: () => _showCategoryPicker(field, appState, isDark),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: field.hasError ? Colors.red.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category_rounded, color: AppColors.primaryGold, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'royal_section'.tr(),
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Text(
                        selectedCategoryName,
                        style: TextStyle(
                          color: field.value == null ? (isDark ? Colors.white38 : Colors.black38) : (isDark ? Colors.white : Colors.black87),
                          fontWeight: field.value != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : Colors.black38),
                  ],
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 32),
                    child: Text(field.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPicker(FormFieldState<String?> field, AppState appState, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final sheetBg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subColor = isDark ? Colors.white60 : Colors.black54;

        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(Icons.category_rounded, color: AppColors.primaryGold),
                    const SizedBox(width: 12),
                    Text(
                      'pick_section'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 40),
                  itemCount: appState.categories.length,
                  separatorBuilder: (_, __) => Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  itemBuilder: (ctx, index) {
                    final cat = appState.categories[index];
                    final isSelected = field.value == cat['id'].toString();
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          field.didChange(cat['id'].toString());
                          Navigator.pop(sheetContext);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cat['name'],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primaryGold : textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold)
                              else
                                Icon(Icons.chevron_left_rounded, color: subColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context, AppState appState) {
    return GoldGradientButton(
      text: widget.product != null ? 'submit_edit'.tr() : 'submit_new'.tr(),
      isLoading: appState.isLoading,
      onPressed: () async {
          if (_formKey.currentState!.saveAndValidate()) {
            final data = Map<String, dynamic>.from(_formKey.currentState!.value);
            
            data['weight'] = double.tryParse(data['weight'].toString()) ?? 0.0;
            data['stone_weight'] = double.tryParse(data['stone_weight']?.toString() ?? '') ?? 0.0;
            data['type'] = 'jewelry';
            data['is_featured'] = widget.product?.isFeatured == true ? 1 : 0; 
            data['stock_quantity'] = int.tryParse(data['stock_quantity'].toString()) ?? 1;
            data['manage_stock'] = 1;

            // Ensure purity is null for gemstones
            if (data['material_type'] == 'gemstone') {
              data['purity'] = null;
            }
            
            if (_selectedImages.isNotEmpty) {
              data['images'] = _selectedImages;
            }

            // If we are in edit mode and images changed, tell backend
            if (widget.product != null) {
              // Check if any existing images were removed
              final removedImages = _originalExistingImages
                  .where((url) => !_existingImages.contains(url))
                  .toList();
              
              if (_selectedImages.isNotEmpty && removedImages.length == _originalExistingImages.length) {
                // User replaced ALL old images → tell backend to clear old ones
                data['replace_images'] = 1;
              } else if (removedImages.isNotEmpty) {
                // Partial deletions — but since we only have URLs not IDs from the API,
                // if user removed some and added new ones, do a full replace for safety
                if (_selectedImages.isNotEmpty) {
                  data['replace_images'] = 1;
                }
              }
            }

            final success = widget.product == null 
                ? await appState.addProduct(data)
                : await appState.updateProduct(widget.product!.id, data);
            
            if (success) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.product == null ? 'product_insert_success'.tr() : 'product_update_success'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.primaryGold,
                ),
              );
              Navigator.pop(context);
            } else {
              if (!mounted) return;
              final errorMsg = appState.lastError ?? 'action_failed'.tr();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg, style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
      },
    );
  }
}
