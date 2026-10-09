import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../shared/notifications_screen.dart';
import '../../../utils/localization_service.dart';
import 'merchant_verification_screen.dart';
import 'merchant_custom_designs_screen.dart';
import 'merchant_bookings_screen.dart';
import '../../widgets/custom/gold_calculator_widget.dart';
import '../../widgets/shared/shimmer_helper.dart';
// Animations managed manually via _stagger helper

class MerchantDashboardScreen extends StatefulWidget {
  final Function(int)? onDrawerItemTap;
  final VoidCallback? onOpenDrawer;
  const MerchantDashboardScreen({super.key, this.onDrawerItemTap, this.onOpenDrawer});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  String _chartFilter = 'week'; // 'week' or 'month'
  late AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    
    // Add listener for real-time notifications
    _appState.addListener(_notificationListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _appState.checkVerificationStatus();
      if (mounted) {
        _appState.fetchMerchantProducts();
        _appState.fetchBookings();
        _appState.fetchMerchantCustomDesigns();
        _appState.fetchOrders();
        _appState.fetchMerchantAnalytics();
      }
    });
  }

  @override
  void dispose() {
    // Crucial: remove listener to prevent memory leaks
    _appState.removeListener(_notificationListener);
    super.dispose();
  }

  void _notificationListener() {
    if (!mounted) return;
    
    if (_appState.hasNewNotifications) {
      final payload = _appState.latestNotificationPayload;
      // Clear alert immediately so we don't show it twice
      _appState.clearNotificationAlert();
      
      // UI Feedback: Show a luxury top alert using Overlay for better positioning
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
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
    
    // Auto-remove after 5 seconds if not already removed
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // The provided `_contactMerchant` method relies on `widget.product`,
  // which is not available in `MerchantDashboardScreen`.
  // To maintain syntactical correctness as per instructions, this method
  // cannot be added here without further context or modification.
  // It appears to be intended for a product-specific screen.

  Future<void> _onRefresh() async {
    final appState = context.read<AppState>();
    await appState.checkVerificationStatus();
    await Future.wait([
      appState.fetchMerchantProducts(),
      appState.fetchBookings(),
      appState.fetchMerchantCustomDesigns(),
      appState.fetchMerchantAnalytics(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          // Static Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
              ),
            ),
          ),
          // Interactive Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primaryGold,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                child: Column(
                  key: const ValueKey('merchant_dashboard_content'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (appState.isLoading && appState.products.isEmpty)
                      _buildShimmerContent(isDark)
                    else
                      ..._stagger([
                        _buildLuxuryAppBar(context, isDark, appState, user?.storeName),
                        const SizedBox(height: 16),
                        _buildGoldPriceBar(context, appState, isDark),
                        const SizedBox(height: 20),
                        _buildVerificationBanner(context, isDark, appState),
                        const SizedBox(height: 32),
                        _buildStatsGrid(isDark, appState),
                        _buildOutofStockAlert(isDark, appState),
                      const SizedBox(height: 32),
                      _buildSalesChart(isDark, appState),
                      const SizedBox(height: 32),
                      const GoldCalculatorWidget(isMerchant: true),
                      const SizedBox(height: 32),
                      _buildRecentOrders(isDark, appState),
                        const SizedBox(height: 40),
                      ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldPriceBar(BuildContext context, AppState appState, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.public_rounded, color: Colors.black54, size: 12),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${'global_ounce_price'.tr()}: ${appState.globalOuncePriceUSD.toStringAsFixed(2)} USD',
                        style: GoogleFonts.cairo(
                          color: Colors.black54,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => appState.setShowGramPrice(!appState.showGramPrice),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: appState.showGramPrice,
                        onChanged: (v) => appState.setShowGramPrice(v ?? false),
                        activeColor: Colors.black,
                        checkColor: AppColors.primaryGold,
                        side: const BorderSide(color: Colors.black54, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
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
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appState.isGoldPriceLoaded
                    ? (appState.showGramPrice 
                        ? '${appState.goldPrice.toStringAsFixed(2)} ${appState.selectedCurrency.tr()} / ${'gram'.tr()}'
                        : '${(appState.globalOuncePriceUSD * appState.currencyRate).toStringAsFixed(2)} ${appState.selectedCurrency.tr()} / ${'ounce'.tr()}')
                    : '--------',
                  style: GoogleFonts.cairo(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              _buildSmallSelector(
                currentValue: appState.selectedCurrency,
                options: ['YER', 'SAR', 'USD'],
                onChanged: (v) => appState.setSelectedCurrency(v!),
              ),
              const SizedBox(width: 6),
              _buildSmallSelector(
                currentValue: appState.selectedUnit,
                options: ['K24', 'K22', 'K21', 'K18'],
                onChanged: (v) => appState.setSelectedUnit(v!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSelector({
    required String currentValue,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            return options.map<Widget>((String item) {
              return Center(
                child: Text(
                  item.tr(),
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w900),
                ),
              );
            }).toList();
          },
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value.tr(), 
                style: GoogleFonts.cairo(fontSize: 12, color: isDark ? AppColors.primaryGold : Colors.black, fontWeight: FontWeight.bold)
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLuxuryAppBar(BuildContext context, bool isDark, AppState appState, String? storeName) {
    return Row(
      children: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primaryGold, size: 28),
            onPressed: () {
              if (widget.onOpenDrawer != null) {
                widget.onOpenDrawer!();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        const Spacer(),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    storeName != null && storeName.isNotEmpty 
                        ? '${'dashboard'.tr()} - $storeName' 
                        : 'dashboard'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Badge(
          isLabelVisible: appState.unreadNotificationsCount > 0,
          label: Text(appState.unreadNotificationsCount.toString()),
          backgroundColor: Colors.redAccent,
          child: IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryGold),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ),
      ],
    );
  }


  Widget _buildStatsGrid(bool isDark, AppState appState) {
    final pendingDesignsCount = appState.merchantCustomDesigns.where((d) => d['status'] == 'pending').length;
    final outOfStockCount = appState.outOfStockProductsCount;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MerchantBookingsScreen(initialFilter: 'pending'),
                    ),
                  );
                },
                child: _buildStatCard(
                  'pending_requests'.tr(), 
                  '${appState.bookingsCount}', 
                  Icons.pending_actions_rounded, 
                  Colors.blueAccent, 
                  isDark
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantCustomDesignsScreen()));
                },
                child: _buildStatCard(
                  'طلبات التصميم', 
                  '$pendingDesignsCount', 
                  Icons.design_services_rounded, 
                  Colors.purpleAccent, 
                  isDark
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (widget.onDrawerItemTap != null) {
                    appState.setShowOnlyOutOfStock(false);
                    widget.onDrawerItemTap!(1);
                  }
                },
                child: _buildStatCard(
                  'إجمالي المنتجات', 
                  '${appState.products.length}', 
                  Icons.inventory_2_outlined, 
                  Colors.orangeAccent, 
                  isDark
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (widget.onDrawerItemTap != null) {
                    appState.setShowOnlyOutOfStock(true);
                    widget.onDrawerItemTap!(1);
                  }
                },
                child: _buildStatCard(
                  'نفد من المخزون', 
                  '$outOfStockCount', 
                  Icons.warning_amber_rounded, 
                  outOfStockCount > 0 ? Colors.redAccent : Colors.grey, 
                  isDark
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Adding a new row for low stock if needed, or just integrating it into the grid
  // I'll add a specific "Out of Stock" card below the grid if there are any
  Widget _buildOutofStockAlert(bool isDark, AppState appState) {
    final count = appState.outOfStockProductsCount;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'منتجات نفدت كميتها ($count)',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'يرجى تحديث الكمية لإعادة ظهورها للعملاء',
                        style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showQuickRestockSheet(context, isDark, appState),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text('تعديل الكميات سريعاً', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickRestockSheet(BuildContext context, bool isDark, AppState appState) {
    final outOfStockProducts = appState.products.where((p) => p.stockQuantity <= 0).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Text('إعادة تعبئة المخزون', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: outOfStockProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final product = outOfStockProducts[index];
                      final controller = TextEditingController(text: '1');
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(product.mainImageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported_outlined))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(product.materialName, style: GoogleFonts.cairo(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'الكمية',
                                  labelStyle: GoogleFonts.cairo(fontSize: 10),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                              onPressed: () async {
                                final qty = int.tryParse(controller.text) ?? 1;
                                final success = await appState.updateProduct(product.id, {
                                  'stock_quantity': qty,
                                  'status': 'published',
                                });
                                if (success) {
                                  setSheetState(() {
                                    outOfStockProducts.removeAt(index);
                                  });
                                  if (outOfStockProducts.isEmpty) Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(bool isDark, AppState appState) {
    final analytics = appState.merchantAnalytics;
    final chartData = analytics?['chart_data']?[_chartFilter] as List? ?? [];
    final summary = analytics?['summary'];
    final growthPercentage = summary?['growth_percentage'] ?? 0.0;
    final isPositive = growthPercentage >= 0;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : AppColors.primaryGold.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.auto_graph_rounded, color: Colors.greenAccent, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'growth_index'.tr(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${isPositive ? "+" : ""}$growthPercentage% ${'this_month'.tr()}',
                    style: TextStyle(color: isPositive ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              _buildChartFilterChip('week'.tr(), _chartFilter == 'week', () {
                setState(() => _chartFilter = 'week');
              }),
              const SizedBox(width: 8),
              _buildChartFilterChip('month'.tr(), _chartFilter == 'month', () {
                setState(() => _chartFilter = 'month');
              }),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold);
                        String text = "";
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          text = chartData[index]['label'] ?? "";
                        }
                        // For monthly view, show fewer labels to avoid overlapping
                        if (_chartFilter == 'month' && index % 5 != 0) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, 
                maxX: chartData.isEmpty ? 6 : (chartData.length - 1).toDouble(),
                minY: 0, 
                maxY: (chartData.fold<double>(5, (max, e) {
                  final v = double.tryParse(e['value'].toString()) ?? 0.0;
                  return v > max ? v : max;
                }) + 2).toDouble(),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((e) {
                      final val = double.tryParse(e.value['value'].toString()) ?? 0.0;
                      return FlSpot(e.key.toDouble(), val);
                    }).toList(),
                    isCurved: true,
                    gradient: AppColors.liquidGold,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primaryGold,
                        strokeWidth: 2,
                        strokeColor: isDark ? AppColors.matteBlack : Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGold.withOpacity(0.2),
                          AppColors.primaryGold.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primaryGold : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }


  Widget _buildVerificationBanner(BuildContext context, bool isDark, AppState appState) {
    final status = appState.currentUser?.verificationStatus ?? 'not_submitted';
    final isVerified = appState.currentUser?.isVerified ?? false;

    if (isVerified) return const SizedBox.shrink();

    // ─── Rejected ───────────────────────────────────────────────────────────
    if (status == 'rejected') {
      final reason = appState.currentUser?.rejectionReason ?? '';
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MerchantVerificationScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تم رفض طلب التوثيق',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'إعادة الرفع',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (reason.isNotEmpty) ...
                [
                  const SizedBox(height: 8),
                  Text(
                    'السبب: $reason',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
            ],
          ),
        ),
      );
    }

    // ─── Pending (waiting for admin review) ─────────────────────────────────
    if (status == 'pending') {
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MerchantVerificationScreen()),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_empty_rounded, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'pending_verification'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.orangeAccent, size: 14),
            ],
          ),
        ),
      );
    }

    // ─── Not submitted yet ───────────────────────────────────────────────────
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MerchantVerificationScreen()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryGold.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: AppColors.primaryGold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'verify_account_tap'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryGold, size: 14),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentOrders(bool isDark, AppState appState) {
    final recentOrders = appState.orders.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 16),
          child: Text(
            'recent_orders'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        if (recentOrders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('no_recent_bookings'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = recentOrders[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                  ),
                ),
                  child: ListTile(
                    onTap: () {
                      if (widget.onDrawerItemTap != null) {
                        widget.onDrawerItemTap!(2); // Switch to Bookings tab
                      }
                    },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryGold),
                  ),
                  title: Text(
                    '${'booking_no'.tr()}${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MM/dd HH:mm').format(order.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${order.items.isNotEmpty ? (order.items.first.product?.weight ?? 0) : 0} ${'gram'.tr()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  Widget _buildShimmerContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShimmerHelper.buildBoxShimmer(height: 50, borderRadius: 12),
        const SizedBox(height: 24),
        ShimmerHelper.buildBoxShimmer(height: 100, borderRadius: 20),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: ShimmerHelper.buildBoxShimmer(height: 100, borderRadius: 20)),
            const SizedBox(width: 16),
            Expanded(child: ShimmerHelper.buildBoxShimmer(height: 100, borderRadius: 20)),
          ],
        ),
        const SizedBox(height: 24),
        ShimmerHelper.buildBoxShimmer(height: 250, borderRadius: 32),
        const SizedBox(height: 24),
        ShimmerHelper.buildBoxShimmer(height: 150, borderRadius: 24),
      ],
    );
  }

  List<Widget> _stagger(List<Widget> children) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      return child.animate(delay: (index * 100).ms)
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
    }).toList();
  }
}
