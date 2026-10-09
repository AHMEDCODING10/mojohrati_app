import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../models/product.dart';
import '../../../state/app_state.dart';
import '../../widgets/custom/product_card.dart';
import '../customer/product_details_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/localization_service.dart';

// --- البحث بجرام معين ---
class GramSearchScreen extends StatefulWidget {
  const GramSearchScreen({super.key});

  @override
  State<GramSearchScreen> createState() => _GramSearchScreenState();
}

class _GramSearchScreenState extends State<GramSearchScreen> {
  RangeValues _currentRange = const RangeValues(1, 50);
  String _selectedCategory = 'all';
  String _selectedKarat = 'all';
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filter();
    });
  }

  void _filter() {
    final appState = context.read<AppState>();
    setState(() {
      _filteredProducts = appState.products.where((p) {
        final matchesWeight = p.weight >= _currentRange.start && p.weight <= _currentRange.end;
        final matchesCategory = _selectedCategory == 'all' || p.category == _selectedCategory;
        final matchesKarat = _selectedKarat == 'all' || p.karat == _selectedKarat;
        return matchesWeight && matchesCategory && matchesKarat;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'gram_search_title'.tr(),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                color: AppColors.primaryGold.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('weight_range_label'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    RangeSlider(
                      values: _currentRange,
                      min: 1,
                      max: 100,
                      divisions: 100,
                      activeColor: AppColors.primaryGold,
                      labels: RangeLabels('${_currentRange.start.round()}', '${_currentRange.end.round()}'),
                      onChanged: (v) {
                        setState(() => _currentRange = v);
                        _filter();
                      },
                    ),
                    Text('found_pieces_count'.tr().replaceAll('{}', '${_filteredProducts.length}'), style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildFilterDropdown('التصنيف', _selectedCategory, ['all', 'Rings', 'Necklaces', 'Bracelets', 'Earrings'], (v) {
                          setState(() => _selectedCategory = v!);
                          _filter();
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _buildFilterDropdown('العيار', _selectedKarat, ['all', 'K24', 'K22', 'K21', 'K18'], (v) {
                          setState(() => _selectedKarat = v!);
                          _filter();
                        })),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: _filteredProducts[index],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: _filteredProducts[index]))),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: Container(height: 1, color: AppColors.primaryGold.withOpacity(0.3)),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o == 'all' ? 'الكل' : o, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// --- معرفة القياس ---
class SizeGuideScreen extends StatefulWidget {
  const SizeGuideScreen({super.key});

  @override
  State<SizeGuideScreen> createState() => _SizeGuideScreenState();
}

class _SizeGuideScreenState extends State<SizeGuideScreen> {
  double _diameter = 16.5; // Average initial diameter (approx US 6)
  int _selectedSystem = 0; // 0: Gold (Asian/HK), 1: Silver (US)

  final List<String> _systems = ['ذهب', 'فضة'];

  String _getConvertedSize() {
    final circumference = _diameter * 3.1415926535;
    
    switch (_selectedSystem) {
      case 0: // Gold (Asian/HK Standard: 1-30)
        final size = circumference - 38.0;
        return size.clamp(1.0, 30.0).toStringAsFixed(0);
      case 1: // Silver (US/Canada Standard: 2-15.5)
        final size = (circumference - 36.5) / 2.55;
        return size.clamp(2.0, 15.5).toStringAsFixed(1);
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'ring_size_guide'.tr(),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGold,
            fontSize: 22,
          ),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'sizing_instructions_header'.tr(),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: AppColors.primaryGold
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'sizing_instructions_body'.tr(),
                  style: GoogleFonts.cairo(fontSize: 13, height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 32),
                
                // Four Sizing Systems Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: List.generate(2, (index) {
                      final isSelected = _selectedSystem == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() => _selectedSystem = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryGold : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isSelected ? [
                                BoxShadow(color: AppColors.primaryGold.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                              ] : null,
                            ),
                            child: Text(
                              _systems[index],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.black : (isDark ? Colors.white60 : Colors.black54),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Interactive Sizing Area
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        width: 220,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryGold.withOpacity(0.1)),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 50),
                          width: _diameter * 6,
                          height: _diameter * 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.primaryGold, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGold.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Unified Size Display
                      Center(
                        child: Column(
                          children: [
                            Text(
                              _getConvertedSize(),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 64, 
                                fontWeight: FontWeight.bold, 
                                color: AppColors.primaryGold,
                                letterSpacing: -2,
                              ),
                            ),
                            Text(
                              'قياس ${_systems[_selectedSystem]}',
                              style: GoogleFonts.cairo(
                                fontSize: 14, 
                                color: isDark ? Colors.white54 : Colors.black54,
                                height: 0.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'diameter_label'.tr().replaceAll('{}', _diameter.toStringAsFixed(1)),
                              style: GoogleFonts.cairo(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Controls Panel
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'diameter_control_header'.tr(),
                                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                                ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryGold),
                                        onPressed: () {
                                          if (_diameter > 10) {
                                            HapticFeedback.lightImpact();
                                            setState(() => _diameter = (_diameter - 0.1).clamp(10.0, 25.0));
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: _diameter,
                                          min: 10.0,
                                          max: 25.0,
                                          activeColor: AppColors.primaryGold,
                                          inactiveColor: isDark ? Colors.white10 : Colors.black12,
                                          onChanged: (v) {
                                            HapticFeedback.selectionClick();
                                            setState(() => _diameter = v);
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGold),
                                        onPressed: () {
                                          if (_diameter < 25) {
                                            HapticFeedback.lightImpact();
                                            setState(() => _diameter = (_diameter + 0.1).clamp(10.0, 25.0));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                Text('royal_tip_label'.tr(), style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                const SizedBox(height: 8),
                Text(
                  'royal_tip_body'.tr(),
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }


}

// --- المعلومات ---
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'about_us_title'.tr(),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          bottom: false, // Handle padding manually below
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Hero Section with Circular Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.2), width: 1),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AppConstants.logoPlaceholder, 
                          height: 120, 
                          width: 120, 
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ).animate().scale(delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                ),
                const SizedBox(height: 48),

                // Intro Text
                Text(
                  'about_intro'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    color: AppColors.primaryGold,
                    height: 1.4,
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms).fadeIn(),
                const SizedBox(height: 24),
                
                Text(
                  'about_p1'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 14, height: 1.8, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 20),
                
                Text(
                  'about_p2'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 14, height: 1.8, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),

                // Mission & Vision
                Row(
                  children: [
                    Expanded(child: _buildInfoCard('our_mission_title'.tr(), 'our_mission_desc'.tr(), Icons.auto_awesome_rounded, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInfoCard('our_vision_title'.tr(), 'our_vision_desc'.tr(), Icons.visibility_rounded, isDark)),
                  ],
                ).animate().slideY(begin: 0.1, end: 0, delay: 400.ms).fadeIn(),
                const SizedBox(height: 48),

                // Values Section
                _buildSectionHeader('our_values_title'.tr()),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildValueChip('value_excellence'.tr(), Icons.verified_rounded, isDark),
                    _buildValueChip('value_trust'.tr(), Icons.security_rounded, isDark),
                    _buildValueChip('value_heritage'.tr(), Icons.history_edu_rounded, isDark),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 60),
                
                Text(
                  '© 2024 MOJOHRTI PRO. ALL RIGHTS RESERVED.',
                  style: GoogleFonts.playfairDisplay(fontSize: 10, letterSpacing: 2, color: Colors.grey.withOpacity(0.5)),
                ),
                
                const SizedBox(height: 100), // Increased bottom padding to ensure visibility of all text
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String desc, IconData icon, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryGold, size: 32),
              const SizedBox(height: 16),
              Text(title, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
              const SizedBox(height: 12),
              Text(
                desc, 
                textAlign: TextAlign.center, 
                style: GoogleFonts.cairo(fontSize: 12, height: 1.6, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 16),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.primaryGold, thickness: 0.5, endIndent: 20)),
        Text(title, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
        const Expanded(child: Divider(color: AppColors.primaryGold, thickness: 0.5, indent: 20)),
      ],
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('privacy_policy_title'.tr()),
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
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildPolicySection('privacy_intro'.tr(), 'privacy_p1'.tr(), Icons.security_rounded, isDark, 0),
              _buildPolicySection('policy_use_title'.tr() == 'policy_use_title' ? 'البيانات واستخدامها' : 'policy_use_title'.tr(), 'privacy_p2'.tr(), Icons.data_usage_rounded, isDark, 1),
              _buildPolicySection('policy_sharing_title'.tr() == 'policy_sharing_title' ? 'مشاركة البيانات' : 'policy_sharing_title'.tr(), 'privacy_p3'.tr(), Icons.share_rounded, isDark, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content, IconData icon, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primaryGold, size: 24),
                    const SizedBox(width: 12),
                    Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  style: GoogleFonts.cairo(fontSize: 14, height: 1.8, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
        ).animate().slideY(begin: 0.1, end: 0, delay: (index * 100).ms).fadeIn(),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('terms_of_use_title'.tr()),
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
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildPolicySection('terms_intro'.tr(), 'terms_p1'.tr(), Icons.gavel_rounded, isDark, 0),
              _buildPolicySection('terms_responsibilities_title'.tr() == 'terms_responsibilities_title' ? 'مسؤوليات الأطراف' : 'terms_responsibilities_title'.tr(), 'terms_p2'.tr(), Icons.assignment_ind_rounded, isDark, 1),
              _buildPolicySection('terms_updates_title'.tr() == 'terms_updates_title' ? 'تحديث الأحكام' : 'terms_updates_title'.tr(), 'terms_p3'.tr(), Icons.update_rounded, isDark, 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content, IconData icon, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primaryGold, size: 24),
                    const SizedBox(width: 12),
                    Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  style: GoogleFonts.cairo(fontSize: 14, height: 1.8, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
        ).animate().slideY(begin: 0.1, end: 0, delay: (index * 100).ms).fadeIn(),
      ),
    );
  }
}
