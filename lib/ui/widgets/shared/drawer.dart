import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../state/app_state.dart';
import '../../../state/theme_state.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../utils/localization_service.dart';
import '../../screens/customer/zakat_calculator_screen.dart';
import '../../screens/tools/currency_converter_screen.dart';
import '../../screens/customer/misc_screens.dart';
import '../../screens/customer/custom_design_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeState = context.watch<ThemeState>();
    final user = appState.currentUser;
    final isDark = themeState.effectiveDarkMode(context);

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75, // reduced width
      child: Drawer(
        backgroundColor: Colors.transparent, // Background handled by BackdropFilterContainer
      child: Stack(
        children: [
          // 1. Frosted Glass Background
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionHeader('main_sections'.tr(), isDark),
                    _buildRoyalCard(
                      context, 
                      Icons.auto_awesome_rounded, 
                      'custom_design'.tr(), 
                      const CustomDesignOrderScreen(),
                      isDark
                    ),
                    
                    const SizedBox(height: 12),
                    _buildSectionHeader('useful_tools'.tr(), isDark),
                    // Quick Action Row for Tools
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickTool(
                            context,
                            Icons.currency_exchange_rounded,
                            'currency_conv'.tr(), 
                            const CurrencyConverterScreen(),
                            isDark
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickTool(
                            context,
                            Icons.calculate_rounded,
                            'zakat_tool'.tr(),
                            const ZakatCalculatorScreen(),
                            isDark
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    _buildRoyalCard(
                      context, 
                      Icons.straighten_rounded, 
                      'size_guide'.tr(), 
                      const SizeGuideScreen(),
                      isDark
                    ),

                    const SizedBox(height: 12),
                    _buildThemeToggleCard(themeState, isDark),

                    const SizedBox(height: 24),
                    _buildSectionHeader('information_center'.tr(), isDark),
                    _buildSimpleTile(context, Icons.info_outline, 'about_us'.tr(), const AboutUsScreen(), isDark),
                    _buildSimpleTile(context, Icons.privacy_tip_outlined, 'privacy_policy'.tr(), const PrivacyPolicyScreen(), isDark),
                    _buildSimpleTile(context, Icons.description_outlined, 'terms_of_use'.tr(), const TermsScreen(), isDark),

                    if (appState.isLoggedIn) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Divider(color: Colors.white12, thickness: 0.5),
                      ),
                      _buildLogoutTile(context, isDark),
                    ],

                    const SizedBox(height: 100), // Increased bottom padding to ensure visibility
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

  Widget _buildLogoutTile(BuildContext context, bool isDark) {
    return ListTile(
      onTap: () {
        // Confirm logout or just logout
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('logout_confirm_title'.tr(), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: Text('logout_confirm_msg'.tr(), style: GoogleFonts.cairo()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr(), style: const TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Close drawer
                  context.read<AppState>().logout();
                },
                child: Text('logout'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
      title: Text(
        'logout'.tr(),
        style: GoogleFonts.cairo(
          fontSize: 14, 
          color: Colors.redAccent,
          fontWeight: FontWeight.w700
        ),
      ),
      dense: true,
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
                  backgroundImage: user?.type == 'merchant' 
                      ? NetworkImage(user.storeLogo ?? user.profileImage)
                      : (user?.profileImage != null && user!.profileImage!.isNotEmpty)
                          ? NetworkImage(user.profileImage!)
                          : const NetworkImage(AppConstants.logoPlaceholder),
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
          Text(
            user?.name ?? 'guest_user'.tr(),
            style: GoogleFonts.cairo(
              color: Colors.black87, 
              fontSize: 18, 
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? user?.phone ?? 'royal_welcome_desc'.tr(),
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
        title, // removed toUpperCase() for Arabic compatibility
        style: TextStyle(
          color: isDark ? AppColors.primaryGold.withOpacity(0.8) : AppColors.primaryGold,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildRoyalCard(BuildContext context, IconData icon, String title, Widget destination, bool isDark, {Color? accent}) {
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
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
          title: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14, 
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }

  Widget _buildQuickTool(BuildContext context, IconData icon, String title, Widget destination, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGold, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
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
