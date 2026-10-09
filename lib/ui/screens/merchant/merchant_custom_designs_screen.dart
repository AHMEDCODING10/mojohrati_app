import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../state/app_state.dart';

class MerchantCustomDesignsScreen extends StatefulWidget {
  const MerchantCustomDesignsScreen({super.key});

  @override
  State<MerchantCustomDesignsScreen> createState() => _MerchantCustomDesignsScreenState();
}

class _MerchantCustomDesignsScreenState extends State<MerchantCustomDesignsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchMerchantCustomDesigns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('طلبات التصميم الخاص'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.meshDark : AppColors.meshLight,
        ),
        child: SafeArea(
          child: appState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : appState.merchantCustomDesigns.isEmpty
                  ? _buildEmptyState(isDark)
                  : RefreshIndicator(
                      onRefresh: () => appState.fetchMerchantCustomDesigns(),
                      color: AppColors.primaryGold,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: appState.merchantCustomDesigns.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final order = appState.merchantCustomDesigns[index];
                          return _buildDesignCard(context, order, isDark);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.design_services_outlined, size: 80,
              color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text('لا توجد طلبات تصميم خاص حالياً',
              style: GoogleFonts.cairo(fontSize: 16,
                  color: isDark ? Colors.white60 : Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildDesignCard(BuildContext context, Map<String, dynamic> order, bool isDark) {
    final status = order['status'] ?? 'pending';
    final customerName = order['user']?['name'] ?? 'عميل';
    final customerPhone = order['user']?['phone'];
    final description = order['description'] ?? '';
    final budget = order['budget']?.toString() ?? '';
    final purity = order['purity'] ?? '';
    final weight = order['weight']?.toString() ?? '';
    String? imageUrl = order['image_url'];
    if (imageUrl == null && order['image_path'] != null) {
      final path = order['image_path'].toString();
      imageUrl = path.contains('http') ? path : '${AppConstants.storageUrl}/$path';
    }
    final orderId = order['id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('طلب #$orderId', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),

          // Customer Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                  child: const Icon(Icons.person_outline, color: AppColors.primaryGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (customerPhone != null)
                        Text(customerPhone,
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                    ],
                  ),
                ),
                if (customerPhone != null) ...[
                  IconButton(
                    icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 22),
                    onPressed: () => launchUrl(Uri.parse('https://wa.me/$customerPhone')),
                    tooltip: 'واتساب',
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: AppColors.primaryGold, size: 22),
                    onPressed: () => launchUrl(Uri.parse('tel:$customerPhone')),
                    tooltip: 'اتصال',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Design Image
          if (imageUrl != null) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        iconTheme: const IconThemeData(color: Colors.white),
                        elevation: 0,
                      ),
                      body: SafeArea(
                        child: Center(
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 50),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: Colors.grey.withOpacity(0.1),
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Specs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (purity.isNotEmpty) _buildChip('عيار: $purity K'),
              if (weight.isNotEmpty) _buildChip('الوزن: $weight غ'),
              if (budget.isNotEmpty) _buildChip('الميزانية: $budget'),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text('التفاصيل:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(description,
              style: GoogleFonts.cairo(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),

          const SizedBox(height: 20),

          // Action Buttons
          if (status == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('قبول الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    onPressed: () => _updateStatus(context, orderId, 'reviewed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text('رفض', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    onPressed: () => _updateStatus(context, orderId, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'reviewed') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text('تم التواصل - إتمام الطلب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                onPressed: () => _updateStatus(context, orderId, 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'reviewed':
      case 'contacted':
        color = Colors.blue;
        label = 'جاري المراجعة';
        break;
      case 'completed':
        color = Colors.green;
        label = 'مكتمل';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'مرفوض';
        break;
      default:
        color = Colors.orange;
        label = 'في الانتظار';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _updateStatus(BuildContext context, String id, String status) async {
    final success = await context.read<AppState>().updateCustomDesignStatus(id, status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'تم تحديث حالة الطلب' : 'حدث خطأ'),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
