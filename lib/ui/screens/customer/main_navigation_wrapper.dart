import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/colors.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'bookings_screen.dart';
import '../shared/notifications_screen.dart';
import '../../widgets/shared/drawer.dart';
import '../../../state/favorites_state.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _appState.addListener(_notificationListener);
    
    // Initial fetch to sync badge counts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _appState.fetchNotifications(silently: true);
      }
    });
  }

  @override
  void dispose() {
    _appState.removeListener(_notificationListener);
    super.dispose();
  }

  void _notificationListener() {
    if (!mounted) return;
    
    if (_appState.hasNewNotifications) {
      final payload = _appState.latestNotificationPayload;
      _appState.clearNotificationAlert();
      _showTopNotification(context, payload);
    }
  }

  void _showTopNotification(BuildContext context, Map<String, dynamic>? payload) {
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final title = payload?['title']?.toString() ?? 'new_notification_received'.tr();
    final message = payload?['message']?.toString() ?? 'check_notifications_tab'.tr();

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.primaryGold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, 
                          color: isDark ? Colors.white : Colors.black87
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        message,
                        style: GoogleFonts.cairo(
                          fontSize: 12, 
                          color: isDark ? Colors.white70 : Colors.black54
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    overlayEntry.remove();
                    // Custom logic: switch to profile/notifications if needed or just push
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  }, 
                  child: Text('view'.tr(), style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold))
                ),
              ],
            ),
          ),
        ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOutBack).fadeOut(delay: 4.seconds),
      ),
    );

    overlay.insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const BookingsScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  Future<bool> _onWillPop() async {
    // If not on home tab, navigate to home tab instead of exiting
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    // On home tab: double-tap to exit
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
        extendBody: true,
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildFloatingBottomNav(isDark),
      ),
    );
  }

   Widget _buildFloatingBottomNav(bool isDark) {
    final favoritesState = context.watch<FavoritesState>();
    final favCount = favoritesState.favoriteIds.length;

    final appState = context.watch<AppState>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.matteBlack : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          if (index == 2) {
            context.read<AppState>().markBookingNotificationsRead();
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primaryGold,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGold,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 10,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        items: [
          _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'nav_home'.tr(), 0),
          _buildNavItem(Icons.grid_view_rounded, Icons.grid_view, 'nav_categories'.tr(), 1),
          _buildNavItem(Icons.bookmark_added_rounded, Icons.bookmark_added_outlined, 'nav_bookings'.tr(), 2, badgeCount: appState.unreadBookingUpdatesCount),
          _buildNavItem(Icons.favorite_rounded, Icons.favorite_outline_rounded, 'nav_favorites'.tr(), 3, badgeCount: favCount),
          _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'nav_profile'.tr(), 4),
        ],
      ),
    );
  }

   BottomNavigationBarItem _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index, {int badgeCount = 0}) {
    final isActive = _currentIndex == index;
    Widget iconWidget = Icon(isActive ? activeIcon : inactiveIcon, size: 24);
    
    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
        backgroundColor: Colors.red,
        child: iconWidget,
      );
    }

    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: iconWidget,
      ),
      label: label,
      tooltip: label,
    );
  }
}
