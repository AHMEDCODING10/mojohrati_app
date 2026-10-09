import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../models/booking.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_details_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.fetchBookings();
      appState.fetchCustomerCustomDesigns();
      appState.markBookingNotificationsRead();
    });
  }

  Future<void> _contactMerchant(String? whatsapp, {bool isWhatsApp = true}) async {
    if (whatsapp == null || whatsapp.isEmpty) return;
    
    final url = isWhatsApp 
        ? Uri.parse("https://wa.me/$whatsapp") 
        : Uri.parse("tel:$whatsapp");
    
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('bookings_title'.tr()),
          bottom: TabBar(
            indicatorColor: AppColors.primaryGold,
            indicatorWeight: 3,
            labelColor: AppColors.primaryGold,
            unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              Tab(text: 'bookings_section'.tr()),
              Tab(text: 'custom_designs_section'.tr()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Bookings
            _buildBookingsTab(appState),
            // Tab 2: Custom Designs
            _buildCustomDesignsTab(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab(AppState appState) {
    if (appState.isLoading && appState.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }
    
    if (appState.bookings.isEmpty) {
      return _buildEmptyState(context, 'no_bookings'.tr());
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: appState.bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final booking = appState.bookings[index];
        return _buildBookingCard(context, booking);
      },
    );
  }

  Widget _buildCustomDesignsTab(AppState appState) {
    if (appState.isLoading && appState.customerCustomDesigns.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }
    
    if (appState.customerCustomDesigns.isEmpty) {
      return _buildEmptyState(context, 'no_custom_designs'.tr());
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: appState.customerCustomDesigns.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final design = appState.customerCustomDesigns[index];
        return _buildCustomDesignCard(context, design);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 80, color: Theme.of(context).hintColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 18, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }

  Widget _buildCustomDesignCard(BuildContext context, Map<String, dynamic> design) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = design['status'] ?? 'pending';
    final String title = design['title'] ?? 'تصميم خاص';
    final DateTime createdAt = design['created_at'] != null 
        ? DateTime.parse(design['created_at']) 
        : DateTime.now();
    String? imageUrl = design['image_url'];
    if (imageUrl == null && design['image_path'] != null) {
      final path = design['image_path'].toString();
      imageUrl = path.contains('http') ? path : '${AppConstants.storageUrl}/$path';
    }
    final budget = design['budget'];
    final material = design['material_type'] ?? 'gold';
    final merchant = design['merchant'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#CD-${design['id']}', 
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (imageUrl != null)
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.draw_rounded, color: AppColors.primaryGold),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (budget != null)
                      Text(
                        '${'budget_label'.tr()} $budget', 
                        style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    Text(
                      material == 'gold' ? 'gold'.tr() : (material == 'silver' ? 'silver'.tr() : material), 
                      style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                      '${createdAt.day} / ${createdAt.month} / ${createdAt.year}', 
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text('order_date'.tr(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              if (merchant != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      merchant['store_name'] ?? 'متجر غير معروف', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text('merchant_store'.tr(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
            ],
          ),
          if (merchant != null && (status == 'confirmed' || status == 'accepted'))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _contactMerchant(merchant['whatsapp']),
                      icon: const Icon(Icons.message_outlined, size: 18),
                      label: Text('merchant_whatsapp'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = booking.product;
    final merchant = product?.merchant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                'booking_id_hash'.tr().replaceAll('{}', booking.id), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(product.images.isNotEmpty ? product.images.first : AppConstants.placeholderImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking.createdAt.day} / ${booking.createdAt.month} / ${booking.createdAt.year}', 
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                  ),
                  Text('booking_date'.tr(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              if (merchant != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      merchant.storeName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text('merchant_store'.tr(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (merchant != null && (booking.status == 'confirmed' || booking.status == 'accepted' || booking.status == 'processing'))
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactMerchant(merchant.whatsapp),
                    icon: const Icon(Icons.message_outlined, size: 18),
                    label: Text('merchant_whatsapp'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactMerchant(merchant.contactNumber ?? merchant.whatsapp, isWhatsApp: false), 
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text('direct_call_btn'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGold,
                      side: const BorderSide(color: AppColors.primaryGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          if (booking.status == 'pending')
            Center(
              child: Text(
                'waiting_merchant_approval'.tr(),
                style: const TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic),
              ),
            ),
          if ((booking.status == 'rejected' || booking.status == 'declined') && booking.rejectionReason != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text('reject_reason'.tr().isNotEmpty ? 'reject_reason'.tr() : 'سبب الرفض:', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    booking.rejectionReason!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'status_pending'.tr();
        break;
      case 'confirmed':
        color = Colors.green;
        text = 'status_confirmed'.tr();
        break;
      case 'rejected':
      case 'declined':
        color = Colors.red;
        text = 'status_rejected'.tr().isNotEmpty ? 'status_rejected'.tr() : 'مرفوض';
        break;
      case 'accepted':
        color = Colors.green;
        text = 'status_accepted'.tr().isNotEmpty ? 'status_accepted'.tr() : 'مقبول';
        break;
      case 'processing':
        color = Colors.blue;
        text = 'status_processing'.tr().isNotEmpty ? 'status_processing'.tr() : 'قيد التنفيذ';
        break;
      case 'completed':
        color = AppColors.primaryGold;
        text = 'status_completed'.tr();
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    bool isPremium = status == 'confirmed' || status == 'accepted' || status == 'completed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: isPremium ? AppColors.liquidGold : null,
        color: isPremium ? null : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        boxShadow: isPremium ? [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ] : null,
        border: isPremium ? null : Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: isPremium ? Colors.black : color, 
          fontSize: 10, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}
