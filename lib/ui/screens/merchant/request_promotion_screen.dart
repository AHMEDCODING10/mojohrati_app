import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../models/product.dart';
import '../../../state/app_state.dart';
import 'merchant_promotions_history_screen.dart';

class RequestPromotionScreen extends StatefulWidget {
  const RequestPromotionScreen({super.key});

  @override
  State<RequestPromotionScreen> createState() => _RequestPromotionScreenState();
}

class _RequestPromotionScreenState extends State<RequestPromotionScreen> {
  String _selectedType = 'product'; // product, category, all_categories
  int _durationWeeks = 1; // Minimum 1 week
  dynamic _selectedCategory;
  final List<Product> _selectedProducts = [];
  File? _receiptImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      state.fetchCategories();
      state.fetchProducts();
    });
  }

  double get _calculatedFee {
    double weeklyRate = 20.0;
    if (_selectedType == 'product') {
      int count = _selectedProducts.isEmpty ? 1 : _selectedProducts.length;
      weeklyRate = 20.0 * count;
    } else if (_selectedType == 'category') {
      weeklyRate = 50.0;
    } else if (_selectedType == 'all_categories') {
      weeklyRate = 120.0;
    }
    return weeklyRate * _durationWeeks;
  }

  Future<void> _pickReceiptImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedType == 'category' && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار القسم المطلوب')),
      );
      return;
    }

    if (_selectedType == 'product' && _selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صنف واحد على الأقل')),
      );
      return;
    }

    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إرفاق صورة إشعار الدفع / التحويل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = context.read<AppState>();
      final categoryId = _selectedCategory != null 
          ? (_selectedCategory is Map ? _selectedCategory['id'].toString() : _selectedCategory.id.toString())
          : null;

      final success = await appState.submitPromotionRequest(
        type: _selectedType,
        categoryId: categoryId,
        productIds: _selectedProducts.map((p) => int.parse(p.id)).toList(),
        durationWeeks: _durationWeeks,
        receiptImage: _receiptImage!,
      );

      setState(() => _isLoading = true);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب الترويج بنجاح! سيتم مراجعته من الإدارة'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MerchantPromotionsHistoryScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appState.lastError ?? 'فشل إرسال الطلب، يرجى المحاولة لاحقاً'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'طلب ترويج مميز ✨',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'طلباتي السابقة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MerchantPromotionsHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC5A059), Color(0xFF8B6914)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: Colors.black, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ترويج المنتجات وإبرازها للعملاء',
                          style: GoogleFonts.cairo(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'احصل على الأولوية الأولى في نتائج البحث والشاشة الرئيسية',
                          style: GoogleFonts.cairo(
                            color: Colors.black87,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 1. Choose Duration (Weeks)
            Text(
              '1. حدد مدة الترويج (بالأسابيع)',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? AppColors.primaryGold : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: _durationWeeks > 1
                        ? () => setState(() => _durationWeeks--)
                        : null,
                  ),
                  Column(
                    children: [
                      Text(
                        '$_durationWeeks أسبوع (${_durationWeeks * 7} يوم)',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        'أقل مدة أسبوع وتزداد بمقدار أسبوع',
                        style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => setState(() => _durationWeeks++),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Choose Promotion Scope
            Text(
              '2. اختر نوع ونطاق الترويج',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? AppColors.primaryGold : Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            _buildTypeCard(
              id: 'product',
              title: 'أصناف / منتجات معينة',
              subtitle: '\$20 للأسبوع لكل صنف محدد',
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(height: 8),
            _buildTypeCard(
              id: 'category',
              title: 'قسم معين بالكامل',
              subtitle: '\$50 للأسبوع لكافة المعروضات داخل القسم',
              icon: Icons.category_rounded,
            ),
            const SizedBox(height: 8),
            _buildTypeCard(
              id: 'all_categories',
              title: 'جميع الأقسام / المتجر بالكامل 🚀',
              subtitle: '\$120 للأسبوع لكافة منتجات المتجر بظهور أول شامل',
              icon: Icons.store_rounded,
            ),

            const SizedBox(height: 16),

            // Conditional Selectors
            if (_selectedType == 'category') ...[
              Text(
                'اختر القسم المستهدف:',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<dynamic>(
                initialValue: _selectedCategory,
                hint: const Text('-- اختر القسم --'),
                items: appState.categories.map((cat) {
                  final name = cat is Map ? cat['name'] : cat.name;
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(name ?? '', style: GoogleFonts.cairo()),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],

            if (_selectedType == 'product') ...[
              Text(
                'اختر الأصناف المراد ترويجها:',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: appState.products.map((prod) {
                  final isSelected = _selectedProducts.any((p) => p.id == prod.id);
                  return FilterChip(
                    label: Text(prod.name, style: GoogleFonts.cairo(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGold,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedProducts.add(prod);
                        } else {
                          _selectedProducts.removeWhere((p) => p.id == prod.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // 3. Receipt Upload & Calculated Price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGold),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إجمالي سعر الترويج:',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '\$${_calculatedFee.toStringAsFixed(2)} USD',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    'إرفاق صورة إشعار الدفع / التحويل:',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickReceiptImage,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? Colors.black38 : Colors.white,
                      ),
                      child: _receiptImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_receiptImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primaryGold),
                                const SizedBox(height: 6),
                                Text(
                                  'اضغط هنا لرفع صورة الإشعار',
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        'إرسال طلب الترويج والتحويل',
                        style: GoogleFonts.cairo(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedType == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedType = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGold : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: isSelected ? AppColors.primaryGold : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primaryGold : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
