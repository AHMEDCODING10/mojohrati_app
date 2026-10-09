import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../models/booking.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../customer/product_details_screen.dart';
class MerchantBookingsScreen extends StatefulWidget {
  final Function(int)? onDrawerItemTap;
  final VoidCallback? onOpenDrawer;
  final String initialFilter;
  
  const MerchantBookingsScreen({
    super.key, 
    this.onDrawerItemTap, 
    this.onOpenDrawer,
    this.initialFilter = 'all',
  });

  @override
  State<MerchantBookingsScreen> createState() => _MerchantBookingsScreenState();
}

class _MerchantBookingsScreenState extends State<MerchantBookingsScreen> {
  late String _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clear alert when looking at the screen
    if (appState.hasNewBookings) {
      Future.microtask(() => context.read<AppState>().clearBookingAlert());
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Navigator.canPop(context) 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryGold),
              onPressed: () => Navigator.pop(context),
            )
          : Builder(
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
        title: Stack(
          clipBehavior: Clip.none,
          children: [
            Text('manage_booking_requests'.tr()),
            if (appState.hasNewBookings)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          SizedBox(width: 48),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterTabs(isDark),
              Expanded(
                child: appState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _getFilteredBookings(appState.bookings).isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _getFilteredBookings(appState.bookings).length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final booking = _getFilteredBookings(appState.bookings)[index];
                            return _buildBookingCard(context, booking, isDark);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Booking> _getFilteredBookings(List<Booking> allBookings) {
    if (_currentFilter == 'all') return allBookings;
    return allBookings.where((b) => b.status == _currentFilter).toList();
  }

  Widget _buildFilterTabs(bool isDark) {
    final filters = [
      {'id': 'all', 'label': 'الكل'},
      {'id': 'pending', 'label': 'معلقة'},
      {'id': 'confirmed', 'label': 'مؤكدة'},
      {'id': 'rejected', 'label': 'مرفوضة'},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _currentFilter == f['id'];
          return GestureDetector(
            onTap: () => setState(() => _currentFilter = f['id']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.liquidGold : null,
                color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: isSelected ? Colors.transparent : AppColors.primaryGold.withOpacity(0.3)),
              ),
              child: Text(
                f['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text('no_bookings_now'.tr(), style: TextStyle(fontSize: 18, color: isDark ? Colors.white60 : Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, bool isDark) {
    final product = booking.product;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'booking_no'.tr()}#${booking.id}', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              _buildStatusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 20),
          if (product != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(product: product),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: product.mainImageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGold)),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          AppConstants.placeholderImage,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${product.weight} ${'gram'.tr()}', 
                              style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            if (booking.quantity > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'x${booking.quantity}',
                                  style: const TextStyle(
                                    color: AppColors.primaryGold, 
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          product.materialName, 
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          
          // Customer Info Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primaryGold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName ?? 'guest_user'.tr(), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                      ),
                      Text(
                        booking.customerPhone ?? 'no_details_placeholder'.tr(), 
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, letterSpacing: 0.5)
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (booking.customerPhone != null) ...[
                      _buildContactIcon(
                        icon: Icons.chat_bubble_rounded, 
                        color: const Color(0xFF25D366), 
                        onTap: () => launchUrl(Uri.parse("https://wa.me/${booking.customerPhone}"))
                      ),
                      const SizedBox(width: 8),
                      _buildContactIcon(
                        icon: Icons.call_rounded, 
                        color: AppColors.primaryGold, 
                        onTap: () => launchUrl(Uri.parse("tel:${booking.customerPhone}"))
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (booking.customerNotes != null && booking.customerNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: BorderDirectional(start: BorderSide(color: Colors.orange.withOpacity(0.5), width: 3)),
              ),
              child: Text(
                '${'customer_note'.tr()}${booking.customerNotes}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          if (booking.status == 'pending')
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.liquidGold,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryGold.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(context, booking.id, 'confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'confirm_booking'.tr(), 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => _updateStatus(context, booking.id, 'rejected'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
                        ),
                      ),
                      child: Text('reject_booking'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status == 'confirmed' ? 'تم تأكيد الحجز' : 'تم الرفض',
                  style: TextStyle(
                    color: booking.status == 'confirmed' ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String labelKey = 'status_pending';

    if (status == 'confirmed') { color = Colors.green; labelKey = 'status_confirmed'; }
    if (status == 'rejected') { color = Colors.red; labelKey = 'status_rejected'; }
    if (status == 'completed') { color = Colors.blue; labelKey = 'status_completed'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(labelKey.tr(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _updateStatus(BuildContext context, String bookingId, String status) async {
    if (status == 'rejected') {
      final reason = await _showRejectReasonDialog(context);
      if (reason == null) return; // User cancelled
      _processStatusUpdate(context, bookingId, status, reason: reason);
    } else {
      _processStatusUpdate(context, bookingId, status);
    }
  }

  Future<String?> _showRejectReasonDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reject_booking'.tr()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'سبب الرفض (إلزامي)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context), 
             child: Text('cancel'.tr())
          ),
          ElevatedButton(
             onPressed: () {
               if (controller.text.trim().isNotEmpty) {
                 Navigator.pop(context, controller.text.trim());
               }
             }, 
             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
             child: Text('reject_booking'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processStatusUpdate(BuildContext context, String bookingId, String status, {String? reason}) async {
    final appState = context.read<AppState>();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('updating_booking_status'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final success = await appState.updateBookingStatus(bookingId, status, reason: reason);
    
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'confirmed' ? 'booking_confirmed_success'.tr() : 'booking_rejected_success'.tr()),
          backgroundColor: status == 'confirmed' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Show the backend error if available, else generic error
          content: Text(appState.lastError ?? 'error_occurred'.tr()), 
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
