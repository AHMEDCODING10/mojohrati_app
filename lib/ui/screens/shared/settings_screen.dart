import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../../../state/theme_state.dart';
import '../../../state/app_state.dart';
import '../customer/profile_screen.dart';
import '../auth/change_password_screen.dart';
import '../../../utils/localization_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeState>();
    final isDark = themeState.effectiveDarkMode(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionHeader('account_settings_section'.tr(), isDark),
                    _buildSettingTile(Icons.person_outline_rounded, 'profile_title'.tr(), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), isDark),
                    _buildSettingTile(Icons.lock_reset_rounded, 'change_password'.tr(), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())), isDark),
                    _buildSettingTile(Icons.notifications_none_rounded, 'customize_notifications'.tr(), () {}, isDark),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('interface_settings_section'.tr(), isDark),
                    _buildSettingTile(
                      Icons.dark_mode_outlined, 
                      'app_theme'.tr(), 
                      () => _showThemeDialog(context, themeState), 
                      isDark,
                      trailing: Text(
                        _getThemeName(themeState.themeMode),
                        style: const TextStyle(color: AppColors.primaryGold, fontSize: 12),
                      ),
                    ),
                    _buildSettingTile(Icons.language_rounded, '${'language'.tr()} (${context.read<AppState>().locale.languageCode == 'ar' ? 'arabic'.tr() : 'english'.tr()})', () => _showLanguageDialog(context), isDark),
                    
                    const SizedBox(height: 48),
                    _buildDeleteAccountBtn(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildLogoutBtn(context, themeState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'settings_title'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryGold,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback? onTap, bool isDark, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGold, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          trailing: trailing ?? const Icon(Icons.chevron_left_rounded, size: 18, color: AppColors.primaryGold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }


  Widget _buildLogoutBtn(BuildContext context, ThemeState themeState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<AppState>().performLogout();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        icon: const Icon(Icons.logout_rounded),
        label: Text('logout'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeState.isDarkMode ? Colors.white10 : Colors.black12,
          foregroundColor: themeState.isDarkMode ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final appState = context.read<AppState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('choose_language'.tr(), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('arabic'.tr()),
              leading: Radio<Locale>(
                value: const Locale('ar'),
                groupValue: appState.locale,
                onChanged: (v) {
                  appState.setLocale(v!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                appState.setLocale(const Locale('ar'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('english'.tr()),
              leading: Radio<Locale>(
                value: const Locale('en'),
                groupValue: appState.locale,
                onChanged: (v) {
                  appState.setLocale(v!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                appState.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'theme_system'.tr();
      case ThemeMode.light: return 'theme_light'.tr();
      case ThemeMode.dark: return 'theme_dark'.tr();
    }
  }

  void _showThemeDialog(BuildContext context, ThemeState themeState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('choose_theme'.tr(), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(context, themeState, ThemeMode.system, 'theme_system'.tr(), Icons.settings_brightness_rounded),
            _buildThemeOption(context, themeState, ThemeMode.light, 'theme_light'.tr(), Icons.light_mode_rounded),
            _buildThemeOption(context, themeState, ThemeMode.dark, 'theme_dark'.tr(), Icons.dark_mode_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeState themeState, ThemeMode mode, String title, IconData icon) {
    final isSelected = themeState.themeMode == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryGold : null),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primaryGold) : null,
      onTap: () {
        themeState.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildDeleteAccountBtn() {
    return Consumer<AppState>(
      builder: (context, appState, _) {
       return Center(
          child: TextButton(
            onPressed: appState.isLoading ? null : () => _confirmDeleteAccount(context),
            child: appState.isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
              : Text(
                  'delete_account'.tr(),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, decoration: TextDecoration.underline),
                ),
          ),
        );
      }
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_account_confirm_title'.tr(), style: const TextStyle(color: Colors.redAccent)),
        content: Text('delete_account_confirm_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog first
              final success = await context.read<AppState>().deleteAccount();
              if (success && context.mounted) {
                 Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              } else if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text(context.read<AppState>().lastError ?? 'error_occurred'.tr()))
                 );
              }
            },
            child: Text('yes_delete'.tr(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
