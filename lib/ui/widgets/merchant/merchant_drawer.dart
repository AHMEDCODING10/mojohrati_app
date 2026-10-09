import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../state/app_state.dart';
import '../../../state/theme_state.dart';
import '../../screens/merchant/store_settings_screen.dart';
import '../../screens/customer/misc_screens.dart';
import '../../screens/customer/zakat_calculator_screen.dart';
import '../../screens/tools/currency_converter_screen.dart';
import '../../screens/merchant/merchant_custom_designs_screen.dart';
import '../../../utils/localization_service.dart';

class MerchantDrawer extends StatelessWidget {
  final Function(int)? onItemTap;
  const MerchantDrawer({super.key, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeState = context.watch<ThemeState>();
    final user = appState.currentUser;
    final isDark = themeState.effectiveDarkMode(context);
    final int pendingDesignsCount = appState.merchantCustomDesigns.where((d) => d['status'] == 'pending').length;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Frosted Glass Background
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.black.withOpacity(0.8) 
                        : Colors.white.withOpacity(0.85),
                    gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
                  ),
                ),
              ),
            ),
            
            Column(
              children: [
                _buildModernRoyalHeader(context, user, isDark),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      left: 16, 
                      right: 16, 
                      top: 20, 
                      bottom: MediaQuery.of(context).padding.bottom + 100
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSectionHeader('main_sections'.tr(), isDark),
                      _buildMerchantRoyalCard(
                        context, 
                        Icons.dashboard_rounded, 
                        'nav_home'.tr(), 
                        index: 0,
                        isDark: isDark
                      ),
                      const SizedBox(height: 12),
                      _buildMerchantRoyalCard(
                        context, 
                        Icons.color_lens_rounded, 
                        'store_identity_title'.tr(), 
                        destination: const MerchantStoreSettingsScreen(),
                        isDark: isDark
                      ),
                      const SizedBox(height: 12),
                      _buildMerchantRoyalCard(
                        context,
                        Icons.design_services_rounded,
                        'طلبات التصميم الخاص',
                        destination: const MerchantCustomDesignsScreen(),
                        isDark: isDark,
                        badgeCount: pendingDesignsCount,
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader('useful_tools'.tr(), isDark),
                      _buildMerchantRoyalCard(
                        context, 
                        Icons.straighten_rounded, 
                        'ring_size_guide'.tr(), 
                        destination: const SizeGuideScreen(),
                        isDark: isDark
                      ),
                      const SizedBox(height: 12),
                      _buildMerchantRoyalCard(
                        context, 
                        Icons.calculate_rounded, 
                        'zakat_calc_title'.tr(), 
                        destination: const ZakatCalculatorScreen(),
                        isDark: isDark,
                        accent: AppColors.primaryGold.withOpacity(0.1),
                      ),
                      const SizedBox(height: 12),
                      _buildMerchantRoyalCard(
                        context, 
                        Icons.currency_exchange_rounded, 
                        'currency_conv_title'.tr(), 
                        destination: const CurrencyConverterScreen(),
                        isDark: isDark
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('royal_settings'.tr(), isDark),
                      _buildThemeToggleCard(themeState, isDark),
                      const SizedBox(height: 12),
                      _buildMerchantRoyalCard(
                        context, 
                        Icons.person_rounded, 
                        'nav_profile'.tr(), 
                        index: 3,
                        isDark: isDark
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader('information_center'.tr(), isDark),
                      _buildSimpleTile(context, Icons.info_outline, 'about_us'.tr(), const AboutUsScreen(), isDark),
                      _buildSimpleTile(context, Icons.privacy_tip_outlined, 'privacy_policy'.tr(), const PrivacyPolicyScreen(), isDark),
                      _buildSimpleTile(context, Icons.description_outlined, 'terms_of_use'.tr(), const TermsScreen(), isDark),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRoyalHeader(BuildContext context, user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 32, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: AppColors.liquidGold,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(50)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.white, AppColors.primaryGold]),
                ),
                child: CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  backgroundImage: (user?.storeLogo != null && user!.storeLogo!.isNotEmpty)
                      ? NetworkImage(user.storeLogo!)
                      : const AssetImage(AppConstants.logoPlaceholder) as ImageProvider,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.blueGrey, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  user?.storeName ?? user?.name ?? 'luxury_store'.tr(),
                  style: GoogleFonts.cairo(
                    color: Colors.black87, 
                    fontSize: 18, 
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user?.isVerified == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'verified_merchant'.tr(), 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? user?.phone ?? 'merchant_dashboard_title'.tr(),
            style: GoogleFonts.cairo(
              color: Colors.black54, 
              fontSize: 12, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, bottom: 12, top: 12),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.primaryGold.withOpacity(0.8) : AppColors.primaryGold,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMerchantRoyalCard(
    BuildContext context, 
    IconData icon, 
    String title, 
    {Widget? destination, int? index, required bool isDark, Color? accent, int badgeCount = 0}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: accent ?? (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.primaryGold.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            if (index != null && onItemTap != null) {
              Navigator.pop(context); // Only pop if we are just switching tabs in the wrapper
              onItemTap!(index);
            } else if (destination != null) {
              // Don't pop here so it stays open when we come back
              Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
            }
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.liquidGold,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.black87, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }




  Widget _buildThemeToggleCard(ThemeState themeState, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: themeState.isDarkMode,
            onChanged: (v) => themeState.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
            activeTrackColor: AppColors.primaryGold,
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
                color: AppColors.primaryGold, 
                size: 20
              ),
            ),
            title: Text(
              'dark_mode'.tr(),
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          if (!themeState.isSystemMode)
            TextButton(
              onPressed: () => themeState.setThemeMode(ThemeMode.system),
              child: Text('التفعيل حسب وضع الهاتف', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primaryGold)),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleTile(BuildContext context, IconData icon, String title, Widget destination, bool isDark) {
    return ListTile(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      leading: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 20),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14, 
          color: isDark ? Colors.white60 : Colors.black54,
          fontWeight: FontWeight.w600
        ),
      ),
      dense: true,
    );
  }
}
