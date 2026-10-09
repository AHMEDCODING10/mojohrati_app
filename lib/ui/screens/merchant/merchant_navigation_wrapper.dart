import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import 'dashboard_screen.dart';
import 'my_products_screen.dart';
import 'merchant_bookings_screen.dart';
import 'add_product_screen.dart';
import 'merchant_verification_screen.dart';
import '../customer/profile_screen.dart';
import '../../widgets/merchant/merchant_drawer.dart';

class MerchantNavigationWrapper extends StatefulWidget {
  const MerchantNavigationWrapper({super.key});

  @override
  State<MerchantNavigationWrapper> createState() => _MerchantNavigationWrapperState();
}

class _MerchantNavigationWrapperState extends State<MerchantNavigationWrapper> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _screens = [
    MerchantDashboardScreen(
      onDrawerItemTap: (index) => _onItemTapped(index),
      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
    ),
    MyProductsScreen(
      onDrawerItemTap: (index) => _onItemTapped(index),
      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
    ),
    MerchantBookingsScreen(
      onDrawerItemTap: (index) => _onItemTapped(index),
      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
    ),
    ProfileScreen(
      onDrawerItemTap: (index) => _onItemTapped(index),
      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
    ),
  ];

  Future<bool> _onWillPop() async {
    // If not on dashboard tab, navigate to dashboard tab instead of exiting
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    // On dashboard tab: double-tap to exit
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'اضغط مرة أخرى للخروج',
            style: GoogleFonts.cairo(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        extendBody: true,
        drawer: MerchantDrawer(
          onItemTap: _onItemTapped,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        floatingActionButton: _buildGlassyFAB(isDark),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildFloatingBottomNav(isDark),
      ),
    );
  }

  Widget _buildGlassyFAB(bool isDark) {
    return Container(
      width: 70,
      height: 70,
      margin: const EdgeInsets.only(top: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Glass Button
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGold.withValues(alpha: 0.7),
                      AppColors.primaryGold.withValues(alpha: 0.3),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      final appState = context.read<AppState>();
                      final user = appState.currentUser;
                      final isVerified = user?.isVerified == true;

                      if (!isVerified) {
                        // Show verification required dialog
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            final isDark = Theme.of(ctx).brightness == Brightness.dark;
                            return Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1C1C2E) : Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, -10)),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.amber.withValues(alpha: 0.1),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                    ),
                                    child: const Icon(Icons.verified_user_outlined, color: Colors.amber, size: 32),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'يجب توثيق الحساب أولاً',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'لا يمكنك نشر منتجات قبل توثيق حسابك من قِبل الإدارة. يرجى رفع وثائق التاجر من صفحة التوثيق وانتظار قبول الإدارة.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                      height: 1.7,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const MerchantVerificationScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.upload_file_outlined),
                                      label: const Text('رفع وثائق التوثيق'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryGold,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('إغلاق', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddProductScreen()),
                      );
                    },
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav(bool isDark) {
    final appState = context.watch<AppState>();
    return BottomAppBar(
      height: 75,
      padding: EdgeInsets.zero,
      notchMargin: 12,
      shape: const CircularNotchedRectangle(),
      color: isDark ? AppColors.matteBlack.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'nav_home'.tr(), 0, isDark),
          _buildNavItem(Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'my_products'.tr(), 1, isDark),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'bookings'.tr(), 2, isDark, badgeCount: appState.bookingsCount),
          _buildNavItem(Icons.person_rounded, Icons.person_outline, 'nav_profile'.tr(), 3, isDark),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index, bool isDark, {int badgeCount = 0}) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? activeIcon : inactiveIcon,
                    size: 24,
                    color: isActive ? AppColors.primaryGold : (isDark ? Colors.white38 : Colors.black38),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.primaryGold : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
