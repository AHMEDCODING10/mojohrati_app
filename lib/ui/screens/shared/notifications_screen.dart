import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';
import '../../../utils/localization_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../merchant/add_product_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<AppState>().fetchNotifications()
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('notifications'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (appState.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: AppColors.primaryGold),
              onPressed: () => _markAllAsRead(context),
              tooltip: 'mark_all_read'.tr(),
            ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: appState.isLoading && appState.notifications.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : appState.notifications.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildNotificationsList(appState, isDark),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    final success = await context.read<AppState>().markAllNotificationsRead();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('all_marked_as_read'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, 
               size: 80, 
               color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            'no_notifications'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'no_notifications_desc'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(AppState appState, bool isDark) {
    return RefreshIndicator(
      onRefresh: () => appState.fetchNotifications(),
      color: AppColors.primaryGold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        itemCount: appState.notifications.length,
        itemBuilder: (context, index) {
          final notification = appState.notifications[index];
          return _NotificationTile(notification: notification, isDark: isDark)
              .animate()
              .fadeIn(delay: (index * 50).ms)
              .slideX(begin: 0.1, curve: Curves.easeOutQuad);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic notification;
  final bool isDark;

  const _NotificationTile({required this.notification, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Safely cast data to Map, defaulting to empty Map if it's a list or null
    final dynamic rawData = notification['data'];
    final Map<String, dynamic> data = (rawData is Map) ? Map<String, dynamic>.from(rawData) : {};
    
    final title = data['title'] ?? notification['title'] ?? 't_notification'.tr();
    final body = data['body'] ?? data['message'] ?? notification['message'] ?? '';
    final createdAtStr = notification['created_at'];
    final isRead = notification['read_at'] != null;
    
    DateTime? createdAt;
    if (createdAtStr != null) {
      createdAt = DateTime.tryParse(createdAtStr);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? (isRead ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.08)) 
            : (isRead ? Colors.white.withOpacity(0.6) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRead 
              ? Colors.transparent 
              : AppColors.primaryGold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          if (!isRead)
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Always mark as read first
            if (!isRead) {
              context.read<AppState>().markNotificationRead(notification['id'].toString());
            }

            // Handle specific navigation types
            if (notification['type'] == 'out_of_stock') {
              final productId = data['product_id']?.toString();
              if (productId != null) {
                // Show loading indicator or simple snackbar if fetch takes time
                final product = await context.read<AppState>().fetchProductById(productId);
                if (product != null && context.mounted) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => AddProductScreen(product: product))
                  );
                }
              }
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with Unread Indicator
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isRead ? null : AppColors.liquidGold,
                        color: isRead ? (isDark ? Colors.white10 : Colors.grey.shade100) : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getIconForType(notification['type']), 
                        color: isRead ? (isDark ? Colors.white38 : Colors.black38) : Colors.black87, 
                        size: 24
                      ),
                    ),
                    if (!isRead)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? AppColors.matteBlack : Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              timeago.format(createdAt, locale: LocalizationService.translate('locale_code')), 
                              style: TextStyle(
                                fontSize: 10, 
                                color: isRead ? Colors.grey : AppColors.primaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.notifications_none_rounded;
    if (type.contains('booking')) return Icons.calendar_today_rounded;
    if (type.contains('gold')) return Icons.trending_up_rounded;
    if (type.contains('order')) return Icons.shopping_bag_outlined;
    if (type.contains('verification')) return Icons.verified_user_outlined;
    if (type.contains('out_of_stock')) return Icons.inventory_2_outlined;
    return Icons.notifications_none_rounded;
  }
}

