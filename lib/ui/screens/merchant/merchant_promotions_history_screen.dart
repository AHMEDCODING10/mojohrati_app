import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/colors.dart';
import '../../../state/app_state.dart';

class MerchantPromotionsHistoryScreen extends StatefulWidget {
  const MerchantPromotionsHistoryScreen({super.key});

  @override
  State<MerchantPromotionsHistoryScreen> createState() => _MerchantPromotionsHistoryScreenState();
}

class _MerchantPromotionsHistoryScreenState extends State<MerchantPromotionsHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final appState = context.read<AppState>();
      final list = await appState.fetchMerchantPromotionRequests();
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'سجل طلبات الترويج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
            : _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars_outlined, size: 60, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد طلبات ترويج مسجلة حالياً',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final item = _requests[index];
                      final status = item['status']?.toString() ?? 'pending';
                      final reason = item['rejection_reason']?.toString();
                      final weeks = item['duration_weeks'] ?? 1;
                      final fee = item['fee_amount'] ?? '0.00';
                      final type = item['type']?.toString();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: status == 'approved'
                                ? Colors.green.withValues(alpha: 0.5)
                                : (status == 'rejected' ? Colors.red.withValues(alpha: 0.5) : AppColors.primaryGold.withValues(alpha: 0.3)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
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
                                  _getTypeLabel(type),
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                _buildStatusBadge(status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'المدة: $weeks أسبوع ($fee \$)',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'تاريخ الطلب: ${item['created_at']?.toString().split('T').first ?? ''}',
                              style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                            ),

                            // Rejection Reason Alert Container
                            if (status == 'rejected' && reason != null && reason.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: Colors.red, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'سبب الرفض من الإدارة:',
                                          style: GoogleFonts.cairo(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      reason,
                                      style: GoogleFonts.cairo(
                                        color: isDark ? Colors.red[200] : Colors.red[900],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _getTypeLabel(String? type) {
    if (type == 'product') return 'ترويج أصناف محددة';
    if (type == 'category') return 'ترويج قسم محدد';
    if (type == 'all_categories') return 'ترويج شامل لجميع الأقسام / المتجر';
    return 'طلب ترويج';
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    if (status == 'approved') {
      bg = Colors.green.withValues(alpha: 0.15);
      text = Colors.green;
      label = 'تمت الموافقة 🚀';
    } else if (status == 'rejected') {
      bg = Colors.red.withValues(alpha: 0.15);
      text = Colors.red;
      label = 'مرفوض ❌';
    } else {
      bg = Colors.amber.withValues(alpha: 0.15);
      text = Colors.amber[800]!;
      label = 'قيد المراجعة ⏳';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
