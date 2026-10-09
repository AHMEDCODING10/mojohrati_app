// ignore_for_file: use_build_context_synchronously, deprecated_member_use, curly_braces_in_flow_control_structures, avoid_unnecessary_containers
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../state/app_state.dart';
import '../../../state/theme_state.dart';
import '../auth/auth_screen.dart';
// Kept for backwards compatibility if needed elsewhere
import '../auth/change_password_screen.dart';
import '../shared/support_screen.dart';
import '../../../utils/localization_service.dart';

class ProfileScreen extends StatelessWidget {
  final Function(int)? onDrawerItemTap;
  final VoidCallback? onOpenDrawer;
  const ProfileScreen({super.key, this.onDrawerItemTap, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeState = context.watch<ThemeState>();
    final user = appState.currentUser;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: themeState.effectiveDarkMode(context) ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text('profile_title'.tr()),
                leading: onDrawerItemTap != null ? Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu_rounded, color: themeState.effectiveDarkMode(context) ? AppColors.primaryGold : Colors.black87),
                    onPressed: () {
                      if (onOpenDrawer != null) {
                        onOpenDrawer!();
                      } else {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                  ),
                ) : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildUserInfo(context, user),
                      const SizedBox(height: 40),
                      const SizedBox(height: 20),
                      _buildMenuSection(context, themeState, [
                        _buildMenuItem(
                          context,
                          Icons.dark_mode_outlined,
                          'dark_mode'.tr(),
                          () => _showThemeDialog(context, themeState),
                          trailing: Text(
                            _getThemeName(themeState.themeMode),
                            style: const TextStyle(color: AppColors.primaryGold, fontSize: 12),
                          ),
                        ),
                        _buildMenuItem(context, Icons.language_outlined, 'language'.tr(), () => _showLanguageDialog(context, appState)),
                        _buildMenuItem(context, Icons.lock_outline_rounded, 'change_password'.tr(), () {
                          if (!appState.isLoggedIn || appState.currentUser?.type == 'guest') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('guest_restriction_msg'.tr(), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                        }),
                        _buildMenuItem(context, Icons.help_outline, 'help_support'.tr(), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                        }),
                        _buildMenuItem(context, Icons.logout_rounded, 'logout'.tr(), () {
                          appState.logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                            (route) => false,
                          );
                        }),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(user?.profileImage ?? AppConstants.placeholderImage),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'username_placeholder'.tr(), 
          style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold)
        ),
        Text(
          user?.email ?? user?.phone ?? 'user@example.com', 
          style: GoogleFonts.cairo(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, ThemeState themeState, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: themeState.effectiveDarkMode(context)
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback? onTap, {Widget? trailing}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryGold, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          trailing ?? Icon(Icons.chevron_left, size: 16, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                appState.setLocale(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('english'.tr()),
              leading: Radio<Locale>(
                value: const Locale('en'),
                groupValue: appState.locale,
                onChanged: (v) {
                  appState.setLocale(v!);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                appState.setLocale(const Locale('en'));
                Navigator.pop(context);
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
}