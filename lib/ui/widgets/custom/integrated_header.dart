import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import '../../screens/shared/notifications_screen.dart';
import 'filter_bottom_sheet.dart';
import '../shared/reservation_bag_icon.dart';

class IntegratedHeroHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;
  const IntegratedHeroHeader({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      // Reduced total vertical space
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.matteBlack : AppColors.royalCream,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 0. Royal Branding (Centered Title & Balanced Side Icons)
          _buildTopBranding(isDark, context),
          
          const SizedBox(height: 12),
          
          // 1. Live Gold Price Bar
          _buildGoldPriceBar(context, appState, isDark),
        ],
      ),
    );
  }

  Widget _buildGoldPriceBar(BuildContext context, AppState appState, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.liquidGold,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Global price and Gram toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible( // Wrap to prevent horizontal overflow
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public_rounded, color: Colors.black54, size: 10),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${'global_ounce_price'.tr()}: ${appState.globalOuncePriceUSD.toStringAsFixed(1)} USD',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          color: Colors.black54,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Checkbox for Gram Price
              GestureDetector(
                onTap: () => appState.setShowGramPrice(!appState.showGramPrice),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: appState.showGramPrice,
                        onChanged: (v) => appState.setShowGramPrice(v ?? false),
                        activeColor: Colors.black,
                        checkColor: AppColors.primaryGold,
                        side: const BorderSide(color: Colors.black54, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'gram_price'.tr(),
                      style: GoogleFonts.cairo(
                        color: Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Bottom row: Main price and Selectors
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.black, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appState.formattedGoldPriceDisplay,
                  style: GoogleFonts.cairo(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              _buildSmallSelector(
                currentValue: appState.selectedCurrency,
                options: ['YER', 'SAR', 'USD'],
                onChanged: (v) => appState.setSelectedCurrency(v!),
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildSmallSelector(
                currentValue: appState.selectedUnit,
                options: ['K24', 'K22', 'K21', 'K18'],
                onChanged: (v) => appState.setSelectedUnit(v!),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBranding(bool isDark, BuildContext context) {
    final appState = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Perfect Centered Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Text(
              'app_name'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          
          // Menu
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primaryGold, size: 32),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          
          // Notifications & Bag
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNotificationIcon(context, isDark, appState),
                const SizedBox(width: 8),
                ReservationBagIcon(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, bool isDark, AppState appState) {
    return badges.Badge(
      showBadge: appState.unreadNotificationsCount > 0,
      badgeContent: Text(
        appState.unreadNotificationsCount.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      badgeStyle: const badges.BadgeStyle(
        badgeColor: Colors.redAccent,
        padding: EdgeInsets.all(5),
      ),
      position: badges.BadgePosition.topEnd(top: -5, end: -5),
      child: _buildActionIcon(
        Icons.notifications_none_rounded, 
        isDark, 
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        tooltip: 'notifications'.tr(),
      ),
    );
  }

  Widget _buildSmallSelector({
    required String currentValue,
    required List<String> options,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          dropdownColor: isDark ? const Color(0xFF131313) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.black),
          selectedItemBuilder: (BuildContext context) {
            return options.map((String value) {
              return Center(
                child: Text(
                  value.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList();
          },
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value.tr(), 
                style: GoogleFonts.cairo(
                  fontSize: 12, 
                  color: isDark ? AppColors.primaryGold : Colors.black, 
                  fontWeight: FontWeight.bold
                )
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionIcon(
    IconData icon, 
    bool isDark, {
    required VoidCallback onTap, 
    String? tooltip,
  }) {
    Widget child = InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryGold, size: 20),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        textStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: child,
      );
    }
    return child;
  }
}

class IntegratedSearchBar extends StatefulWidget {
  const IntegratedSearchBar({super.key});

  @override
  State<IntegratedSearchBar> createState() => _IntegratedSearchBarState();
}

class _IntegratedSearchBarState extends State<IntegratedSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, AppState appState) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      appState.fetchProducts(search: query);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _buildSearchBar(context, isDark, appState)),
          const SizedBox(width: 12),
          _buildFilterIcon(context, isDark),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark, AppState appState) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.primaryGold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _onSearchChanged(v, appState),
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'search_placeholder'.tr(),
                hintStyle: GoogleFonts.cairo(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('', appState);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterIcon(BuildContext context, bool isDark) {
    return _buildActionIcon(
      Icons.tune_rounded, 
      isDark, 
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const FilterBottomSheet(),
        );
      },
      tooltip: 'filter_results'.tr(),
    );
  }

  Widget _buildActionIcon(
    IconData icon, 
    bool isDark, {
    required VoidCallback onTap, 
    String? tooltip,
  }) {
    Widget child = InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Icon(icon, color: AppColors.primaryGold, size: 24),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        textStyle: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: child,
      );
    }
    return child;
  }
}
