import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _weightRange = const RangeValues(0.5, 200);
  String? _selectedPurity;
  String? _selectedCategoryId;

  final List<String> _purities = ['18', '21', '22', '24'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'تصفية النتائج',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Category Selection
          _buildCategorySelection(isDark),
          
          const SizedBox(height: 32),
          
          
          const SizedBox(height: 24),

          // Weight Range
          _buildRangeSlider(
            title: 'الوزن (جرام)',
            values: _weightRange,
            min: 0.5,
            max: 200,
            divisions: 399,
            onChanged: (values) => setState(() => _weightRange = values),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Karat Selection
          Text(
            'قيراط الذهب',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: _purities.map((purity) {
              final isSelected = _selectedPurity == purity;
              return ChoiceChip(
                label: Text(purity),
                selected: isSelected,
                selectedColor: AppColors.primaryGold,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedPurity = selected ? purity : null;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 40),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _weightRange = const RangeValues(0.5, 200);
                      _selectedPurity = null;
                      _selectedCategoryId = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     side: const BorderSide(color: AppColors.primaryGold),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('إلغاء التصفية', style: TextStyle(color: AppColors.primaryGold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AppState>().fetchProducts(
                      minWeight: _weightRange.start,
                      maxWeight: _weightRange.end,
                      purity: _selectedPurity,
                      categoryId: _selectedCategoryId,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('تطبيق التصفية', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRangeSlider({
    required String title,
    required RangeValues values,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Text(
              '${values.start.round()} - ${values.end.round()}',
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primaryGold,
          inactiveColor: isDark ? Colors.grey[800] : Colors.grey[300],
          labels: RangeLabels(
            values.start.round().toString(),
            values.end.round().toString(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCategorySelection(bool isDark) {
    final appState = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التصنيف والأقسام',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: appState.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = appState.categories[index];
              final isSelected = _selectedCategoryId == category['id'].toString();
              return ChoiceChip(
                label: Text(category['name'] ?? ''),
                selected: isSelected,
                selectedColor: AppColors.primaryGold,
                backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryId = selected ? category['id'].toString() : null;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

}
